/* =========================================================================
 * dl_fetch.v — 显示列表取指器 DFU（Display-list Fetch Unit）   S2 / v2.11
 * -------------------------------------------------------------------------
 * 依据 = doc/display_list_design.md（§5 描述符/几何表、§6 状态机、§7 预取、
 *        §8 畸形列表保护、§9 顺序规则）。
 *
 * 一句话：从 DDR 取 16B 描述符 → 展开成**现有的 8 字命令** → 推入**现有的
 * cmd_fifo**。引擎 FSM / 像素通路 / 地址生成 / 写主机一行未改。
 *
 * 四条不变式（S2 不得破坏，见设计文档 §1）：
 *   I1 命令字仍是 8×32bit，引擎零改动 —— 本模块只产出与 CPU 今天写的
 *      **一模一样的 8 个字**（展开表见设计文档 §5.3）。
 *   I2 cmd_fifo 是唯一命令入口；DFU 与 CPU 在**整条命令粒度**上互斥。
 *      本模块只负责"申请/持有/释放"：在 S_PUSH 拉高 dl_cmd_req，拿到
 *      dl_cmd_gnt 才认为字写进去了；从第 1 个字到第 8 个字之间**一直举着
 *      req**，由 blt_regs_axi_lite.v 保证这段时间 CPU 侧的 ready 被压低。
 *   I3 每精灵的写顺序 = 描述符顺序；完成判据仍是引擎的 done_out
 *      （内含 wr_commit_idle / b_pending）。本模块只**等**它，不碰它。
 *   I4 预取/译码允许跑在引擎前面，但**只提前进 FIFO**，不提前任何一次写
 *      —— 本模块根本不产生写事务，唯一出口是 cmd_fifo。
 *
 * 展开流水（每条描述符）：S_HEAD 取 → S_CHK 查索引/保留位 → S_GEOM(+W) 取几何
 *   → S_EVAL 组合算尺寸/裁剪/地址 + 锁存 8 个字 → S_PUSH 逐拍推 8 个字。
 *   几何表**总是先落到 geff0~geff3 寄存器**再进 S_EVAL，所以 S_EVAL 里那套
 *   包含 2 个 16×16 乘法的展开逻辑输入全是触发器，不进 AXI 的任何组合路径。
 *
 * 与设计文档的四处实现选择（已在汇报里说明）：
 *   1) 几何表读与描述符读**共用 desc 流的一个读口**，且 DFU 同时只允许 1 笔
 *      在飞（文档 §7.1 的"desc 读 ≤ 1 笔未完成"）。回程归属因此不需要序号；
 *      出错/ABORT 后残留 beat 由"desc_rready 恒 1 + 状态无关地丢弃"排干净，
 *      绝不把 axi_rd_master 的 R 队列堵死。
 *   2) 预取是**水位触发的内联预取**（S_HEAD 发现 FIFO 剩余 ≤ WM 就先补一块再
 *      回来取），而不是与译码并行的独立流水。理由：展开本身是单条串行的，
 *      WM≥1 时一块 8 条的读只有 ~30 拍，而 1 条描述符的命令要跑 ~130 拍，
 *      FIFO 永不见底；状态机少一层并发，回程归属永远唯一。
 *   3) 屏幕尺寸来自新寄存器 0x88 DL_FB_WH —— 设计文档 §8.1 要求 SPRITE_BOUNDS
 *      检查 `W≤FB_W && H≤FB_H`、`X∈[-W,FB_W)`，但 §4 的寄存器表里没有屏宽高。
 *   4) 目标行距来自新寄存器 0x84 DL_DST_STRIDE —— §4 把 0x70 定成 32bit 的
 *      DL_DST_BASE，与 §14.7 建议的"复用 0x70 高半字放行距"直接冲突；取 §4
 *      的表为准，另开一个 16bit 寄存器。
 *   5) ★S3：掩码不进 ATTR FIFO，而是走 **w0[31:2] 的空位**（w0[31:16]=掩码、
 *      w0[2]=MASK_EN）。§13 设想 S2 顺手做的"平行属性 FIFO" S2 并未实现，
 *      补做它要两个 FIFO 严格同步（错位即静默错掩码）；而 §2.2 自己写着
 *      "w0[31:2] 当前未用"，掩码 17 bit 放得下 ⇒ 用空位最省且无同步风险。
 *      描述符字段（dw1.FLAGS[7]=MASK_EN、[9:8]=MASK_MODE、dw3[15:0]=MASK_ID）
 *      **一位没动**，仍是 §5.1 的布局；只在 S_CHK 里补一条"MASK_MODE≠01 ⇒
 *      未实现"的检查（否则会拿 01 的语义去猜别的模式）。
 *
 * A/B 逃生门：`-DDL_OFF` 时顶层不例化本模块（dl_cmd_req 恒 0、desc_req 恒 0），
 *   寄存器组把 CPU 写口直通 —— 与 S1 之后的行为逐位一致。
 *   `-DMASK_SKIP_OFF` 时掩码位恒 0、MASK_MODE 检查也关掉 ⇒ 展开出的 8 个字与
 *   S2 逐位相同。
 * ========================================================================= */
