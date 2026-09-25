/* =========================================================================
 * blt_regs_axi_lite.v — BitBlt 引擎寄存器组（AXI-Lite 从机）
 * -------------------------------------------------------------------------
 * 地址映射（对齐 software/blt_regs.h）：
 *   0x00 CTRL            RW : bit0=GO(自动消费使能) bit1=IRQ_EN(DONE) bit2=SOFT_RST
 *   0x04 STATUS          R  : bit0=BUSY bit1=DONE(电平) bit2=ERR bit3=FIFO_EMPTY
 *   0x08 CMD_FIFO_DATA   W  : 指令字（连写 8 字 = 一条）
 *   0x0C CMD_FIFO_COUNT  R  : 已排队完整指令条数
 *   0x10 IRQ_STATUS      W1C: bit0=DONE 中断
 *                             ★ bit1=FRAME 中断（v2.7：扫描输出帧边界脉冲，
 *                                每个场恰好 1 个 core 拍；软件写 1 清 0）
 *   0x14 IRQ_EN          RW : bit0=DONE 使能 bit1=FRAME 使能（CTRL.bit1 只动 bit0）
 *   0x18 DBG_CUR_CMD     R  : 当前执行指令 word0（op 等）
 *   0x1C PERF            R  : 性能计数（二期实现，预留）
 *   0x20 SCAN_DBG        R  : [15:0]=扫描输出欠载行数 [31:16]=取数看门狗中止次数
 *                             （显示被 DDR 竞争拖垮的**板级量化证据**，正常恒 0）
 *   0x24 FB_SEL          W  : ★v2.7 [1:0] = 希望扫描输出显示的缓冲
 *                             （0=FB_BASE 1=FB_BASE1 2=FB_BASE2，3 保留→回落到 0）。
 *                             写下去只是**请求**：扫描输出在下一个帧边界（垂直消隐起点）
 *                             才锁存它 ⇒ 绝不会出现"一场里混两个缓冲"的帧。
 *                             （读回 = 尚未生效的请求值，仅供调试）
 *   0x28 FB_STAT         R  : [1:0]   = fb_cur_sel（**已经生效**的显示缓冲选择）
 *                             [31:16] = frame_cnt（扫描输出场计数，每个帧边界 +1）
 *                             软件写 FB_SEL 后轮询本寄存器确认翻转已生效，
 *                             也可以用它把渲染节奏锁到真实场频上。
 *                             ★ 两个字段都来自 fb_scanout 的 core 域寄存器，直接读，无跨域采样问题
 *   ---- ★v2.7 并发清屏引擎（见 rtl/clr_engine.v + 功能清单 §21）----
 *   0x2C CLR_ADDR        RW : 起始字节地址（读回 = 已写入值）
 *   0x30 CLR_STRIDE      RW : 字节/行
 *   0x34 CLR_WH          RW : (h<<16)|w
 *   0x38 CLR_COLOR       RW : RGB565 常量色
 *   0x3C CLR_CTRL        W  : bit0=GO(1 拍脉冲) [3:2]=目标缓冲号 bit4=ERR_CLR(1 拍脉冲)
 *   0x40 CLR_STAT        R  : bit0=BUSY bit1=目标缓冲已清干净 [5:2]=四块 clean 位图
 *                             bit6=ERR(互斥拒绝/运行中被抢，sticky)
 *                             [31:16]=上一次 clear 的 AW 突发数（事务计数）
 *   0x44 DRAW_SEL        RW : [1:0] = BitBlt 引擎**正在画**的缓冲（软件每趟开画时写）。
 *                             写它会把该缓冲的 clean 位清零（画过就不算干净）。
 *                             硬件互斥的第二半：清屏目标 == 本值 ⇒ 拒绝写。
 *   0x48 CLR_CYC         R  : 上一次 clear 的 core 周期数（32 位，不饱和）
 *   ---- ★v2.11 显示列表 / 描述符表（S2，见 doc/display_list_design.md + rtl/dl_fetch.v）----
 *   0x4C DL_BASE0        RW : [31:4] 列表 A 基地址（16B 对齐；未对齐写被忽略 + DESC_RANGE）
 *   0x50 DL_BASE1        RW : [31:4] 列表 B 基地址（乒乓的另一张）
 *   0x54 DL_COUNT        RW : [15:0] 本列表描述符条数（0 = 合法空列表；>4095 ⇒ DESC_COUNT）
 *   0x58 DL_CTRL         W  : bit0=GO(1 拍脉冲，BUSY 时忽略) bit1=ABORT(1 拍脉冲)
 *                             bit2=BUF_SEL bit3=IRQ_EN bit4=AUTO_GO(复位 1)
 *                             bit5=STRICT_BOUNDS(复位 1)
 *   0x5C DL_STATUS       R  : bit0=BUSY bit1=DONE bit2=ERR bit3=ABORTED bit4=STALL
 *                             [9:8]=ACTIVE_BUF [31:16]=CONSUMED
 *   0x60 DL_ERR          R/W1C: [7:0]=DESC_RANGE/GEOM_INDEX/GEOM_RANGE/SPRITE_BOUNDS/
 *                             WATCHDOG/AXI_RRESP/DESC_COUNT/ZERO_SIZE
 *                             [23:16]=出错描述符序号 [24]=UNSUPPORTED(MIRROR/CHAIN 等)
 *   0x64 DL_FAULT_ADDR   R  : 出错时正在访问的地址
 *   0x68 DL_GEOM_BASE    RW : [31:4] 精灵几何表基地址（16B/条）
 *   0x6C DL_GEOM_MAX     RW : [15:0] 几何表条目数（0 = 关闭几何表）
 *   0x70 DL_DST_BASE     RW : [31:0] 本列表的目标缓冲基地址
 *   0x74 DL_CFG          RW : bit0=PREFETCH_EN(1) bit1=GEOM_CACHE_EN(1)
 *                             [7:4]=CHUNK(8) [11:8]=FIFO_WM(4)
 *   0x78 DL_TIMEOUT      RW : [15:0] 单条描述符看门狗（core 拍，复位 4096；0=关）
 *   0x7C DL_PERF         R  : 上一次列表的 core 周期数（GO→DONE）
 *   0x80 DL_VERSION      R  : 32'h0210_0002（[7:0]=0x02 S2、[31:16]=0x0210）
 *   0x84 DL_DST_STRIDE   RW : [15:0] 目标字节行距（设计文档 §14.7 的落地，见 dl_fetch.v 头注释）
 *   0x88 DL_FB_WH        RW : [15:0]=FB_W [31:16]=FB_H（SPRITE_BOUNDS/CLIP_EN 用）
 *   0x10 IRQ_STATUS 追加 bit2 = DL_DONE（W1C）；0x14 IRQ_EN 追加 bit2 = DL_DONE 使能
 *   ---- ★S5（v3.2）属性侧口 / scissor / 扫描输出颜色 LUT（全部**新增**，旧地址一位没动）----
 *   0x8C ATTR_PORT       W  : ★属性侧口。每写一次 = 往**属性 FIFO（深 16，FWFT）**压入
 *                             一个 32bit 属性字；引擎在**每条命令起始**（ST_DEC）按序弹
 *                             一个字 ⇒ 属性与命令**按顺序配对**（先写属性、再写命令）。
 *                             FIFO **空**时引擎用默认字（= 兼容档：blend 0 / RGB565 /
 *                             global_alpha 255 / flags 0）⇒ 不写属性的软件行为与今天逐位相同。
 *                             位域：[3:0] blend_mode（0=按算子默认行为，1=alpha 混合，
 *                             2=加算饱和，3=乘法，4~15 保留→按 0）；[5:4] src_format
 *                             （0=RGB565，1=ARGB1555，2=ARGB4444，3 保留→按 0）；
 *                             [13:6] global_alpha（255=不淡）；[15:14]/[23:16] 保留
 *                             （键色仍走命令字的 color）；[31:24] flags：bit0=alpha 测试
 *                             （有效 alpha=0 的像素不写），bit1=强制不透明（按 255 算）。
 *                             写入**不看 WSTRB**（与 0x08 CMD_FIFO_DATA 同口径，整字入队）。
 *   0x90 CLIP_X0         RW : scissor 左边界（含）
 *   0x94 CLIP_X1         RW : scissor 右边界（**不含**）⇒ 命中条件 X0 ≤ x < X1
 *   0x98 CLIP_Y0         RW : scissor 上边界（含）
 *   0x9C CLIP_Y1         RW : scissor 下边界（**不含**）
 *   0xA0 CLIP_CTRL       RW : bit0=ENABLE（复位 0 ⇒ 逐位回到今天）。坐标是**本条命令的
 *                             目的矩形局部坐标**（原点 = 该行 dst_base + row*stride 的第一个
 *                             像素、第 0 行 = 第一行）。启用后：矩形外的像素不写，整行在
 *                             矩形外的行**不取数、不算**直接跳过（见 blt_engine_fsm）。
 *                             ★ 引擎在命令起始（ST_DEC）锁存本组寄存器 ⇒ 命令中途改寄存器
 *                             不会撕裂正在画的这条命令，下一命令才生效。
 *   0xA4 LUT_ADDR        RW : [9:8]=通道（0=R 1=G 2=B，3 保留→该次写忽略）[7:0]=表内下标
 *   0xA8 LUT_DATA        W  : [7:0]=写入当前下标/当前 bank 的输出值（写它就产生 1 拍写脉冲）
 *   0xAC LUT_CTRL        RW : bit0=ENABLE bit1=BANK（**写入 bank** 选择）。
 *                             ★ 语义（见 §28 与 fb_scanout.v）：bit1 选的是"LUT_DATA 写进
 *                             哪个 bank"，而**显示读的是另一个 bank**（两者永远不同 ⇒
 *                             写表在物理上碰不到正在显示的那张表）。bit1 与 bit0 都只在
 *                             fb_scanout 的**帧边界**才被锁存成"显示用的值"⇒ 一场之内
 *                             只读一个 bank、绝不会半场换表。
 *                             软件协议：读 0xB0 拿到当前显示的 bank → 整张写新表（自动落到
 *                             另一个 bank）→ 写一次 bit1 = 刚写的那个 bank ⇒ 下一帧生效。
 *   0xB0 LUT_STAT        R  : bit0 = **正在显示**的 bank（= fb_scanout 锁存值的反相）
 * -------------------------------------------------------------------------
 * ★v2.11 cmd_fifo 写口仲裁（I2 的落地，见本文件"指令 FIFO 入队"一节末）：
 *   DFU（dl_fetch）与 CPU 在**整条命令粒度**上互斥。DFU 在 S_PUSH 拉高 dl_cmd_req，
 *   从第 1 个字到第 8 个字期间一直举着；这段时间 CPU 侧的 awready/wready 被压低
 *   （AXI 层反压，不是静默丢弃）。CPU 若正在写一条命令（cpu_word_cnt != 0），
 *   DFU 也让路。⇒ FIFO 里的字序永远是"整条整条"的，引擎的 8 字对齐永不错位。
 *   判据里 dl_gnt 与 cpu_en 共用同一个 fifo_full、同一拍求值 ⟹ 受理即入队。
 * -------------------------------------------------------------------------
 * 行为要点：
 *   - CTRL.GO 写 1 置 run_en（blt_init/blt_start 用法）；CTRL bit1 与 0x14 均写 IRQ_EN
 *   - SOFT_RST 输出 1 拍脉冲；引擎侧复位由顶层按 soft_rst 联动
 *   - STATUS 各状态位来自引擎（本模块只做位映射）
 *   - IRQ_STATUS：DONE 完成沿 / IRQ_EN 使能沿补偿置位；W1C 清除（W1C 优先于置位）
 *   - CMD_FIFO_DATA 写：**与 AXI 握手同拍**入队（组合 wr_en）。满时 awready
 *     拉低反压；因为反压与入队用的是同一个 fifo_full，握手成立即保证入队，
 *     结构上不可能丢字（详见文件中"指令 FIFO 入队"一节）。
 * ========================================================================= */
module blt_regs_axi_lite #(
    parameter ADDR_W = 12
)(
    input  wire               clk,
    input  wire               rst_n,

    /* ---- AXI-Lite 从机（CPU 配置口） ---- */
    input  wire [ADDR_W-1:0]  s_axil_awaddr,
    input  wire               s_axil_awvalid,
    output wire               s_axil_awready,
    input  wire [31:0]        s_axil_wdata,
    input  wire [3:0]         s_axil_wstrb,
    input  wire               s_axil_wvalid,
    output wire               s_axil_wready,
    output wire               s_axil_bvalid,
    output wire [1:0]         s_axil_bresp,
    input  wire               s_axil_bready,
    input  wire [ADDR_W-1:0]  s_axil_araddr,
    input  wire               s_axil_arvalid,
    output wire               s_axil_arready,
    output wire [31:0]        s_axil_rdata,
    output wire [1:0]         s_axil_rresp,
    output wire               s_axil_rvalid,
    input  wire               s_axil_rready,

    /* ---- 引擎侧接口 ---- */
    output reg                ctrl_go,        // GO / run_en（自动消费使能）
    output reg                soft_rst,       // SOFT_RST 1 拍脉冲
    output reg                irq_en,
    input  wire               eng_busy,
    input  wire               eng_done,
    input  wire               eng_err,
    input  wire               fifo_empty,     // 字空
    input  wire               fifo_full,      // 字满（2048）
    input  wire [8:0]         fifo_cmd_count, // 完整指令条数
    /* 扫描输出健康度（只读，来自 fb_scanout）：欠载行数 / 看门狗中止次数 */
    input  wire [15:0]        scan_underrun,
    input  wire [15:0]        scan_abort,
    /* ★ 显示缓冲翻转（FLIP）：请求 / 状态（都接 fb_scanout，见 blt_top → ddr3_example_top） */
    output reg  [1:0]         fb_sel,         // 0x24 W：请求显示哪个缓冲（0/1/2）
    input  wire [1:0]         fb_cur_sel,     // 0x28 R [1:0]   ：已生效的显示缓冲
    input  wire [15:0]        fb_frame_cnt,   // 0x28 R [31:16]：扫描输出场计数
    /* ★v2.7 帧边界脉冲（来自 fb_scanout，core 域，每场 1 拍）→ IRQ_STATUS[1] */
    input  wire               frame_pulse,
    /* fifo_wr_en / fifo_wr_data 是**组合**输出：与硬件握手同拍生效。
     * 详见下面"指令 FIFO 入队（与握手同拍）"一节 —— 这是"满时绝不丢字"的
     * 结构性保证，而不是靠"握手那拍的 full 恰好等于入队那拍的 full"。 */
    output wire               fifo_wr_en,     // 与握手同拍：本拍把这个字交给 FIFO
    output wire [31:0]        fifo_wr_data,
    input  wire [31:0]        dbg_cur,        // 当前指令 word0
    input  wire [31:0]        perf,
    output wire               irq_done,
    /* ---- ★v2.7 并发清屏引擎（rtl/clr_engine.v）---- */
    output reg  [31:0]        clr_addr,       // 0x2C
    output reg  [31:0]        clr_stride,     // 0x30
    output reg  [15:0]        clr_w,          // 0x34[15:0]
    output reg  [15:0]        clr_h,          // 0x34[31:16]
    output reg  [15:0]        clr_color,      // 0x38
    output reg  [1:0]         clr_sel,        // 0x3C[3:2]
    output reg                clr_go,         // 0x3C[0]：1 拍脉冲
    output reg                clr_err_clr,    // 0x3C[4]：1 拍脉冲
    input  wire               clr_busy,       // → 0x40[0]
    input  wire               clr_err,        // → 0x40[6]
    input  wire [3:0]         clr_clean,      // → 0x40[5:2]
    input  wire [15:0]        clr_burst,      // → 0x40[31:16]
    input  wire [31:0]        clr_cyc,        // → 0x48
    output reg  [1:0]         draw_sel,       // 0x44：BitBlt 引擎正在画的缓冲
    output reg                draw_wr,        // 0x44 被写（1 拍脉冲，给 clr_engine 清 clean 位）

    /* ---- ★v2.11 显示列表（S2）：配置输出 → dl_fetch ---- */
    output reg  [31:0]        dl_base0,       // 0x4C（只保留 [31:4]）
    output reg  [31:0]        dl_base1,       // 0x50
    output reg  [15:0]        dl_count,       // 0x54
    output reg                dl_buf_sel,     // 0x58 bit2
    output reg                dl_irq_en,      // 0x58 bit3
    output reg                dl_auto_go,     // 0x58 bit4（复位 1）
    output reg                dl_strict,      // 0x58 bit5（复位 1）
    output reg                dl_go_pulse,    // 0x58 bit0：1 拍脉冲（BUSY 时忽略）
    output reg                dl_abort_pulse, // 0x58 bit1：1 拍脉冲
    output reg  [31:0]        dl_geom_base,   // 0x68
    output reg  [15:0]        dl_geom_max,    // 0x6C
    output reg  [31:0]        dl_dst_base,    // 0x70
    output reg  [3:0]         dl_cfg_chunk,   // 0x74[7:4]（复位 8）
    output reg  [3:0]         dl_cfg_wm,      // 0x74[11:8]（复位 4）
    output reg                dl_cfg_prefetch,// 0x74 bit0（复位 1）
    output reg                dl_cfg_gec,     // 0x74 bit1（复位 1）
    output reg  [15:0]        dl_timeout,     // 0x78（复位 4096）
    output reg  [15:0]        dl_dst_stride,  // 0x84[15:0]
    output reg  [15:0]        dl_fb_w,        // 0x88[15:0]
    output reg  [15:0]        dl_fb_h,        // 0x88[31:16]
    output reg  [31:0]        dl_err_clr_mask,// 0x60 W1C 掩码（1 拍内有效）
    output reg                dl_err_clr_pulse,
    output reg                dl_list_rewr_pulse, // 写 0x4C/0x50 ⇒ 清 DL_STATUS.DONE
    output reg                dl_base_align_err,  // 写 0x4C/0x50 未对齐（1 拍）
    /* ---- ★v2.11 DFU → 寄存器组：状态回读 ---- */
    input  wire               dl_busy,        // 0x5C bit0
    input  wire               dl_done,        // 0x5C bit1
    input  wire               dl_err,         // 0x5C bit2
    input  wire               dl_aborted,     // 0x5C bit3
    input  wire               dl_stall,       // 0x5C bit4
    input  wire [15:0]        dl_consumed,    // 0x5C[31:16]
    input  wire [1:0]         dl_active_buf,  // 0x5C[9:8]
    input  wire [31:0]        dl_err_word,    // 0x60 完整读回值
    input  wire [31:0]        dl_fault_addr,  // 0x64
    input  wire [31:0]        dl_perf,        // 0x7C
    /* ---- ★v2.11 DFU → cmd_fifo 写口请求（仲裁在本模块内） ---- */
    input  wire               dl_cmd_req,
    input  wire [31:0]        dl_cmd_data,
    input  wire               dl_cmd_last,    // 8 字命令的第 8 个 ⇒ 写完释放端口
    output wire               dl_cmd_gnt,     // 本拍受理（写进 cmd_fifo）

    /* ---- ★S5（v3.2）属性侧口（0x8C）：FIFO 在本模块内，引擎侧只看这三个口 ----
     * FIFO 是本模块的私有资源（写口是 AXI 握手、读口是引擎的 1 拍脉冲），
     * 这样 blt_top 不必再传 full/push 两根线，tb_regs_axi_lite 那种"直接例化本模块"
     * 的测试台把 attr_pop 悬空（z）也安全：下面所有判据都写成 `if (attr_pop && ...)`，
     * Verilog 的 `if (x/z)` 取假分支 ⇒ 悬空 = 不弹。 */
    output wire               attr_empty,     // 1 = 空（引擎据此用默认属性字）
    output wire [31:0]        attr_dout,      // 队头（FWFT：!empty 即有效）
    input  wire               attr_pop,       // 引擎弹出（1 拍脉冲）
    /* ---- ★S5 scissor（0x90~0xA0） ---- */
    output reg  [15:0]        clip_x0,
    output reg  [15:0]        clip_x1,
    output reg  [15:0]        clip_y0,
    output reg  [15:0]        clip_y1,
    output reg                clip_en,
    /* ---- ★S5 扫描输出颜色 LUT（0xA4~0xB0 → fb_scanout） ---- */
    output reg                lut_wr,         // 写脉冲（1 拍）
    output reg  [1:0]         lut_ch,         // 0xA4[9:8]
    output reg  [7:0]         lut_idx,        // 0xA4[7:0]
    output reg  [7:0]         lut_data,       // 0xA8[7:0]
    output reg                lut_en,         // 0xAC bit0（请求，帧边界生效）
    output reg                lut_bank_req,   // 0xAC bit1（请求，帧边界生效）
    input  wire               lut_bank_act    // 0xB0 bit0：已生效 bank（来自 fb_scanout）
);
    /* ================ ★S5 属性 FIFO（ATTR_PORT 0x8C → 引擎，深 16，FWFT） ================
     * 契约（与 cmd_fifo 同一口径）：写口是**组合**的，wr_hs 成立 ⟺ 本拍 attr_full=0
     * （因为 awready/wready 都把"目标是 0x8C 且 attr_full"挡在外面）⟹ 受理即入队，
     * 不存在"握手了却没进去"的静默丢失窗口。
     * 读口是 FWFT（`attr_dout = mem[rp]`，!empty 即有效）：引擎只需在**每条命令起始**
     * 弹一次，且弹完到下次弹至少隔着 8 个命令字的取出（≈16 拍）⇒ 不存在
     * sync_fifo 那种"弹字后输出寄存器空窗被误判成空"的问题 —— 属性与命令的配对
     * 是**严格按序**的，任何一次误判都会让后续属性整体错位，所以这里刻意不用
     * "同步读 + 假空窗口"的写法。
     * 深度 16（规格要求 ≥8）：最坏也就是软件连续写 16 条属性才需要等引擎消费。
     * （存储/指针的声明必须排在下面的 ready 判据之前 —— 那两条反压判据用 attr_full。） */