module dl_fetch #(
    parameter DESC_DEPTH = 16,             // 描述符 FIFO 深度（条）
    parameter COUNT_MAX  = 16'd4095,       // DL_COUNT 上限（设计文档 §4）
    parameter GEOM_MAXN  = 16'd1023        // DL_GEOM_MAX 上限
)(
    input  wire          clk,
    input  wire          rst_n,

    /* ---- 配置（GO 时刻采到影子寄存器；寄存器组已在 BUSY 期间挡住写入） ---- */
    input  wire [31:0]   cfg_base0,        // 0x4C
    input  wire [31:0]   cfg_base1,        // 0x50
    input  wire [15:0]   cfg_count,        // 0x54
    input  wire          cfg_buf_sel,      // 0x58 bit2
    input  wire          cfg_auto_go,      // 0x58 bit4
    input  wire          cfg_strict,       // 0x58 bit5
    input  wire [31:0]   cfg_geom_base,    // 0x68
    input  wire [15:0]   cfg_geom_max,     // 0x6C
    input  wire [31:0]   cfg_dst_base,     // 0x70
    input  wire [15:0]   cfg_dst_stride,   // 0x84[15:0] 字节/行
    input  wire [15:0]   cfg_fb_w,         // 0x88[15:0] 屏宽（像素）
    input  wire [15:0]   cfg_fb_h,         // 0x88[31:16] 屏高（像素）
    input  wire [15:0]   cfg_timeout,      // 0x78 单条描述符看门狗（core 拍，0=关）
    input  wire [3:0]    cfg_chunk,        // 0x74[7:4]  每次 AXI 读几条（0 ⇒ 8）
    input  wire [3:0]    cfg_wm,           // 0x74[11:8] 预取水位（剩 ≤WM 就补块）
    input  wire          cfg_prefetch,     // 0x74 bit0
    input  wire          cfg_gec,          // 0x74 bit1  几何表 cache

    /* ---- 控制（都是 1 拍脉冲，由寄存器组产生） ---- */
    input  wire          go_pulse,         // 0x58 bit0
    input  wire          abort_pulse,      // 0x58 bit1
    input  wire          err_clr_pulse,    // 0x60 W1C
    input  wire [31:0]   err_clr_mask,     // 0x60 W1C 掩码
    input  wire          list_rewr_pulse,  // 写 0x4C/0x50 ⇒ 清 DONE
    input  wire          base_align_err,   // 写 0x4C/0x50 未 16B 对齐（1 拍）

    /* ---- 描述符 / 几何表读口 → axi_rd_master 的 desc 流（rd_sel=2'b10） ---- */
    output wire          desc_req,
    output wire [31:0]   desc_addr,
    output wire [7:0]    desc_len,         // 拍数（1..15）
    input  wire          desc_ready,       // 读主机有信用：本拍受理
    input  wire          desc_rvalid,      // R 回程 beat（16B = 1 条描述符）
    input  wire [127:0]  desc_rdata,
    input  wire [1:0]    desc_rresp,
    output wire          desc_rready,      // 恒 1：回程一律收下

    /* ---- 命令推入口 → blt_regs_axi_lite 的 cmd_fifo 写口仲裁 ---- */
    output wire          dl_cmd_req,       // 有一个字要写（gnt 才算写进去）
    output wire [31:0]   dl_cmd_data,
    output wire          dl_cmd_last,      // 本字是 8 字命令的第 8 个 ⇒ 释放端口
    input  wire          dl_cmd_gnt,       // 本拍受理（写进 cmd_fifo）

    /* ---- 引擎 / 读主机状态 ---- */
    input  wire          eng_done,         // 引擎完成判据（含 wr_commit_idle）
    input  wire          rd_busy,          // axi_rd_master 仍有在飞突发

    /* ---- 状态回读（→ 寄存器组 0x5C/0x60/0x64/0x7C/0x10） ---- */
    output wire          busy,             // 0x5C bit0
    output wire          done,             // 0x5C bit1（电平）
    output wire          err,              // 0x5C bit2 = |err_r
    output wire          aborted,          // 0x5C bit3
    output wire          stall,            // 0x5C bit4
    output wire [15:0]   consumed,         // 0x5C[31:16]
    output wire [1:0]    active_buf,       // 0x5C[9:8]
    output wire [31:0]   err_word,         // 0x60 完整读回值
    output wire [31:0]   fault_addr,       // 0x64
    output wire [31:0]   perf_cycles,      // 0x7C：上次 GO→DONE 的 core 拍数
    output wire          auto_go_hold      // → 引擎 go（AUTO_GO 的落地）
);
    /* ---------------- 状态 ---------------- */
    localparam S_IDLE  = 4'd0;
    localparam S_CHUNK = 4'd1;    // 发一块描述符读
    localparam S_FILL  = 4'd2;    // 收 R beat → desc FIFO
    localparam S_HEAD  = 4'd3;    // 取一条描述符（含水位预取）
    localparam S_CHK   = 4'd4;    // 查几何索引 / 保留位
    localparam S_GEOM  = 4'd5;    // 几何表：查 cache / 发 1 拍读
    localparam S_GEOMW = 4'd6;    // 几何表：等 1 拍 R
    localparam S_EVAL  = 4'd7;    // 尺寸/边界/裁剪 + 展开（几何已稳定）
    localparam S_PUSH  = 4'd8;    // 按 w0→w7 推入 cmd_fifo
    localparam S_END   = 4'd9;
    localparam S_ERR   = 4'd10;
    localparam S_ABORT = 4'd11;
    localparam S_DRAIN = 4'd12;   // GO 时若上一张表遗留了在飞 desc 读：先等它回完

    reg [3:0]  st;
    reg [15:0] s_count;                  // 影子 COUNT
    reg [31:0] s_base, s_geom_base, s_dst_base;
    reg [15:0] s_geom_max, s_dst_stride, s_fb_w, s_fb_h, s_timeout;
    reg [3:0]  s_chunk, s_wm;
    reg        s_prefetch, s_gec, s_strict;
    reg [1:0]  s_buf;

    reg [15:0] issued;                   // 已向 DDR 请求的描述符条数
    reg [15:0] consumed_r;               // 已展开下发的条数
    reg        end_seen;                 // 遇到 END_OF_LIST
    reg [7:0]  rd_beats, rd_cnt;         // 本块应回 / 已回 beat 数
    reg        perf_run;
    reg [31:0] perf_cnt, perf_r;
    reg [15:0] wd_cnt;                   // 看门狗（core 拍）
    reg        done_r, aborted_r, auto_go_r, go_pulse_r;
    reg        unsync;                   // 上一张表遗留了在飞 desc 读（见 S_DRAIN）

    /* 错误锁存（W1C；[7:0]=位、[24]=未实现、[23:16]=序号在外面拼） */
    reg [31:0] err_r;
    reg [7:0]  err_idx_r;
    reg [31:0] fault_r;

    /* 描述符字（S_HEAD 弹出） */
    reg [31:0] d0, d1, d2, d3;
    reg [31:0] d_addr_r;                 // 本条描述符自己的地址（诊断）
    /* 几何表字（进 S_EVAL 前一定已锁存） */
    reg [31:0] geff0, geff1, geff2, geff3;

    /* 展开结果（S_EVAL 组合算、进 S_PUSH 前锁存） */
    reg [31:0] w0_r, w1_r, w2_r, w3_r, w4_r, w5_r, w6_r, w7_r;
    reg [3:0]  pcnt;

    /* 几何表 cache：16 条 × 16B 直接映射（SPR_ID[3:0] 索引 + 高位标签） */
    reg [127:0] gc_data [0:15];
    reg [11:0]  gc_tag  [0:15];
    reg         gc_v    [0:15];
    integer     gi;

    /* ---------------- 描述符 FIFO（复用已验证的 sync_fifo） ---------------- */
    wire         df_full, df_empty;
    wire [4:0]   df_count;
    wire [127:0] df_dout;
    wire [4:0]   df_room   = DESC_DEPTH[4:0] - df_count;
    /* 水位触发：FIFO 剩余 ≤ WM 且还有没取的、且 FIFO 装得下 ⇒ 先补一块。
     * 顺序上必须在 df_rd 之前（df_rd 要排除"这一拍其实是要去取新块"）。 */
    wire [3:0]   wm_eff    = s_prefetch ? s_wm : 4'd0;
    wire         fetch_now = (st == S_HEAD) && !end_seen &&
                             (issued < s_count) && (df_count <= {1'b0, wm_eff}) &&
                             (df_room != 5'd0);
    wire         df_wr = (st == S_FILL) && desc_rvalid;
    wire         df_rd = (st == S_HEAD) && !df_empty && !fetch_now;
    wire         df_rst_n = rst_n & ~go_pulse_r;   // 每条列表从空开始

    /* ---------------- 组合：地址 / 水位 / 预取 ---------------- */
    wire [31:0] desc_cur  = s_base + {issued, 4'b0};
    wire [15:0] remain16  = s_count - issued;
    wire [15:0] b4k       = 16'd256 - {8'd0, desc_cur[11:4]};   // 到 4KB 边界
    wire [15:0] chunk16   = (s_chunk == 4'd0) ? 16'd8 : {12'd0, s_chunk};
    wire [15:0] limit16   = (remain16 < chunk16) ? remain16 : chunk16;
    wire [15:0] room16    = {11'd0, df_room};
    wire [15:0] n16       = (limit16 < room16) ? limit16 : room16;
    wire [15:0] n16b      = (n16 < b4k) ? n16 : b4k;
    wire [7:0]  nbeats    = (n16b == 16'd0) ? 8'd1 : n16b[7:0];

    /* ---------------- 描述符字段 ---------------- */
    wire [15:0] spr_id   = d1[15:0];
    wire [15:0] flags    = d1[31:16];
    wire [1:0]  f_op     = flags[1:0];
    wire        f_mirx   = flags[2];
    wire        f_miry   = flags[3];
    wire        f_clip   = flags[4];
    wire        f_szov   = flags[5];
    wire        f_srcoff = flags[6];
    wire        f_masken = flags[7];
    wire [1:0]  f_maskmd = flags[9:8];
    wire        f_end    = flags[10];
    wire        f_irqaf  = flags[11];
    wire        f_chain  = flags[12];
    wire [15:0] d_key    = d2[15:0];
    wire [7:0]  d_alpha  = d2[23:16];
    wire [15:0] d_maskid = d3[15:0];
    wire [7:0]  d_wovr   = d3[23:16];
    wire [7:0]  d_hovr   = d3[31:24];

    /* ---------------- 几何表字段（S_EVAL 用锁存值） ---------------- */
    wire [31:0] g_atlas  = geff0;
    wire [15:0] g_stride = geff1[15:0];
    wire [15:0] g_keydef = geff1[31:16];
    wire [15:0] g_w      = geff2[15:0];
    wire [15:0] g_h      = geff2[31:16];
    wire [15:0] g_sx     = geff3[15:0];
    wire [15:0] g_sy     = geff3[31:16];

    /* ---------------- S_CHK：几何索引 / 地址 / 未实现位 ---------------- */
    wire [31:0] geom_addr = s_geom_base + {spr_id, 4'b0};
    wire        geom_ovf  = (geom_addr < s_geom_base);
    /* FILL + SIZE_OVR 时几何表完全用不到 ⇒ 不读；其余情况都需要几何表 */
    wire        need_geom = !((f_op == 2'd1) && f_szov);
    wire        e_gidx    = (s_geom_max == 16'd0) ? need_geom
                                                  : (spr_id >= s_geom_max);
    wire        e_gaddr   = need_geom &&
                            ((geom_addr[3:0] != 4'd0) || geom_ovf);
    /* ★S3：掩码只实现了 MASK_MODE=01（"1=该块全透明⇒跳过"）。MASK_EN=1 而模式是
     * 别的编码（00=0 跳过 / 10=逐像素 alpha 阈值 / 11=保留）时**报未实现**，
     * 而不是拿 01 的语义去猜 —— 设计文档 §5.1 把这三位留给 S3，这里就用满它。
     * `-DMASK_SKIP_OFF`（A/B）下连这条检查也回到 S2：MASK_EN 被原样忽略。 */
`ifdef MASK_SKIP_OFF
    wire        e_maskmd  = 1'b0;
`else
    wire        e_maskmd  = f_masken && (f_maskmd != 2'b01);
`endif
    wire        e_unsup   = f_mirx | f_miry | f_srcoff | f_chain | e_maskmd;
    wire [3:0]  gcidx     = spr_id[3:0];
    wire        gc_hit    = s_gec && gc_v[gcidx] && (gc_tag[gcidx] == spr_id[15:4]);
    wire        chk_err   = e_gidx | e_gaddr | e_unsup;

    /* ---------------- S_EVAL：尺寸 / 位置 / 裁剪 ---------------- */
    wire [15:0] e_w = f_szov ? {8'd0, d_wovr} : g_w;
    wire [15:0] e_h = f_szov ? {8'd0, d_hovr} : g_h;

    wire [31:0] rx0   = {{16{d0[15]}}, d0[15:0]};         // 二元补码 32bit
    wire [31:0] ry0   = {{16{d0[31]}}, d0[31:16]};
    wire [31:0] fbw32 = {16'd0, s_fb_w};
    wire [31:0] fbh32 = {16'd0, s_fb_h};
    wire [31:0] rx1   = rx0 + {16'd0, e_w};
    wire [31:0] ry1   = ry0 + {16'd0, e_h};

    wire off_x0 = $signed(rx0) < 0;
    wire off_y0 = $signed(ry0) < 0;
    wire off_x1 = $signed(rx1) > $signed(fbw32);
    wire off_y1 = $signed(ry1) > $signed(fbh32);
    wire off_any = off_x0 | off_y0 | off_x1 | off_y1;

    wire [31:0] cx0 = off_x0 ? 32'd0  : rx0;
    wire [31:0] cy0 = off_y0 ? 32'd0  : ry0;
    wire [31:0] cx1 = off_x1 ? fbw32  : rx1;
    wire [31:0] cy1 = off_y1 ? fbh32  : ry1;
    wire clip_empty = ($signed(cx1) <= $signed(cx0)) ||
                      ($signed(cy1) <= $signed(cy0));

    wire [31:0] eff_x  = f_clip ? cx0 : rx0;
    wire [31:0] eff_y  = f_clip ? cy0 : ry0;
    wire [31:0] eff_w  = f_clip ? (cx1 - cx0) : {16'd0, e_w};
    wire [31:0] eff_h  = f_clip ? (cy1 - cy0) : {16'd0, e_h};
    wire [31:0] dx_off = f_clip ? (cx0 - rx0) : 32'd0;
    wire [31:0] dy_off = f_clip ? (cy0 - ry0) : 32'd0;

    wire e_zero   = (eff_w[15:0] == 16'd0) || (eff_h[15:0] == 16'd0);
    wire e_bounds = s_strict && !f_clip && off_any;
    wire eval_err = e_zero | e_bounds;
    wire eval_skip= f_clip && clip_empty;                 // 裁完是空矩形 ⇒ 跳过不下发

    /* ---------------- S_EVAL：展开（设计文档 §5.3 的表） ---------------- */
    wire [15:0] src_sy = g_sy + dy_off[15:0];
    wire [15:0] src_sx = g_sx + dx_off[15:0];
    wire [31:0] src_addr = g_atlas + ({16'd0, src_sy} * {16'd0, g_stride})
                                   + ({16'd0, src_sx} * 32'd2);
    wire [31:0] dst_addr = s_dst_base + ({16'd0, eff_y[15:0]} * {16'd0, s_dst_stride})
                                      + ({16'd0, eff_x[15:0]} * 32'd2);
    /* ★S3：透明块掩码随命令字下传 —— 8 字命令的"空位"就在 w0[31:2]
     *   （设计文档 §2.2 明确写着 w0[31:2] 当前未用、dbg_opword 只显示），
     *   于是 S3 不需要 §13 设想的"平行 ATTR FIFO"（S2 没做，做它要两个 FIFO
     *   严格同步，一旦错位就是静默错掩码）。掩码本体仍是描述符里 S3 预留的
     *   dw3[15:0]=MASK_ID（16 位 4×4 块位图）与 dw1.FLAGS[7]=MASK_EN，
     *   描述符字段布局一位没动。
     *   w0 = {MASK[15:0], 13'd0, MASK_EN, OP[1:0]}；CPU 侧写 0 ⇒ 行为与今天相同。 */
`ifdef MASK_SKIP_OFF
    wire [15:0] x_msk    = 16'd0;          // A/B：连命令字都逐位回到 S2
    wire        x_msk_en = 1'b0;
`else
    wire [15:0] x_msk    = d_maskid;
    wire        x_msk_en = f_masken;
`endif
    wire [31:0] x_w0 = {x_msk, 13'd0, x_msk_en, f_op};
    wire [31:0] x_w1 = (f_op == 2'd1) ? 32'd0 : src_addr;
    wire [31:0] x_w2 = dst_addr;
    wire [31:0] x_w3 = {16'd0, g_stride};
    wire [31:0] x_w4 = {16'd0, s_dst_stride};
    wire [31:0] x_w5 = {eff_h[15:0], eff_w[15:0]};
    wire [31:0] x_w6 = {24'd0, d_alpha};
    wire [31:0] x_w7 = (f_op == 2'd1) ? {16'd0, d_key}
                                      : ((d_key == 16'hFFFF) ? {16'd0, g_keydef}
                                                             : {16'd0, d_key});

    /* ---------------- 输出 ---------------- */
    assign desc_req   = (st == S_CHUNK) || ((st == S_GEOM) && !gc_hit);
    assign desc_addr  = (st == S_GEOM) ? geom_addr : desc_cur;
    assign desc_len   = (st == S_GEOM) ? 8'd1 : nbeats;
    assign desc_rready= 1'b1;      // 回程一律收下：异常后的残留 beat 直接丢弃，
                                   // 绝不把 axi_rd_master 的 R 队列堵死

    assign dl_cmd_req  = (st == S_PUSH);
    assign dl_cmd_data = (pcnt == 4'd0) ? w0_r : (pcnt == 4'd1) ? w1_r :
                         (pcnt == 4'd2) ? w2_r : (pcnt == 4'd3) ? w3_r :
                         (pcnt == 4'd4) ? w4_r : (pcnt == 4'd5) ? w5_r :
                         (pcnt == 4'd6) ? w6_r : w7_r;
    assign dl_cmd_last = (pcnt == 4'd7);
    wire   last_desc   = end_seen | f_end | ((consumed_r + 16'd1) >= s_count);

    assign busy       = (st != S_IDLE);
    assign done       = done_r;
    assign err        = |err_r;
    assign aborted    = aborted_r;
    assign stall      = (st != S_IDLE) &&
                        (((st == S_PUSH)  && !dl_cmd_gnt) ||
                         ((st == S_CHUNK) && !desc_ready) ||
                         ((st == S_GEOM)  && !gc_hit && !desc_ready) ||
                         ((st == S_HEAD)  && df_empty && !fetch_now &&
                          (df_count == 5'd0) && (issued >= s_count) && !end_seen));
    assign consumed   = consumed_r;
    assign active_buf = s_buf;
    /* DL_ERR 读回值：{保留[31:25], UNSUPPORTED[24], 序号[23:16], 保留[15:8], 错误位[7:0]}。
     * ★ 拼接里那个 8'd0 不能省：{7'd0,r[24],idx,r[7:0]} 只有 24 bit，零扩展后
     *   序号会落到 bit[15:8]、UNSUPPORTED 落到 bit16（本 TB 的 M3/M9 抓到过）。 */
    assign err_word   = {7'd0, err_r[24], err_idx_r, 8'd0, err_r[7:0]};
    assign fault_addr = fault_r;
    assign perf_cycles= perf_r;
    assign auto_go_hold = auto_go_r;

    /* ---------------- 看门狗 / 读回程错误 ---------------- */
    wire wd_hit = (s_timeout != 16'd0) && (wd_cnt >= s_timeout);
    wire rd_resp_err = ((st == S_FILL) || (st == S_GEOMW)) &&
                       desc_rvalid && (desc_rresp != 2'b00);
    /* "停住不动"的判据：配合 wd_hit（超时）才构成 WATCHDOG 错误 */
    wire rd_wd_err   = ((st == S_CHUNK) && !desc_ready) ||
                       ((st == S_FILL)  && !desc_rvalid) ||
                       ((st == S_GEOM)  && !gc_hit && !desc_ready) ||
                       ((st == S_GEOMW) && !desc_rvalid) ||
                       ((st == S_HEAD)  && df_empty && !fetch_now &&
                        (df_count == 5'd0) &&
                        !(issued >= s_count) && !end_seen) ||
                       ((st == S_DRAIN) && rd_busy);

    wire err_any = rd_resp_err | (wd_hit && rd_wd_err) |
                   ((st == S_CHK) && chk_err) |
                   ((st == S_EVAL) && eval_err);
    wire [31:0] err_any_w = rd_resp_err ? 32'h0000_0020 :
                            ((st == S_CHK)  && e_unsup)  ? 32'h0100_0000 :
                            ((st == S_CHK)  && e_gidx)   ? 32'h0000_0002 :
                            ((st == S_CHK)  && e_gaddr)  ? 32'h0000_0004 :
                            ((st == S_EVAL) && e_zero)   ? 32'h0000_0080 :
                            ((st == S_EVAL) && e_bounds) ? 32'h0000_0008 :
                                                            32'h0000_0010;  // WATCHDOG
    wire [31:0] err_any_a = ((st == S_GEOM) || (st == S_GEOMW)) ? geom_addr :
                            ((st == S_CHK) && (e_gidx || e_gaddr)) ? geom_addr :
                                                                     d_addr_r;

    /* 出错/中止这一拍，desc 流里还剩多少 beat 没回来（用于 S_DRAIN 重新同步）。
     * 设计文档 §8.3 规定 BUSY 只需等引擎 done_out —— 若还要求 !rd_busy，
     * 从机永不回 R 时 BUSY 就永远不落（看门狗也就白报了）。所以这里改成：
     * BUSY 按 §8.3 释放，把"回程可能错位"这件事用一个 unsync 标志记下来，
     * 下一次 GO 先进 S_DRAIN 等读通道真空，再开始取指。 */
    wire [7:0] abandon_beats = (st == S_FILL)  ? (rd_beats - rd_cnt) :
                               (st == S_GEOMW) ? 8'd1 : 8'd0;
    wire       will_abandon  = (err_any || abort_pulse) && (abandon_beats != 8'd0) &&
                               (st != S_IDLE);

    /* ---------------- 主状态机 ---------------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st          <= S_IDLE;
            s_count     <= 16'd0;
            s_base      <= 32'd0;
            s_geom_base <= 32'd0;
            s_dst_base  <= 32'd0;
            s_geom_max  <= 16'd0;
            s_dst_stride<= 16'd0;
            s_fb_w      <= 16'd0;
            s_fb_h      <= 16'd0;
            s_timeout   <= 16'd0;
            s_chunk     <= 4'd8;
            s_wm        <= 4'd4;
            s_prefetch  <= 1'b1;
            s_gec       <= 1'b1;
            s_strict    <= 1'b1;
            s_buf       <= 2'd0;
            issued      <= 16'd0;
            consumed_r  <= 16'd0;
            end_seen    <= 1'b0;
            rd_beats    <= 8'd0;
            rd_cnt      <= 8'd0;
            perf_run    <= 1'b0;
            perf_cnt    <= 32'd0;
            perf_r      <= 32'd0;
            wd_cnt      <= 16'd0;
            done_r      <= 1'b0;
            aborted_r   <= 1'b0;
            auto_go_r   <= 1'b0;
            go_pulse_r  <= 1'b0;
            unsync      <= 1'b0;
            err_r       <= 32'd0;
            err_idx_r   <= 8'd0;
            fault_r     <= 32'd0;
            d0<=32'd0; d1<=32'd0; d2<=32'd0; d3<=32'd0; d_addr_r<=32'd0;
            geff0<=32'd0; geff1<=32'd0; geff2<=32'd0; geff3<=32'd0;
            w0_r<=32'd0; w1_r<=32'd0; w2_r<=32'd0; w3_r<=32'd0;
            w4_r<=32'd0; w5_r<=32'd0; w6_r<=32'd0; w7_r<=32'd0;
            pcnt        <= 4'd0;
            for (gi = 0; gi < 16; gi = gi + 1) begin
                gc_v[gi] <= 1'b0; gc_tag[gi] <= 12'd0; gc_data[gi] <= 128'd0;
            end
        end else begin
            go_pulse_r <= go_pulse;

            /* ---- 命令周期计数（GO→DONE，与 PERF 0x1C 同风格） ---- */
            if (st == S_IDLE) begin
                if (go_pulse) begin perf_cnt <= 32'd1; perf_run <= 1'b1; end
            end else if (perf_run)
                perf_cnt <= perf_cnt + 32'd1;

            /* ---- DL_ERR W1C（bit0~7 与 bit24 各自独立） ---- */
            if (err_clr_pulse) begin
                err_r[7:0]  <= err_r[7:0]  & ~err_clr_mask[7:0];
                err_r[24]   <= err_r[24]   & ~err_clr_mask[24];
                if ((err_clr_mask[7:0] == 8'hFF) && err_clr_mask[24])
                    err_idx_r <= 8'd0;
            end
            if (base_align_err) err_r[0] <= 1'b1;
            if (list_rewr_pulse) done_r <= 1'b0;

            /* ---- 看门狗 ---- */
            if ((st == S_HEAD) && !df_empty && !fetch_now) wd_cnt <= 16'd0;
            else if ((st != S_IDLE) && (st != S_END) && (st != S_ERR) &&
                     (st != S_ABORT))
                wd_cnt <= wd_cnt + 16'd1;

            if (abort_pulse && (st != S_IDLE) && (st != S_END) &&
                (st != S_ERR) && (st != S_ABORT)) begin
                /* ABORT 只停"还没进 FIFO 的命令"；已入队的照跑（等 eng_done）。
                 * ABORT 不写 DL_ERR（设计文档 §8.4）。 */
                aborted_r <= 1'b1;
                if (will_abandon) unsync <= 1'b1;
                st        <= S_ABORT;
            end else if (err_any && (st != S_IDLE)) begin
                err_r     <= err_r | err_any_w;
                err_idx_r <= consumed_r[7:0];
                fault_r   <= err_any_a;
                if (will_abandon) unsync <= 1'b1;
                st        <= S_ERR;
            end else begin
            case (st)
            /* ================= 空闲 ================= */
            S_IDLE: begin
                auto_go_r <= 1'b0;
                if (go_pulse) begin
                    s_count     <= cfg_count;
                    s_base      <= cfg_buf_sel ? cfg_base1 : cfg_base0;
                    s_geom_base <= cfg_geom_base;
                    s_dst_base  <= cfg_dst_base;
                    s_geom_max  <= cfg_geom_max;
                    s_dst_stride<= cfg_dst_stride;
                    s_fb_w      <= cfg_fb_w;
                    s_fb_h      <= cfg_fb_h;
                    s_timeout   <= cfg_timeout;
                    s_chunk     <= cfg_chunk;
                    s_wm        <= cfg_wm;
                    s_prefetch  <= cfg_prefetch;
                    s_gec       <= cfg_gec;
                    s_strict    <= cfg_strict;
                    s_buf       <= {1'b0, cfg_buf_sel};
                    issued      <= 16'd0;
                    consumed_r  <= 16'd0;
                    end_seen    <= 1'b0;
                    rd_cnt      <= 8'd0;
                    wd_cnt      <= 16'd0;
                    aborted_r   <= 1'b0;
                    pcnt        <= 4'd0;
                    perf_r      <= 32'd0;
                    done_r      <= 1'b0;
                    /* GO 时刻的三项结构性检查（都在即将采样的值上做） */
                    if ((cfg_buf_sel ? cfg_base1 : cfg_base0) & 32'hF) begin
                        err_r   <= err_r | 32'h0000_0001;      // DESC_RANGE 未对齐
                        err_idx_r <= 8'd0;
                        fault_r <= cfg_buf_sel ? cfg_base1 : cfg_base0;
                        st      <= S_ERR;
                    end else if (cfg_count > COUNT_MAX) begin
                        err_r   <= err_r | 32'h0000_0040;      // DESC_COUNT
                        err_idx_r <= 8'd0;
                        fault_r <= cfg_buf_sel ? cfg_base1 : cfg_base0;
                        st      <= S_ERR;
                    end else if ((({1'b0, (cfg_buf_sel ? cfg_base1 : cfg_base0)}
                                   + {1'b0, cfg_count, 4'b0}) >> 32) != 1'b0) begin
                        /* 列表尾越出 32bit 地址空间（"源地址跑出映射内存"） */
                        err_r   <= err_r | 32'h0000_0001;      // DESC_RANGE
                        err_idx_r <= 8'd0;
                        fault_r <= cfg_buf_sel ? cfg_base1 : cfg_base0;
                        st      <= S_ERR;
                    end else if (cfg_count == 16'd0)
                        st <= S_END;                           // 空列表
                    else if (unsync)
                        st <= S_DRAIN;                         // 先与读通道重新同步
                    else
                        st <= S_CHUNK;
                end
            end

            /* ================= 发一块描述符读 ================= */
            S_CHUNK: begin
                if (desc_req && desc_ready) begin
                    issued   <= issued + n16b;
                    rd_beats <= nbeats;
                    rd_cnt   <= 8'd0;
                    st       <= S_FILL;
                end
            end

            /* ================= 收 R beat → desc FIFO ================= */
            S_FILL: begin
                if (desc_rvalid) begin
                    rd_cnt <= rd_cnt + 8'd1;
                    if ((rd_cnt + 8'd1) >= rd_beats) st <= S_HEAD;
                end
            end

            /* ================= 取一条描述符（含水位预取） =================
             * ★ 结束判据必须用 `df_count == 0`（FIFO 真实占用）而不是 `df_empty`：
             *   sync_fifo 是同步读 + 输出寄存器，最后一个 beat 写进去之后还要
             *   2 拍才在 `dout` 上可见，这段窗口里 empty=1 但数据已经在了
             *   （实测 df_count=2 / empty=1 / out_v=0）。只看 empty 就会在
             *   这里误判"列表跑完了"直接进 S_END —— tb_dl_malformed 的
             *   M6/M8b/M8c/M9（count=1~2 的短列表）抓到的就是这个。 */
            S_HEAD: begin
                if (fetch_now)
                    st <= S_CHUNK;                 // 先补一块（FIFO 里还有存货）
                else if (!df_empty) begin
                    d0 <= df_dout[31:0];
                    d1 <= df_dout[63:32];
                    d2 <= df_dout[95:64];
                    d3 <= df_dout[127:96];
                    d_addr_r <= s_base + {consumed_r, 4'b0};
                    st <= S_CHK;
                end else if ((df_count == 5'd0) && (issued >= s_count || end_seen))
                    st <= S_END;
            end

            /* ================= 查几何索引 / 保留位 ================= */
            S_CHK: begin
                if (f_end) end_seen <= 1'b1;
                if (need_geom) st <= S_GEOM;
                else begin
                    /* FILL + SIZE_OVR：几何表用不到，塞一份零几何（W/H 走 dw3） */
                    geff0 <= 32'd0;
                    geff1 <= 32'd0;
                    geff2 <= {d_hovr, d_wovr};
                    geff3 <= 32'd0;
                    st    <= S_EVAL;
                end
            end

            /* ================= 几何表 ================= */
            S_GEOM: begin
                if (gc_hit) begin
                    geff0 <= gc_data[gcidx][31:0];
                    geff1 <= gc_data[gcidx][63:32];
                    geff2 <= gc_data[gcidx][95:64];
                    geff3 <= gc_data[gcidx][127:96];
                    st    <= S_EVAL;
                end else if (desc_req && desc_ready)
                    st <= S_GEOMW;
            end
            S_GEOMW: begin
                if (desc_rvalid && (desc_rresp == 2'b00)) begin
                    geff0 <= desc_rdata[31:0];
                    geff1 <= desc_rdata[63:32];
                    geff2 <= desc_rdata[95:64];
                    geff3 <= desc_rdata[127:96];
                    if (s_gec) begin
                        gc_v[gcidx]    <= 1'b1;
                        gc_tag[gcidx]  <= spr_id[15:4];
                        gc_data[gcidx] <= desc_rdata;
                    end
                    st <= S_EVAL;
                end
            end

            /* ================= 尺寸/边界/裁剪 + 展开 ================= */
            S_EVAL: begin
                if (eval_skip) begin
                    /* CLIP_EN 裁完是空矩形：消费掉这一条，不产生任何命令 */
                    consumed_r <= consumed_r + 16'd1;
                    if (last_desc) st <= S_END;
                    else           st <= S_HEAD;
                end else begin
                    w0_r <= x_w0; w1_r <= x_w1; w2_r <= x_w2; w3_r <= x_w3;
                    w4_r <= x_w4; w5_r <= x_w5; w6_r <= x_w6; w7_r <= x_w7;
                    pcnt <= 4'd0;
                    st   <= S_PUSH;
                end
            end

            /* ================= 推 8 字命令 ================= */
            S_PUSH: begin
                if (dl_cmd_gnt) begin
                    if (pcnt == 4'd7) begin
                        consumed_r <= consumed_r + 16'd1;
                        pcnt       <= 4'd0;
                        if (!auto_go_r && cfg_auto_go) auto_go_r <= 1'b1;
                        if (last_desc) st <= S_END;
                        else           st <= S_HEAD;
                    end else
                        pcnt <= pcnt + 4'd1;
                end
            end

            /* ================= 结束 / 错误 / 中止 ================= */
            S_END: begin
                if (eng_done) begin
                    done_r   <= 1'b1;
                    perf_r   <= perf_cnt;
                    perf_run <= 1'b0;
                    st       <= S_IDLE;
                end
            end
            S_ERR: begin
                if (eng_done) begin
                    perf_r   <= perf_cnt;
                    perf_run <= 1'b0;
                    st       <= S_IDLE;    // 按 §8.3：等引擎 done_out 即可（不等 rd_busy）
                end
            end
            S_ABORT: begin
                if (eng_done) begin
                    perf_r   <= perf_cnt;
                    perf_run <= 1'b0;
                    st       <= S_IDLE;
                end
            end
            /* GO 时若上一张表遗留了在飞 desc 读：先等读通道真空再看新表，
             * 否则那笔的残留 beat 会被当成新表的描述符（回程错位）。 */
            S_DRAIN: begin
                if (!rd_busy) begin
                    unsync <= 1'b0;
                    st     <= S_CHUNK;
                end
            end
            default: st <= S_IDLE;
            endcase
            end
        end
    end

    /* 描述符 FIFO（GO 脉冲实时钟清空：跨列表不能残留上一条的存货） */
    sync_fifo #(.DW(128), .DEPTH(DESC_DEPTH)) u_desc_fifo (
        .clk(clk), .rst_n(df_rst_n),
        .wr_en(df_wr), .din(desc_rdata),
        .rd_en(df_rd), .rd_ack(), .dout(df_dout),
        .full(df_full), .empty(df_empty), .count(df_count)
    );
endmodule