`ifdef ATTR_PORT_OFF
    /* A/B 逃生门：属性侧口整体旁路（写被丢弃、永远"空" ⇒ 引擎恒用默认字） */
    wire       attr_full  = 1'b0;
    assign     attr_empty = 1'b1;
    assign     attr_dout  = 32'd0;
    wire [4:0] attr_cnt   = 5'd0;    // 只为 0x8C 读回（恒 0）
`else
    reg [31:0] attr_mem [0:15];
    reg [3:0]  attr_wp, attr_rp;
    reg [4:0]  attr_cnt;
    wire       attr_full  = (attr_cnt == 5'd16);
    assign     attr_empty = (attr_cnt == 5'd0);
    assign     attr_dout  = attr_mem[attr_rp];
`endif
    /* 属性字入队：与 AXI 握手**同拍**（组合），地址 = 0x8C。
     * ★ 不看 WSTRB（与 0x08 CMD_FIFO_DATA 完全同口径：整字入队）—— 组合路径上
     *   拿不到"本拍握手用的 strobe"（W 先到的情形 strobe 还在寄存里）。
     * 赋值放在 wr_hs 定义之后（声明在此、使用在那）。 */
    wire attr_push;

    /* ================ 写通道 FSM ================
     * 支持 AW 先到 / W 先到 / 同拍到；无 outstanding，响应按序回 B。
     */
    localparam W_IDLE = 2'd0;
    localparam W_AWON = 2'd1;   // 已收 AW，等 W
    localparam W_WON  = 2'd2;   // 已收 W，等 AW
    localparam W_RESP = 2'd3;   // 回 B

    reg [1:0]         wst;
    reg [ADDR_W-1:0]  wa;
    reg [31:0]        wd;
    reg [3:0]         ws;
    reg               apply;    // 下一拍执行写落地

    wire [6:0] wa_idx = wa[8:2];
    wire        is_ctrl = (wa_idx == 7'h00);    // 0x00
    wire        is_fifo = (wa_idx == 7'h02);    // 0x08
    wire        is_w1c  = (wa_idx == 7'h04);    // 0x10
    wire        is_irqen= (wa_idx == 7'h05);    // 0x14
    wire        is_fbsel= (wa_idx == 7'h09);    // 0x24
    /* ★v2.7 清屏引擎寄存器（0x2C~0x48，旧地址一个都没动） */
    wire        is_clradr = (wa_idx == 7'h0B);  // 0x2C
    wire        is_clrstr = (wa_idx == 7'h0C);  // 0x30
    wire        is_clrwh  = (wa_idx == 7'h0D);  // 0x34
    wire        is_clrcol = (wa_idx == 7'h0E);  // 0x38
    wire        is_clrctl = (wa_idx == 7'h0F);  // 0x3C
    wire        is_drawsel= (wa_idx == 7'h11);  // 0x44
    /* ★v2.11 显示列表寄存器（0x4C~0x88，旧地址一个都没动） */
    wire        is_dlb0   = (wa_idx == 7'h13);  // 0x4C
    wire        is_dlb1   = (wa_idx == 7'h14);  // 0x50
    wire        is_dlcnt  = (wa_idx == 7'h15);  // 0x54
    wire        is_dlctl  = (wa_idx == 7'h16);  // 0x58
    wire        is_dlerr  = (wa_idx == 7'h18);  // 0x60
    wire        is_dlgb   = (wa_idx == 7'h1A);  // 0x68
    wire        is_dlgm   = (wa_idx == 7'h1B);  // 0x6C
    wire        is_dldst  = (wa_idx == 7'h1C);  // 0x70
    wire        is_dlcfg  = (wa_idx == 7'h1D);  // 0x74
    wire        is_dltmo  = (wa_idx == 7'h1E);  // 0x78
    wire        is_dlstr  = (wa_idx == 7'h21);  // 0x84
    wire        is_dlfwh  = (wa_idx == 7'h22);  // 0x88
    /* ★S5（v3.2）属性侧口 / scissor / 扫描输出 LUT（0x8C~0xB0，旧地址一个都没动） */
    wire        is_attr   = (wa_idx == 7'h23);  // 0x8C ATTR_PORT（写 = 压属性 FIFO）
    wire        is_clpx0  = (wa_idx == 7'h24);  // 0x90
    wire        is_clpx1  = (wa_idx == 7'h25);  // 0x94
    wire        is_clpy0  = (wa_idx == 7'h26);  // 0x98
    wire        is_clpy1  = (wa_idx == 7'h27);  // 0x9C
    wire        is_clpctl = (wa_idx == 7'h28);  // 0xA0
    wire        is_lutadr = (wa_idx == 7'h29);  // 0xA4
    wire        is_lutdat = (wa_idx == 7'h2A);  // 0xA8
    wire        is_lutctl = (wa_idx == 7'h2B);  // 0xAC

    /* ================ ★v2.11 cmd_fifo 写口仲裁（CPU ↔ DFU） ================
     * 规则（整条命令粒度，设计文档 §6 "与 cmd_fifo 的接口"）：
     *   · DFU 在 S_PUSH 拉高 dl_cmd_req，一直举到第 8 个字的 gnt（dl_cmd_last）；
     *   · dl_port_busy = DFU 举着请求 || DFU 还持有 || CPU 正在写一条命令没写完；
     *   · dl_port_busy 期间，目标为 0x08 的 awready/wready 一律压低 —— 这挡的是
     *     **AXI 握手**，所以不存在"受理了却没入队"的静默丢弃窗口；
     *   · dl_gnt 与 cpu_en 互斥（cpu_en 里带了 !dl_port_busy），且两者都只看
     *     同一个 fifo_full、同一拍求值 ⟹ 受理即入队（与簇 3 的修法同一口径）。 */
    reg        dl_owner;
    reg [2:0]  cpu_word_cnt;      // CPU 当前这条命令已入队的字数（0..7）
    /* 挡 CPU 握手的只有 DFU（端口归属 / 正在推进）；CPU 自己的字数计数只用来
     * 让 DFU 让路，绝不去挡 CPU 本身（否则一条命令写到第 2 个字就会被自己挡住）。 */
    wire       dl_port_busy = dl_owner || dl_cmd_req;

    // AW：仅当还能接收时拉高；目标是 CMD_FIFO 且（字满 或 DFU 占着写口）→ 反压
    /* ★S5：目标是 ATTR_PORT 且属性 FIFO 满 → 同样反压（**与入队同拍求值**，
     * 所以"握手成立 ⇒ 必入队"，不会静默丢属性字）。 */
    assign s_axil_awready =
        ((wst == W_IDLE) || (wst == W_WON)) &&
        !((s_axil_awaddr[8:2] == 7'h02) && (fifo_full || dl_port_busy)) &&
        !((s_axil_awaddr[8:2] == 7'h23) && attr_full);

    // W：状态允许；已知道目标是 FIFO 且（字满 或 DFU 占着写口）→ 反压
    assign s_axil_wready =
        ((wst == W_IDLE) || (wst == W_AWON)) &&
        !((wst == W_AWON) && is_fifo && (fifo_full || dl_port_busy)) &&
        !((wst == W_AWON) && is_attr && attr_full);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wst   <= W_IDLE;
            wa    <= {ADDR_W{1'b0}};
            wd    <= 32'd0;
            ws    <= 4'h0;
            apply <= 1'b0;
        end else begin
            apply <= 1'b0;
            case (wst)
                W_IDLE: begin
                    if (s_axil_awvalid && s_axil_awready &&
                        s_axil_wvalid && s_axil_wready) begin          // 同拍
                        wa <= s_axil_awaddr;  wd <= s_axil_wdata; ws <= s_axil_wstrb;
                        apply <= 1'b1;
                        wst   <= W_RESP;
                    end else if (s_axil_awvalid && s_axil_awready) begin
                        wa  <= s_axil_awaddr;
                        wst <= W_AWON;
                    end else if (s_axil_wvalid && s_axil_wready) begin
                        wd  <= s_axil_wdata;  ws <= s_axil_wstrb;
                        wst <= W_WON;
                    end
                end
                W_AWON: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        wd    <= s_axil_wdata;  ws <= s_axil_wstrb;
                        apply <= 1'b1;
                        wst   <= W_RESP;
                    end
                end
                W_WON: begin
                    if (s_axil_awvalid && s_axil_awready) begin
                        wa    <= s_axil_awaddr;
                        apply <= 1'b1;
                        wst   <= W_RESP;
                    end
                end
                W_RESP: begin
                    if (s_axil_bvalid && s_axil_bready)
                        wst <= W_IDLE;
                end
                default: wst <= W_IDLE;
            endcase
        end
    end

    assign s_axil_bvalid = (wst == W_RESP);
    assign s_axil_bresp  = 2'b00;      // OKAY（满时已反压，不可能丢）

    /* ================ 指令 FIFO 入队（与握手同拍） ================
     * 契约：cmd_fifo 的写口是 `do_wr = wr_en && !full` —— 只有非满时 wr_en 才算数。
     * 原实现把入队**寄存化**（握手 → apply → 再一拍才发 wr_en），于是：
     *   - 反压用的是"握手那拍"的 fifo_full；
     *   - 真正入队是"握手 + 2 拍"，那时的 fifo_full 可能已经变 1
     *     （前一个被受理的字刚刚落地把 FIFO 填满）→ 这个字被静默丢弃，
     *     而 CPU 照样收到 B=OKAY，无法察觉（实测：满边界上每轮丢 1 字）。
     * 现在 wr_en/wr_data 是**组合**的：wr_hs 成立就意味着"本拍 full=0"
     * （因为三种状态的 ready 都把 `目标是 FIFO && fifo_full` 挡在外面），
     * 与 FIFO 内部 `!full` 是同一个信号、同一拍求值 ⟹ do_wr=1 ⟹ 必入队。
     * 这是结构性保证，与 master 快慢、AW/W 到达顺序都无关。
     * AXI-Lite 语义上也安全：B 仍在 W_RESP（握手后 1 拍）才拉高，晚于入队，
     * 因此"收到 B"必然意味着数据已经在 FIFO 里。 */
    wire wr_hs = ((wst == W_IDLE) && s_axil_awvalid && s_axil_awready &&
                                        s_axil_wvalid  && s_axil_wready ) ||
                 ((wst == W_AWON) && s_axil_wvalid  && s_axil_wready ) ||
                 ((wst == W_WON ) && s_axil_awvalid && s_axil_awready);
    wire [ADDR_W-1:0] wr_hs_addr = (wst == W_AWON) ? wa : s_axil_awaddr;
    wire [31:0]       wr_hs_data = (wst == W_WON ) ? wd : s_axil_wdata;

    /* ---- ★v2.11 写口受理（见上面的仲裁块） ----
     * cpu_en：CPU 本拍真的在给 0x08 入队（握手成立，且握手时 dl_port_busy=0）。
     * dl_gnt ：DFU 本拍受理（有请求、FIFO 没满、CPU 本拍没在入队、且（已持有端口
     *          或 CPU 不在一条命令中间））。FIFO 满时 dl_gnt=0 而 dl_owner 保持 1
     *          ⇒ DFU 停住等、CPU 继续被挡（端口不会被抢走），FIFO 一空就接着写。 */
    wire cpu_en = wr_hs && (wr_hs_addr[8:2] == 7'h02);
    wire dl_gnt = dl_cmd_req && !fifo_full && !cpu_en &&
                  (dl_owner || (cpu_word_cnt == 3'd0));

    /* ★v2.11：写口在 CPU 与 DFU 之间做 mux（两者互斥，见上面的仲裁块） */
    assign fifo_wr_en   = dl_gnt | cpu_en;
    assign fifo_wr_data = dl_gnt ? dl_cmd_data : wr_hs_data;
    assign dl_cmd_gnt   = dl_gnt;

    /* 端口归属与 CPU 命令字数计数（整条命令粒度的互斥状态） */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dl_owner     <= 1'b0;
            cpu_word_cnt <= 3'd0;
        end else begin
            if (dl_gnt && dl_cmd_last) dl_owner <= 1'b0;   // 第 8 个字写完 ⇒ 释放
            else if (dl_gnt)           dl_owner <= 1'b1;
            if (cpu_en)
                cpu_word_cnt <= (cpu_word_cnt == 3'd7) ? 3'd0 : cpu_word_cnt + 3'd1;
        end
    end

    /* ================ ★S5 属性 FIFO 的存储与指针 ================ */
    assign attr_push = wr_hs && (wr_hs_addr[8:2] == 7'h23);
    /* 注：attr_pop 由引擎给（1 拍脉冲）。直接例化本模块的老 TB（tb_regs_axi_lite /
     * tb_fifo_full）必须显式把它接 0 —— 悬空是 z，z 只要参与判据就会被 iverilog
     * 传播成 x（既有约定：新增端口一律在 TB 里钉住，而不是靠 RTL 猜悬空）。 */

`ifndef ATTR_PORT_OFF
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            attr_wp  <= 4'd0;
            attr_rp  <= 4'd0;
            attr_cnt <= 5'd0;
        end else if (soft_rst) begin
            /* 软复位清空属性 FIFO：复位后"空 FIFO ⇒ 默认属性"必须成立，
             * 否则一条陈旧的属性会错配给软复位后的第一条命令。 */
            attr_wp  <= 4'd0;
            attr_rp  <= 4'd0;
            attr_cnt <= 5'd0;
        end else begin
            if (attr_push && !attr_full && attr_pop && !attr_empty) begin
                attr_mem[attr_wp] <= wr_hs_data;          // 同拍推 + 弹：计数不变
                attr_wp <= attr_wp + 4'd1;
                attr_rp <= attr_rp + 4'd1;
            end else if (attr_push && !attr_full) begin
                attr_mem[attr_wp] <= wr_hs_data;
                attr_wp  <= attr_wp + 4'd1;
                attr_cnt <= attr_cnt + 5'd1;
            end else if (attr_pop && !attr_empty) begin
                attr_rp  <= attr_rp + 4'd1;
                attr_cnt <= attr_cnt - 5'd1;
            end
        end
    end
`endif

    /* ================ 寄存器落地 ================ */
    reg [2:0] irq_status_r;            // [0]=DONE [1]=FRAME [2]=DL_DONE，只在本文件一个 always 中驱动
    reg       irq_en_f;                // ★v2.7：FRAME 使能（0x14 bit1）；端口 irq_en 仍是 DONE 使能

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_go      <= 1'b0;
            irq_en       <= 1'b0;
            irq_en_f     <= 1'b0;
            soft_rst     <= 1'b0;
            fb_sel       <= 2'b00;                    // 复位默认 = 显示 FB_BASE（= 改动前行为）
            clr_addr     <= 32'd0;
            clr_stride   <= 32'd0;
            clr_w        <= 16'd0;
            clr_h        <= 16'd0;
            clr_color    <= 16'd0;
            clr_sel      <= 2'd0;
            clr_go       <= 1'b0;
            clr_err_clr  <= 1'b0;
            draw_sel     <= 2'd0;
            draw_wr      <= 1'b0;
            /* ★v2.11 显示列表（复位值按设计文档 §4：除注明的默认值外全 0） */
            dl_base0     <= 32'd0;
            dl_base1     <= 32'd0;
            dl_count     <= 16'd0;
            dl_buf_sel   <= 1'b0;
            dl_irq_en    <= 1'b0;
            dl_auto_go   <= 1'b1;                     // 默认 1
            dl_strict    <= 1'b1;                     // 默认 1
            dl_go_pulse  <= 1'b0;
            dl_abort_pulse <= 1'b0;
            dl_geom_base <= 32'd0;
            dl_geom_max  <= 16'd0;
            dl_dst_base  <= 32'd0;
            dl_cfg_chunk <= 4'd8;                     // 默认 8 条 = 128B
            dl_cfg_wm    <= 4'd4;                     // 默认水位 4
            dl_cfg_prefetch <= 1'b1;
            dl_cfg_gec   <= 1'b1;
            dl_timeout   <= 16'd4096;                 // 默认 4096 拍
            dl_dst_stride<= 16'd0;
            dl_fb_w      <= 16'd0;
            dl_fb_h      <= 16'd0;
            dl_err_clr_mask  <= 32'd0;
            dl_err_clr_pulse <= 1'b0;
            dl_list_rewr_pulse <= 1'b0;
            dl_base_align_err  <= 1'b0;
            /* ★S5：scissor 与 LUT 全部复位为"不生效"⇒ 与改动前逐位相同 */
            clip_x0      <= 16'd0;
            clip_x1      <= 16'd0;
            clip_y0      <= 16'd0;
            clip_y1      <= 16'd0;
            clip_en      <= 1'b0;
            lut_wr       <= 1'b0;
            lut_ch       <= 2'd0;
            lut_idx      <= 8'd0;
            lut_data     <= 8'd0;
            lut_en       <= 1'b0;
            lut_bank_req <= 1'b0;
        end else begin
            soft_rst   <= 1'b0;                       // 默认无脉冲
            clr_go     <= 1'b0;
            clr_err_clr<= 1'b0;
            draw_wr    <= 1'b0;
            dl_go_pulse      <= 1'b0;
            dl_abort_pulse   <= 1'b0;
            dl_err_clr_pulse <= 1'b0;
            dl_list_rewr_pulse <= 1'b0;
            dl_base_align_err  <= 1'b0;
            lut_wr           <= 1'b0;                 // ★S5：LUT 写脉冲只拉 1 拍
            if (apply) begin
                if (is_ctrl) begin
                    if (ws[0]) begin
                        ctrl_go  <= wd[0];            // GO
                        irq_en   <= wd[1];            // CTRL bit1 = IRQ_EN（只动 DONE 那一位）
                        if (wd[2]) soft_rst <= 1'b1;  // SOFT_RST 1 拍脉冲
                    end
                end else if (is_irqen) begin
                    /* ★v2.7：0x14 bit0/bit1 = DONE/FRAME 两路使能（各写各的，互不覆盖）
                     * ★v2.11：bit2 = DL_DONE 使能（同上，不影响旧两位） */
                    if (ws[0]) begin irq_en <= wd[0]; irq_en_f <= wd[1]; dl_irq_en <= wd[2]; end
                end else if (is_fbsel) begin
                    /* ★ 0x24 FB_SEL：只记"请求"，真正的生效点在 fb_scanout 的帧边界。
                     *   这里同步写入（core 域），与 SOFR_RST 等其它寄存器同一条落地路径。
                     *   v2.7 起是 2 bit（0/1/2 三块；3 保留，扫描输出会回落到 FB0）。 */
                    if (ws[0]) fb_sel <= wd[1:0];
                end else if (is_clradr) begin
                    if (ws[0]) clr_addr <= wd;
                end else if (is_clrstr) begin
                    if (ws[0]) clr_stride <= wd;
                end else if (is_clrwh) begin
                    if (ws[0]) begin clr_w <= wd[15:0]; clr_h <= wd[31:16]; end
                end else if (is_clrcol) begin
                    if (ws[0]) clr_color <= wd[15:0];
                end else if (is_clrctl) begin
                    if (ws[0]) begin
                        clr_sel     <= wd[3:2];       // 目标缓冲号
                        if (wd[0]) clr_go      <= 1'b1;   // GO：1 拍脉冲
                        if (wd[4]) clr_err_clr <= 1'b1;   // ERR_CLR：1 拍脉冲
                    end
                end else if (is_drawsel) begin
                    /* ★v2.7 DRAW_SEL：软件每趟开画时写一次。写它就代表"引擎正在画这块"
                     *   ⇒ 该缓冲的 clean 位立刻清零（画过就不再是"干净背景"）。 */
                    if (ws[0]) begin draw_sel <= wd[1:0]; draw_wr <= 1'b1; end
                /* ---------------- ★v2.11 显示列表 ----------------
                 * 语义 1（设计文档 §4）：DL_BASE0/1、DL_COUNT、DL_GEOM_*、DL_DST_*、
                 * DL_CFG、DL_TIMEOUT 只在 BUSY=0 时被 DFU 采样；BUSY=1 期间的写入
                 * **被忽略**（读回仍是旧值），软件必须先 ABORT 或等 DONE。 */
                end else if (is_dlb0) begin
                    if (ws[0]) begin
                        dl_list_rewr_pulse <= 1'b1;               // 清 DL_STATUS.DONE
                        if (!dl_busy) begin
                            if (wd[3:0] == 4'd0) dl_base0 <= wd & 32'hFFFF_FFF0;
                            else dl_base_align_err <= 1'b1;       // 忽略 + DESC_RANGE
                        end
                    end
                end else if (is_dlb1) begin
                    if (ws[0]) begin
                        dl_list_rewr_pulse <= 1'b1;
                        if (!dl_busy) begin
                            if (wd[3:0] == 4'd0) dl_base1 <= wd & 32'hFFFF_FFF0;
                            else dl_base_align_err <= 1'b1;
                        end
                    end
                end else if (is_dlcnt) begin
                    if (ws[0] && !dl_busy) dl_count <= wd[15:0];
                end else if (is_dlctl) begin
                    /* GO/ABORT 是 1 拍脉冲，不要用读改写去点它们。
                     * GO 在 BUSY=1 时被忽略（不排队、不报错）；ABORT 任何时候都受理。 */
                    if (ws[0]) begin
                        if (wd[0] && !dl_busy) dl_go_pulse    <= 1'b1;
                        if (wd[1])             dl_abort_pulse <= 1'b1;
                        if (!dl_busy) begin
                            dl_buf_sel <= wd[2];
                            dl_irq_en  <= wd[3];
                            dl_auto_go <= wd[4];
                            dl_strict  <= wd[5];
                        end
                    end
                end else if (is_dlerr) begin
                    /* 0x60 DL_ERR：W1C，写 1 清对应位（DFU 内部锁存） */
                    if (ws[0]) begin
                        dl_err_clr_mask  <= wd;
                        dl_err_clr_pulse <= 1'b1;
                    end
                end else if (is_dlgb) begin
                    if (ws[0] && !dl_busy) dl_geom_base <= wd & 32'hFFFF_FFF0;
                end else if (is_dlgm) begin
                    if (ws[0] && !dl_busy) dl_geom_max <= wd[15:0];
                end else if (is_dldst) begin
                    if (ws[0] && !dl_busy) dl_dst_base <= wd;
                end else if (is_dlcfg) begin
                    if (ws[0] && !dl_busy) begin
                        dl_cfg_prefetch <= wd[0];
                        dl_cfg_gec      <= wd[1];
                        dl_cfg_chunk    <= wd[7:4];
                        dl_cfg_wm       <= wd[11:8];
                    end
                end else if (is_dltmo) begin
                    if (ws[0] && !dl_busy) dl_timeout <= wd[15:0];
                end else if (is_dlstr) begin
                    if (ws[0] && !dl_busy) dl_dst_stride <= wd[15:0];
                end else if (is_dlfwh) begin
                    if (ws[0] && !dl_busy) begin dl_fb_w <= wd[15:0]; dl_fb_h <= wd[31:16]; end
                /* ---------------- ★S5（v3.2）属性侧口 / scissor / LUT ----------------
                 * 这四组都是"随时可写"的普通寄存器（不像 0x4C~0x88 那样被 BUSY 门控）：
                 *   · ATTR_PORT(0x8C) 由上面的组合通道入队，不走这里；
                 *   · scissor 由引擎在**命令起始**锁存 ⇒ 命令中途改不会撕裂正在画的命令；
                 *   · LUT 的 bank/使能由 fb_scanout 在**帧边界**锁存 ⇒ 表写不撕裂画面
                 *     （详见 fb_scanout.v 的 LUT 一节）。 */
                end else if (is_clpx0) begin
                    if (ws[0]) clip_x0 <= wd[15:0];
                end else if (is_clpx1) begin
                    if (ws[0]) clip_x1 <= wd[15:0];
                end else if (is_clpy0) begin
                    if (ws[0]) clip_y0 <= wd[15:0];
                end else if (is_clpy1) begin
                    if (ws[0]) clip_y1 <= wd[15:0];
                end else if (is_clpctl) begin
                    if (ws[0]) clip_en <= wd[0];
                end else if (is_lutadr) begin
                    /* [9:8]=通道（0=R 1=G 2=B；3=保留 ⇒ 该次 LUT_DATA 写被忽略）
                     * 规格书写的是"[8] 通道选择"，但三个通道需要 2 bit ⇒ 落成 [9:8]；
                     * 按 (ch<<8)|idx 编码的软件在 R/G/B 三档上完全对得上（见 §28）。 */
                    if (ws[0]) begin lut_ch <= wd[9:8]; lut_idx <= wd[7:0]; end
                end else if (is_lutdat) begin
                    if (ws[0]) begin lut_data <= wd[7:0]; lut_wr <= 1'b1; end
                end else if (is_lutctl) begin
                    if (ws[0]) begin lut_en <= wd[0]; lut_bank_req <= wd[1]; end
                end
                // is_fifo(0x08) 由上面的组合入队通道处理（与握手同拍）
                // is_w1c(0x10) 由 IRQ 专用 always 处理；其余只读地址写入忽略(OKAY)
            end
        end
    end

    /* ================ IRQ_STATUS ================
     * bit0 DONE ：完成沿（irq 已使能）或 IRQ_EN 使能沿（DONE 已高，晚开补偿）；
     * bit1 FRAME：★v2.7 帧边界脉冲（扫描输出每场 1 拍）且 FRAME 使能 → 置位。
     *             脉冲是 1 拍事件，不存在"晚开补偿"；漏掉一拍就等于漏掉一场，
     *             软件用 W1C + 电平读法处理即可。
     * bit2 DL_DONE：★v2.11 显示列表跑完（DL_STATUS.DONE 上升沿）且使能 → 置位，
     *             与 DONE 同一套"沿 + 使能沿补偿"写法。
     * 清除：W1C（写 1 清 0），逐位独立，且**优先于置位**（保持原行为）。
     */
    reg done_d;
    reg irq_en_d;
    reg dl_done_d, dl_irq_en_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_d      <= 1'b0;
            irq_en_d    <= 1'b0;
            dl_done_d   <= 1'b0;
            dl_irq_en_d <= 1'b0;
        end else begin
            done_d      <= eng_done;
            irq_en_d    <= irq_en;
            dl_done_d   <= dl_done;
            dl_irq_en_d <= dl_irq_en;
        end
    end

    wire irq_set = ( eng_done && !done_d  && irq_en ) ||   // 完成沿
                   ( irq_en   && !irq_en_d && eng_done );  // 使能沿补偿
    wire frq_set = frame_pulse && irq_en_f;                // 帧边界脉冲 + FRAME 使能
    wire dlq_set = ( dl_done && !dl_done_d && dl_irq_en ) ||
                   ( dl_irq_en && !dl_irq_en_d && dl_done );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            irq_status_r <= 3'b000;
        else if (apply && is_w1c && ws[0])
            irq_status_r <= irq_status_r & ~wd[2:0];       // W1C：每位独立清
        else begin
            if (irq_set) irq_status_r[0] <= 1'b1;
            if (frq_set) irq_status_r[1] <= 1'b1;
            if (dlq_set) irq_status_r[2] <= 1'b1;          // ★v2.11 列表结束
        end
    end

    /* 中断线：三路状态位的或（FRAME/DL_DONE 默认不使能 ⇒ 默认行为与只有 DONE 时逐位相同） */
    assign irq_done = irq_status_r[0] | irq_status_r[1] | irq_status_r[2];

    /* ================ 读通道（AR/R） ================ */
    reg               r_rdy;     // 1 = 正在回读
    reg [ADDR_W-1:0]  ra;

    assign s_axil_arready = !r_rdy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_rdy <= 1'b0;
            ra    <= {ADDR_W{1'b0}};
        end else begin
            if (!r_rdy && s_axil_arvalid) begin
                ra    <= s_axil_araddr;
                r_rdy <= 1'b1;
            end else if (s_axil_rvalid && s_axil_rready) begin
                r_rdy <= 1'b0;
            end
        end
    end

    assign s_axil_rvalid = r_rdy;
    assign s_axil_rresp  = 2'b00;

    reg [31:0] rdata_c;
    always @(*) begin
        case (ra[8:2])
            7'h00: rdata_c = {30'd0, irq_en, ctrl_go};                               // CTRL
            7'h01: rdata_c = {28'd0, fifo_empty, eng_err, eng_done, eng_busy};       // STATUS
            7'h03: rdata_c = {23'd0, fifo_cmd_count};                                // CMD_FIFO_COUNT
            7'h04: rdata_c = {29'd0, irq_status_r};                                  // IRQ_STATUS[2:0]
            7'h05: rdata_c = {29'd0, dl_irq_en, irq_en_f, irq_en};                   // IRQ_EN[2:0]
            7'h06: rdata_c = dbg_cur;                                                // DBG_CUR_CMD
            7'h07: rdata_c = perf;                                                   // PERF
            7'h08: rdata_c = {scan_abort, scan_underrun};                            // SCAN_DBG(0x20)
            7'h09: rdata_c = {30'd0, fb_sel};                                        // FB_SEL(0x24) 读回请求
            7'h0A: rdata_c = {fb_frame_cnt, 14'd0, fb_cur_sel};                      // FB_STAT(0x28)
            /* ---- ★v2.7 清屏引擎 ---- */
            7'h0B: rdata_c = clr_addr;                                               // CLR_ADDR(0x2C)
            7'h0C: rdata_c = clr_stride;                                             // CLR_STRIDE(0x30)
            7'h0D: rdata_c = {clr_h, clr_w};                                         // CLR_WH(0x34)
            7'h0E: rdata_c = {16'd0, clr_color};                                     // CLR_COLOR(0x38)
            7'h0F: rdata_c = {27'd0, clr_sel, 2'b00};                                // CLR_CTRL(0x3C) 读回
            7'h10: rdata_c = {clr_burst, 9'd0, clr_err, clr_clean,              // CLR_STAT(0x40)
                              clr_clean[clr_sel], clr_busy};
            7'h11: rdata_c = {30'd0, draw_sel};                                      // DRAW_SEL(0x44)
            7'h12: rdata_c = clr_cyc;                                                // CLR_CYC(0x48)
            /* ---- ★v2.11 显示列表 ---- */
            7'h13: rdata_c = {dl_base0[31:4], 4'd0};                                 // DL_BASE0(0x4C)
            7'h14: rdata_c = {dl_base1[31:4], 4'd0};                                 // DL_BASE1(0x50)
            7'h15: rdata_c = {16'd0, dl_count};                                      // DL_COUNT(0x54)
            7'h16: rdata_c = {26'd0, dl_strict, dl_auto_go, dl_irq_en,               // DL_CTRL(0x58)
                              dl_buf_sel, 2'b00};
            7'h17: rdata_c = {dl_consumed, 6'd0, dl_active_buf, 3'd0,                // DL_STATUS(0x5C)
                              dl_stall, dl_aborted, dl_err, dl_done, dl_busy};
            7'h18: rdata_c = dl_err_word;                                            // DL_ERR(0x60)
            7'h19: rdata_c = dl_fault_addr;                                          // DL_FAULT_ADDR(0x64)
            7'h1A: rdata_c = {dl_geom_base[31:4], 4'd0};                             // DL_GEOM_BASE(0x68)
            7'h1B: rdata_c = {16'd0, dl_geom_max};                                   // DL_GEOM_MAX(0x6C)
            7'h1C: rdata_c = dl_dst_base;                                            // DL_DST_BASE(0x70)
            7'h1D: rdata_c = {16'd0, 4'd0, dl_cfg_wm, dl_cfg_chunk,                  // DL_CFG(0x74)
                              2'd0, dl_cfg_gec, dl_cfg_prefetch};
            7'h1E: rdata_c = {16'd0, dl_timeout};                                    // DL_TIMEOUT(0x78)
            7'h1F: rdata_c = dl_perf;                                                // DL_PERF(0x7C)
            7'h20: rdata_c = 32'h0210_0002;                                          // DL_VERSION(0x80)
            7'h21: rdata_c = {16'd0, dl_dst_stride};                                 // DL_DST_STRIDE(0x84)
            7'h22: rdata_c = {dl_fb_h, dl_fb_w};                                     // DL_FB_WH(0x88)
            /* ---- ★S5（v3.2）属性侧口 / scissor / LUT ----
             * 0x8C 读回 = 属性 FIFO 的**占用深度**（不是数据；数据由引擎按序弹走，
             * 软件想核对就写"读回值"当调试量）。0xB0 读回 = fb_scanout 已生效的 bank。 */
            7'h23: rdata_c = {27'd0, attr_cnt};                                      // ATTR_PORT(0x8C)
            7'h24: rdata_c = {16'd0, clip_x0};                                       // CLIP_X0(0x90)
            7'h25: rdata_c = {16'd0, clip_x1};                                       // CLIP_X1(0x94)
            7'h26: rdata_c = {16'd0, clip_y0};                                       // CLIP_Y0(0x98)
            7'h27: rdata_c = {16'd0, clip_y1};                                       // CLIP_Y1(0x9C)
            7'h28: rdata_c = {31'd0, clip_en};                                       // CLIP_CTRL(0xA0)
            7'h29: rdata_c = {22'd0, lut_ch, lut_idx};                               // LUT_ADDR(0xA4)
            7'h2A: rdata_c = {24'd0, lut_data};                                      // LUT_DATA(0xA8)
            7'h2B: rdata_c = {30'd0, lut_bank_req, lut_en};                          // LUT_CTRL(0xAC)
            7'h2C: rdata_c = {31'd0, lut_bank_act};                                  // LUT_STAT(0xB0)
            default: rdata_c = 32'd0;
        endcase
    end
    assign s_axil_rdata = rdata_c;
endmodule
