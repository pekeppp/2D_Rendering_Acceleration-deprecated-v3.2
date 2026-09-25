/* =========================================================================
 * tb_lut_proto.v — ★S5（v3.2）扫描输出颜色 LUT 的**端到端协议回放**台
 * -------------------------------------------------------------------------
 * 补的缺口：既有验证是"一条链的两个半截"，中间那段**真实连线**从来没被跑过 ——
 *   · tb_scanout_lut.v    直接在 fb_scanout 的 LUT 端口上自己造写脉冲 / bank 请求；
 *   · tb_regs_axi_lite.v  只测寄存器组，0xB0 的 lut_bank_act 被钉死成 0。
 * 本台把 **blt_regs_axi_lite + fb_scanout 按板上的接法连起来**，跑的是真链路：
 *   AXI-Lite 写 0xA4/0xA8/0xAC → 寄存器译码 → lut_wr（1 拍脉冲）
 *   → LUT RAM（core 写口 / pclk 读口）→ 显示像素 vr/vg/vb → 0xB0 回读 bit0
 *
 * 回放的协议就是板级软件 AdDemo.c 里 LUT_BANK_BEGIN ~ LUT_BANK_END 那一段的四步：
 *   ① 读 0xB0 → disp（此刻**显示**的 bank）
 *   ② 0xAC.bit1 = ~disp（写口指向**非显示** bank；bit0 保持已发布的使能值）
 *   ③ 3 通道 × 256 项整张写表（0xA4 = (ch<<8)|idx，写 0xA8 → 1 拍写脉冲）
 *   ④ 0xAC.bit1 = disp（发布：权威语义"显示 = ~bit1" ⇒ 帧边界后显示 = ~disp = 刚写的 bank）
 *   ⑤ 等至少一个帧边界（读 0x28 场计数直到它变，与软件同款的有界等待）
 * 注意 0xAC.bit0（使能）在 RTL 里是**立即**生效的，只有 bit1（bank）走帧边界锁存 ——
 * 这与 AdDemo 的注释一致，本台的期望值就按这个语义写（见 P7 的说明）。
 *
 * 四条断言（逐像素、整场，不是抽样）：
 *   T1 发布 + 跨帧边界之后**显示像素真的变了**（端到端证明寄存器写路径上了屏）；
 *   T2 写表期间（发布之前）**整场每一个 DE 像素都不变** —— 无撕裂；
 *   T3 0xB0.bit0 恒等于"此刻屏幕上那张表所在的 bank"，**由像素判定**（不看软件镜像）；
 *   T4 恒等表（LUT[i]=i）+ 使能 ⇒ 与关闭 LUT **逐位相同**（本工程的兼容性不变量）。
 *
 * ★ 2026-09-16 本台第一次跑就抓到 T4 不成立（真实 RTL/文档不符，不是 TB 问题；证据是两条
 *   **观测流**的逐位比较）：当时 fb_scanout 的 LUT 输出级复制字段**高位**
 *   （{rq5,rq5[4:2]} / {gq6,gq6[5:4]} / {bq5,bq5[4:2]}），而旁路（fb_scanout.v 的 r8/g8/b8）
 *   补的是字段**低位**（px2[13:11] / px2[7:6] / px2[2:0]）⇒ 恒等表 + 使能与关闭 LUT 在
 *   G（以及 R/B 部分码值）上差 1~7 个 LSB，整场 2048 个像素全差。
 *   ★ 修法（已按用户决定落地，改动最小）：把 **LUT 输出级**改成与旁路同口径
 *   （补字段低位），旁路与整条视频通路的现有画面**一位不动**；把整条通路统一改成
 *   "复制高位"（rtl/pixel_path.v:182-190 记过同一处错误）会改变现有画面颜色，
 *   属于单独的上板验收决定，本台不碰。修后 T4 由"结构性等式"保证成立：恒等表时
 *   lut_*_o == r8/g8/b8，量化回 5/6/5 再按同一抽头复制 = 原值。
 *   T4 保持**硬 FAIL**（不弱化成 5/6/5 空间比较）：两级必须在 8bit 上逐位一致。
 *
 * 手法（全部沿用既有 TB，不引入新约定）：
 *   · AXI-Lite 读写任务照抄 rtl/tb/tb_regs_axi_lite.v（驱动方式、复位时序同款）；
 *   · 视频时序 / 行标签伪 DDR / 逐像素观测门控 `ctrl2[2]` 照抄 rtl/tb/tb_scanout_lut.v；
 *   · 源帧每行一个**可辨认标签**（tag = {行号, ~行号}）⇒ 参考流同时按"整场流"和
 *     "tag 索引"两套存，"写表前后同一像素位置"的比对不依赖两次抓帧像素个数相等。
 *
 * 表内容（必须让 bank 能从像素反推）：
 *   mode0 恒等表 LUT[i]=i（= 关 LUT 的老输出，T4 用）
 *   mode1 全 0x00（全黑）   mode2 全 0xFF（全白）   mode3 分通道 R=255-i / G=i>>2 / B=i^0xAA
 *   任何时刻两个 bank 的表内容都不同 ⇒ 整场像素能唯一判出"显示的是哪个 bank 的表"。
 *
 * 编译（仓库根）：
 *   iverilog -g2001 -s tb_lut_proto -o sim_tb_lut_proto.vvp \
 *     rtl/blt_regs_axi_lite.v rtl/cmd_fifo.v \
 *     ARC_2DRA/rtl/video/fb_scanout.v ARC_2DRA/rtl/video/video_timing_1080p.v \
 *     ARC_2DRA/rtl/common/simple_dual_port_ram.v rtl/tb/tb_lut_proto.v
 * ========================================================================= */
`timescale 1ns/1ps
module tb_lut_proto;
    /* ---- 视频参数：与 tb_scanout_lut.v 完全一致（一场 = 96×40 pclk ≈ 26us） ---- */
    localparam FB_W = 12'd32;
    localparam FB_H = 12'd16;
    localparam FB_STRIDE = 32'd64;
    localparam FB_BASE = 32'h0000_1000;
    localparam H_ACTIVE = 12'd64, H_FP = 12'd8, H_SYNC = 12'd8, H_BP = 12'd16;
    localparam V_ACTIVE = 12'd32, V_FP = 12'd2, V_SYNC = 12'd2, V_BP = 12'd4;
    localparam MAXP = 4096;                 // 一场 DE 像素上限（本配置实测 2048）

    reg clk = 1'b0, pclk = 1'b0, rst_n = 1'b0, prst_n = 1'b0;
    always #5.0 clk  = ~clk;         // core 100MHz
    always #3.4 pclk = ~pclk;        // pixel ~147MHz

    /* ================= AXI-Lite 主测口（照抄 tb_regs_axi_lite.v） ================= */
    reg  [11:0] awaddr = 12'd0;
    reg         awvalid = 1'b0;
    wire        awready;
    reg  [31:0] wdata = 32'd0;
    reg  [3:0]  wstrb = 4'h0;
    reg         wvalid = 1'b0;
    wire        wready;
    wire        bvalid;
    wire [1:0]  bresp;
    reg         bready = 1'b1;
    reg  [11:0] araddr = 12'd0;
    reg         arvalid = 1'b0;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready = 1'b1;

    /* ============ 寄存器组 ↔ 扫描输出 之间的**真实连线**（本台的主角） ============
     * 七根 LUT 线：寄存器组输出 → 扫描输出输入；lut_bank_act 反向回到 0xB0。 */
    wire        lut_wr;
    wire [1:0]  lut_ch;
    wire [7:0]  lut_idx, lut_data;
    wire        lut_en, lut_bank_req;
    wire        lut_bank_act;

    /* ================= 扫描输出的观测线（声明必须在例化之前：iverilog 2001 不许先用后声明）
     * 参数 / 接法与 tb_scanout_lut.v 一致 */
    wire [27:0] m_araddr;
    wire [7:0]  m_arlen;
    wire [2:0]  m_arsize;
    wire [1:0]  m_arburst;
    wire [3:0]  m_arid;
    wire        m_arvalid, m_rvalid, m_rlast, m_rready, m_hold;
    reg         m_arready;
    wire [127:0] m_rdata;
    wire [1:0]  m_rresp;
    wire [3:0]  m_rid;

    wire [1:0]  fb_cur_sel;
    wire [15:0] frame_cnt;
    wire        frame_pulse;
    wire        vde, vhs, vvs, frame_tick;
    wire [7:0]  vr, vg, vb;
    wire [11:0] dbg_line;
    wire [15:0] dbg_underrun, dbg_abort;

    /* ---- 引擎 / 清屏 / DFU / 属性侧口：本台不跑它们 ⇒ 输入全部显式钉 0 ----
     * （不接会悬空成 Z/X —— 本工程既有约定，见 tb_regs_axi_lite.v 的 DL 端口注释） */
    reg         eng_busy = 1'b0;
    reg         eng_done = 1'b1;
    reg         eng_err  = 1'b0;
    reg  [31:0] dbg_cur  = 32'h1234_5678;
    reg  [31:0] perf     = 32'h0000_00FF;
    reg         clr_busy_r = 1'b0, clr_err_r = 1'b0;
    reg  [3:0]  clr_clean_r = 4'b0000;
    reg  [15:0] clr_burst_r = 16'd0;
    reg  [31:0] clr_cyc_r   = 32'd0;

    wire        ctrl_go, soft_rst, irq_en, irq_done;
    wire [1:0]  fb_sel_w;
    wire        fifo_wr_en;
    wire [31:0] fifo_wr_data;
    wire        fifo_empty, fifo_full;
    wire [8:0]  fifo_cmd_count;
    wire [31:0] clr_addr_w, clr_stride_w;
    wire [15:0] clr_w_w, clr_h_w, clr_color_w;
    wire [1:0]  clr_sel_w, draw_sel_w;
    wire        clr_go_w, clr_err_clr_w, draw_wr_w;
    wire        attr_empty_w;
    wire [31:0] attr_dout_w;

    blt_regs_axi_lite #(.ADDR_W(12)) u_regs (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb),
        .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bvalid(bvalid), .s_axil_bresp(bresp), .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(rresp),
        .s_axil_rvalid(rvalid), .s_axil_rready(rready),
        .ctrl_go(ctrl_go), .soft_rst(soft_rst), .irq_en(irq_en),
        .eng_busy(eng_busy), .eng_done(eng_done), .eng_err(eng_err),
        .fifo_empty(fifo_empty), .fifo_full(fifo_full), .fifo_cmd_count(fifo_cmd_count),
        .fifo_wr_en(fifo_wr_en), .fifo_wr_data(fifo_wr_data),
        .dbg_cur(dbg_cur), .perf(perf), .irq_done(irq_done),
        /* 扫描输出健康度 + 翻转状态：接真模块（本台不用它们断言，但必须接线） */
        .scan_underrun(dbg_underrun), .scan_abort(dbg_abort),
        .fb_sel(fb_sel_w), .fb_cur_sel(fb_cur_sel), .fb_frame_cnt(frame_cnt),
        .frame_pulse(frame_pulse),
        .clr_addr(clr_addr_w), .clr_stride(clr_stride_w),
        .clr_w(clr_w_w), .clr_h(clr_h_w), .clr_color(clr_color_w),
        .clr_sel(clr_sel_w), .clr_go(clr_go_w), .clr_err_clr(clr_err_clr_w),
        .clr_busy(clr_busy_r), .clr_err(clr_err_r), .clr_clean(clr_clean_r),
        .clr_burst(clr_burst_r), .clr_cyc(clr_cyc_r),
        .draw_sel(draw_sel_w), .draw_wr(draw_wr_w),
        /* 显示列表：本台不跑 DFU ⇒ 输入全钉 0，输出不接 */
        .dl_base0(), .dl_base1(), .dl_count(),
        .dl_buf_sel(), .dl_irq_en(), .dl_auto_go(), .dl_strict(),
        .dl_go_pulse(), .dl_abort_pulse(),
        .dl_geom_base(), .dl_geom_max(), .dl_dst_base(),
        .dl_cfg_chunk(), .dl_cfg_wm(), .dl_cfg_prefetch(), .dl_cfg_gec(),
        .dl_timeout(), .dl_dst_stride(), .dl_fb_w(), .dl_fb_h(),
        .dl_err_clr_mask(), .dl_err_clr_pulse(), .dl_list_rewr_pulse(),
        .dl_base_align_err(),
        .dl_busy(1'b0), .dl_done(1'b0), .dl_err(1'b0), .dl_aborted(1'b0),
        .dl_stall(1'b0), .dl_consumed(16'd0), .dl_active_buf(2'd0),
        .dl_err_word(32'd0), .dl_fault_addr(32'd0), .dl_perf(32'd0),
        .dl_cmd_req(1'b0), .dl_cmd_data(32'd0), .dl_cmd_last(1'b0), .dl_cmd_gnt(),
        .attr_empty(attr_empty_w), .attr_dout(attr_dout_w), .attr_pop(1'b0),
        .clip_x0(), .clip_x1(), .clip_y0(), .clip_y1(), .clip_en(),
        /* ★ 被测链路：下面七根线 = AXI-Lite → LUT RAM → 屏幕 → 0xB0 */
        .lut_wr(lut_wr), .lut_ch(lut_ch), .lut_idx(lut_idx), .lut_data(lut_data),
        .lut_en(lut_en), .lut_bank_req(lut_bank_req), .lut_bank_act(lut_bank_act)
    );

    /* ---- 指令 FIFO：板上有，本台接真的（从不写 0x08 ⇒ 恒空，只为把端口按板上接满） ---- */
    wire fifo_rdack;
    cmd_fifo #(.CMD_DEPTH(256)) u_fifo (
        .clk(clk), .rst_n(rst_n & ~soft_rst),
        .wr_en(fifo_wr_en), .din(fifo_wr_data),
        .rd_en(1'b0), .rd_ack(fifo_rdack), .dout(),
        .full(fifo_full), .empty(fifo_empty),
        .word_count(), .cmd_count(fifo_cmd_count)
    );

    /* ================= 扫描输出例化 ================= */
    fb_scanout #(
        .FB_BASE(FB_BASE), .FB_STRIDE(FB_STRIDE), .FB_W(FB_W), .FB_H(FB_H),
        .WIN_X(12'd0), .WIN_Y(12'd0),
        .H_ACTIVE(H_ACTIVE), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP),
        .V_ACTIVE(V_ACTIVE), .V_FP(V_FP), .V_SYNC(V_SYNC), .V_BP(V_BP),
        .MAX_BURST(8'd16), .SCALE_SH(1)
    ) u_scan (
        .clk(clk), .rst_n(rst_n),
        .fb_sel(fb_sel_w), .fb_cur_sel(fb_cur_sel), .frame_cnt(frame_cnt),
        .frame_pulse(frame_pulse),
        .lut_wr(lut_wr), .lut_ch(lut_ch), .lut_idx(lut_idx), .lut_data(lut_data),
        .lut_en(lut_en), .lut_bank_req(lut_bank_req), .lut_bank_act(lut_bank_act),
        .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arid(m_arid), .m_axi_arvalid(m_arvalid),
        .m_axi_arready(m_arready), .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp),
        .m_axi_rid(m_rid), .m_axi_rlast(m_rlast), .m_axi_rvalid(m_rvalid),
        .m_axi_rready(m_rready), .m_axi_hold(m_hold),
        .pclk(pclk), .prst_n(prst_n),
        .vde(vde), .vhs(vhs), .vvs(vvs), .vr(vr), .vg(vg), .vb(vb),
        .frame_tick(frame_tick), .dbg_line(dbg_line),
        .dbg_underrun(dbg_underrun), .dbg_abort(dbg_abort)
    );

    /* ================= 行为 AXI 读从机：整行 = 该行标签 =================
     * 照抄 tb_scanout_lut.v：每行一个可辨认的 16bit 标签（高字节 = 行号，
     * 低字节 = 行号取反），于是"这一像素来自哪一行"可以从像素本身反推。 */
    reg [15:0] line_tag [0:FB_H-1];
    reg [127:0] cur_beat;
    reg [7:0]  beats_left;
    reg [27:0] cur_addr;
    reg        rvalid_r;
    integer    ki;
    initial begin
        for (ki = 0; ki < FB_H; ki = ki + 1)
            line_tag[ki] = {ki[7:0], (~ki[7:0])};
    end

    function [127:0] beat_of;
        input [27:0] a;
        integer row, b;
        reg [15:0] t;
        begin
            row = ((a - FB_BASE) / FB_STRIDE);
            if (row < 0) row = 0;
            if (row >= FB_H) row = FB_H - 1;
            t = line_tag[row];
            beat_of = 128'd0;
            for (b = 0; b < 8; b = b + 1) beat_of[b*16 +: 16] = t;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_arready <= 1'b1; rvalid_r <= 1'b0; beats_left <= 8'd0;
            cur_addr <= 28'd0; cur_beat <= 128'd0;
        end else begin
            if (m_arvalid && m_arready) begin
                cur_addr   <= m_araddr;
                beats_left <= m_arlen + 8'd1;
                rvalid_r   <= 1'b1;
                cur_beat   <= beat_of(m_araddr);
            end else if (rvalid_r && m_rready) begin
                if (beats_left <= 8'd1) rvalid_r <= 1'b0;
                else begin
                    beats_left <= beats_left - 8'd1;
                    cur_beat   <= beat_of(cur_addr + 28'd16);
                    cur_addr   <= cur_addr + 28'd16;
                end
            end
        end
    end
    assign m_rdata  = cur_beat;
    assign m_rresp  = 2'b00;
    assign m_rid    = 4'h1;
    assign m_rlast  = (beats_left <= 8'd1);
    assign m_rvalid = rvalid_r;

    /* ================= 像素模型（与 RTL 同一套抽头 / 量化规则） ================= */
    function [7:0] xr; input [15:0] p; begin xr = {p[15:11], p[13:11]}; end endfunction
    function [7:0] xg; input [15:0] p; begin xg = {p[10:5],  p[7:6]};   end endfunction
    function [7:0] xb; input [15:0] p; begin xb = {p[4:0],   p[2:0]};   end endfunction
    /* 8bit 表值 → 量化回 5/6/5 → 按**旁路同一抽头**复制回 8bit（= RTL 的输出级）。
     * ★ 抽头必须与 fb_scanout.v 末尾的 r8/g8/b8 一致（补字段低位：r5[2:0]/g6[2:1]/b5[2:0]）
     *   —— 这正是 T4（恒等表 + 使能 == 关闭 LUT）成立的结构性条件；
     *   若整条视频通路将来统一改成"复制高位"，这三个函数（以及本台的 xr/xg/xb）
     *   要同步改，否则 T4 会误报。 */
    function [7:0] lutq_r; input [7:0] t; reg [4:0] f; begin f = t[7:3]; lutq_r = {f, f[2:0]}; end endfunction
    function [7:0] lutq_g; input [7:0] t; reg [5:0] f; begin f = t[7:2]; lutq_g = {f, f[2:1]}; end endfunction
    function [7:0] lutq_b; input [7:0] t; reg [4:0] f; begin f = t[7:3]; lutq_b = {f, f[2:0]}; end endfunction

    /* ---- 模式 → 期望输出 ----
     * mode0 = LUT **关闭**（旁路）= fb_scanout 的老输出抽头；
     * mode4 = 恒等表 + **使能** = 老输出再过一遍 LUT 输出级（量化回 5/6/5 再按同一抽头复制）。
     * ★ 修好输出级抽头之后 mode0 与 mode4 **必须逐位相等**（T4 的结构性等式），
     *   本台两条都查：mode4 查"表内容真的走通了 LUT"，mode0/T4 查"与旁路逐位相同"。 */
    function [7:0] mode_r; input integer m; input [15:0] tag;
        begin
            case (m)
                0: mode_r = xr(tag);
                1: mode_r = 8'h00;
                2: mode_r = 8'hFF;
                4: mode_r = lutq_r(xr(tag));
                default: mode_r = 8'h00;
            endcase
        end
    endfunction
    function [7:0] mode_g; input integer m; input [15:0] tag;
        begin
            case (m)
                0: mode_g = xg(tag);
                1: mode_g = 8'h00;
                2: mode_g = 8'hFF;
                4: mode_g = lutq_g(xg(tag));
                default: mode_g = 8'h00;
            endcase
        end
    endfunction
    function [7:0] mode_b; input integer m; input [15:0] tag;
        begin
            case (m)
                0: mode_b = xb(tag);
                1: mode_b = 8'h00;
                2: mode_b = 8'hFF;
                4: mode_b = lutq_b(xb(tag));
                default: mode_b = 8'h00;
            endcase
        end
    endfunction
    function [511:0] mode_name;
        input integer m;
        begin
            case (m)
                0: mode_name = "LUT 关闭（旁路老输出）";
                1: mode_name = "全 0 表（黑）";
                2: mode_name = "全 FF 表（白）";
                3: mode_name = "分通道表 R=255-i,G=i>>2,B=i^AA";
                4: mode_name = "恒等表 + 使能（过 LUT 输出级）";
                default: mode_name = "未知";
            endcase
        end
    endfunction
    /* ---- T1：与"写表前参考场"逐位比较，必须**每一个像素都变了** ---- */

    /* ================= 表内容模型（TB 每写一项就同步记一项） ================= */
    reg [7:0] tbl [0:1][0:2][0:255];
    integer ch, ix, v;

    /* ================= 计数 / 抓帧 / 参考 / 监视 ================= */
    integer errors = 0, nchecks = 0;
    reg [4095:0] dtl;                        // PASS/FAIL 行里的"观测值"拼接缓冲
    reg [31:0]  rv;
    integer     d0, dbank, wbank, nread;
    reg [15:0]  fc0;

    integer     cap_n, cap_frame, cap_bk_chg;
    reg [15:0]  cap_tag [0:MAXP-1];
    reg [7:0]   cap_r [0:MAXP-1], cap_g [0:MAXP-1], cap_b [0:MAXP-1];
    reg         cap_bk  [0:MAXP-1];

    /* ref = 最近一次 commit_ref 的"写表前参考场"；base = P1 的"关闭 LUT 基准场" */
    integer     ref_n, ref_frame;
    reg [15:0]  ref_tag [0:MAXP-1];
    reg [7:0]   ref_r [0:MAXP-1], ref_g [0:MAXP-1], ref_b [0:MAXP-1];
    integer     base_n, base_frame;
    reg [15:0]  base_tag [0:MAXP-1];
    reg [7:0]   base_r [0:MAXP-1], base_g [0:MAXP-1], base_b [0:MAXP-1];

    reg [7:0]   tkr [0:65535], tkg [0:65535], tkb [0:65535];   // 按 tag 索引的参考值
    reg         tkv [0:65535];                                  // 该 tag 有没有参考值

    reg         watch_on;
    integer     watch_px, watch_bad, watch_miss, watch_frames;

    /* ================= 判定工具 ================= */
    task checkv;
        input [2047:0] name;
        input          ok;
        begin
            nchecks = nchecks + 1;
            if (!ok) begin
                errors = errors + 1;
                $display("FAIL: %0s  [%0s]", name, dtl);
            end else begin
                $display("PASS: %0s  [%0s]", name, dtl);
            end
        end
    endtask

    /* ---- AXI-Lite 写 / 读：照抄 tb_regs_axi_lite.v ---- */
    task axi_write;
        input [11:0] addr;
        input [31:0] data;
        begin
            awaddr = addr; awvalid = 1'b1;
            wdata  = data; wstrb  = 4'hF; wvalid = 1'b1;
            while (!(bvalid && bready)) @(posedge clk);
            #1;
            awvalid = 1'b0; wvalid = 1'b0;
        end
    endtask

    task axi_read;
        input [11:0] addr;
        output [31:0] rd;
        begin
            araddr = addr; arvalid = 1'b1;
            while (!arready) @(posedge clk);
            @(posedge clk); #1;
            arvalid = 1'b0;
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata;
            @(posedge clk); #1;
        end
    endtask

    /* ================= AdDemo 协议（逐字对应 C 里的四个函数） ================= */
    /* 对应 lut_write_bank(d) = ~d：写口 bank 永远是显示 bank 的反相 */
    function integer lut_write_bank;
        input integer d;
        begin lut_write_bank = (~d) & 1; end
    endfunction
    /* 对应 lut_pub_bank(wr)（g_lut_inv=1 的权威语义）= ~wr：
     * 显示 = ~bit1 ⇒ 想让下一帧显示 wr，就得写 bit1 = ~wr */
    function integer lut_pub_bank;
        input integer wr;
        begin lut_pub_bank = (~wr) & 1; end
    endfunction

    /* 写"当前写入 bank"（= 0xAC bit1）的一张表：地址/数据完全走 AXI-Lite，
     * 与软件 lut_fill_bank 的内层循环逐字对应。bank 参数只做协议自检。 */
    task wr_tbl;
        input integer mode;
        input integer bank;
        begin
            if (lut_bank_req !== bank[0]) begin
                errors = errors + 1;
                $display("FAIL: 写表协议违规：0xAC.bit1 = %0d，但 TB 要写 bank%0d（协议要求写非显示 bank）",
                         lut_bank_req, bank);
            end
            for (ch = 0; ch < 3; ch = ch + 1) begin
                for (ix = 0; ix < 256; ix = ix + 1) begin
                    case (mode)
                        0: v = ix;                       // 恒等
                        1: v = 0;                        // 全 0（黑）
                        2: v = 255;                      // 全 FF（白）
                        3: v = (ch == 0) ? (255 - ix) :
                               (ch == 1) ? (ix >> 2) : (ix ^ 8'hAA);
                        default: v = 0;
                    endcase
                    tbl[bank][ch][ix] = v[7:0];
                    axi_write(12'hA4, {22'd0, ch[1:0], ix[7:0]});   // LUT_ADDR = (ch<<8)|idx
                    axi_write(12'hA8, {24'd0, v[7:0]});             // LUT_DATA → 1 拍写脉冲
                end
            end
        end
    endtask

    /* 对应 lut_fill_bank(bank, mode, en)：先写 0xAC（选写入 bank + 使能），再整张写表 */
    task fill_bank;
        input integer bank;
        input integer mode;
        input integer en;
        begin
            axi_write(12'hAC, (en ? 32'd1 : 32'd0) | (bank[0] ? 32'd2 : 32'd0));
            wr_tbl(mode, bank);
        end
    endtask

    /* 对应 lut_publish()：④ 写 0xAC = (en<<0) | (lut_pub_bank(wr)<<1) */
    task publish;
        input integer wr;
        input integer en;
        begin
            axi_write(12'hAC, (en ? 32'd1 : 32'd0) | (lut_pub_bank(wr) ? 32'd2 : 32'd0));
        end
    endtask

    /* 等至少一个帧边界：与软件同款（读 0x28 的场计数 [31:16] 直到它变）。
     * 有界（≤4000 次读，远大于一场）⇒ 扫描输出没在跑时报 FAIL，不挂死。 */
    task wait_frame_change;
        input [15:0] fc_in;
        reg [31:0] r;
        reg ok;
        begin
            nread = 0; ok = 1'b0; r = 32'd0;
            while ((nread < 4000) && !ok) begin
                axi_read(12'h28, r);
                nread = nread + 1;
                if (r[31:16] !== fc_in) ok = 1'b1;
            end
            if (!ok) begin
                errors = errors + 1;
                $display("FAIL: 等帧边界超时（0x28 场计数一直是 %04h，读了 %0d 次）", fc_in, nread);
            end
        end
    endtask

    task read_fcnt;
        output [15:0] fc_out;
        reg [31:0] r;
        begin axi_read(12'h28, r); fc_out = r[31:16]; end
    endtask

    /* 把 pclk 相位挪到"刚过帧起点"（vcnt 很小）：距下一个帧边界（vcnt==V_ACTIVE）
     * 还有 ~29 行 ≈ 2800 pclk ⇒ 才能**确定地**观察到"发布之后、帧边界之前 0xB0 不变"。
     * （否则发布恰好贴着帧边界时，那条断言会偶发误判。） */
    task wait_frame_phase;
        begin
            @(posedge pclk);
            while (!((u_scan.hcnt == 12'd0) && (u_scan.vcnt == 12'd3))) @(posedge pclk);
        end
    endtask

    task wait_frames;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1) begin
                @(posedge pclk);
                while (!frame_tick) @(posedge pclk);
            end
        end
    endtask

    /* ================= 抓一场（帧起点 → 下一个帧起点） =================
     * 与 tb_scanout_lut.v 的 run_frame 同一门控：只在 ctrl2[2]（DE + 窗口内 + 行缓冲就绪）
     * 时采样，并取**与输出同一级**的 px2 当源像素。 */
    task capture_frame;
        begin
            cap_n = 0; cap_bk_chg = 0;
            @(posedge pclk);
            while (!frame_tick) @(posedge pclk);
            cap_frame = u_scan.frame_cnt;
            @(posedge pclk);
            while (!frame_tick) begin
                @(posedge pclk);
                if (u_scan.ctrl2[2]) begin
                    cap_tag[cap_n] = u_scan.px2;
                    cap_r[cap_n] = vr; cap_g[cap_n] = vg; cap_b[cap_n] = vb;
                    if ((cap_n > 0) && (u_scan.lut_bk_lat !== cap_bk[cap_n-1]))
                        cap_bk_chg = cap_bk_chg + 1;
                    cap_bk[cap_n] = u_scan.lut_bk_lat;
                    cap_n = cap_n + 1;
                end
            end
        end
    endtask

    /* 把刚抓的这一场登记成"写表前参考场"（同时重建按 tag 索引的表） */
    task commit_ref;
        integer j;
        begin
            for (j = 0; j < ref_n; j = j + 1) tkv[ref_tag[j]] = 1'b0;   // 只清上次用到的 tag
            ref_n = cap_n; ref_frame = cap_frame;
            for (j = 0; j < cap_n; j = j + 1) begin
                ref_tag[j] = cap_tag[j];
                ref_r[j] = cap_r[j]; ref_g[j] = cap_g[j]; ref_b[j] = cap_b[j];
                tkv[cap_tag[j]] = 1'b1;
                tkr[cap_tag[j]] = cap_r[j];
                tkg[cap_tag[j]] = cap_g[j];
                tkb[cap_tag[j]] = cap_b[j];
            end
        end
    endtask

    /* 把刚抓的这一场登记成"关闭 LUT 基准场"（T4 的固定参照） */
    task save_base;
        integer j;
        begin
            base_n = cap_n; base_frame = cap_frame;
            for (j = 0; j < cap_n; j = j + 1) begin
                base_tag[j] = cap_tag[j];
                base_r[j] = cap_r[j]; base_g[j] = cap_g[j]; base_b[j] = cap_b[j];
            end
        end
    endtask

    task watch_start;
        begin
            watch_px = 0; watch_bad = 0; watch_miss = 0; watch_frames = 0;
            watch_on = 1'b1;
        end
    endtask
    task watch_stop;
        begin watch_on = 1'b0; end
    endtask

    /* 写非活动 bank 期间的逐像素监视器：期望值来自"写表前那一场"的**观测值**（按 tag 索引）
     * —— 完全不依赖软件对 bank 的推测。 */
    always @(posedge pclk) begin
        if (prst_n && watch_on) begin
            if (frame_tick) watch_frames = watch_frames + 1;
            if (u_scan.ctrl2[2]) begin
                watch_px = watch_px + 1;
                if (tkv[u_scan.px2]) begin
                    if ((vr !== tkr[u_scan.px2]) || (vg !== tkg[u_scan.px2]) || (vb !== tkb[u_scan.px2])) begin
                        watch_bad = watch_bad + 1;
                        if (watch_bad <= 8)
                            $display("      [watch] 写表期间屏幕变了：frame=%0d tag=%04h got=(%02h,%02h,%02h) 参考=(%02h,%02h,%02h)",
                                     u_scan.frame_cnt, u_scan.px2, vr, vg, vb,
                                     tkr[u_scan.px2], tkg[u_scan.px2], tkb[u_scan.px2]);
                    end
                end else watch_miss = watch_miss + 1;
            end
        end
    end

    /* ---- T2：写表期间整场零变化（watch_px ≥ 一场像素数 ⇒ 至少覆盖了一整场） ---- */
    task check_no_tearing;
        input [2047:0] name;
        input integer  min_frames;
        begin
            $sformat(dtl, "写表期间 DE 像素 %0d（参考场 %0d 像素），变化 %0d，参考缺 tag %0d，跨越帧边界 %0d 个",
                     watch_px, ref_n, watch_bad, watch_miss, watch_frames);
            checkv(name, (watch_bad == 0) && (watch_miss == 0) &&
                         (watch_px >= ref_n) && (watch_frames >= min_frames));
        end
    endtask

    /* ---- 整场逐像素核对模式模型（mode0/1/2） ---- */
    task check_frame_expect;
        input [2047:0] name;
        input integer  mode;
        integer j, nbad;
        reg [7:0] e_r, e_g, e_b;
        begin
            nbad = 0;
            for (j = 0; j < cap_n; j = j + 1) begin
                e_r = mode_r(mode, cap_tag[j]);
                e_g = mode_g(mode, cap_tag[j]);
                e_b = mode_b(mode, cap_tag[j]);
                if ((cap_r[j] !== e_r) || (cap_g[j] !== e_g) || (cap_b[j] !== e_b)) begin
                    nbad = nbad + 1;
                    if (nbad <= 8)
                        $display("      像素#%0d tag=%04h got=(%02h,%02h,%02h) exp=(%02h,%02h,%02h)（模式 %0s）",
                                 j, cap_tag[j], cap_r[j], cap_g[j], cap_b[j], e_r, e_g, e_b, mode_name(mode));
                end
            end
            $sformat(dtl, "本场 %0d 像素（frame=%0d），与模式 %0s 不符 %0d",
                     cap_n, cap_frame, mode_name(mode), nbad);
            checkv(name, (cap_n > 0) && (nbad == 0));
        end
    endtask

    /* ---- 整场逐像素核对"某个 bank 的表内容"（用同一套量化规则算期望） ---- */
    task check_frame_bank;
        input [2047:0] name;
        input integer  bank;
        integer j, nbad;
        reg [7:0] e_r, e_g, e_b;
        begin
            nbad = 0;
            for (j = 0; j < cap_n; j = j + 1) begin
                e_r = lutq_r(tbl[bank][0][xr(cap_tag[j])]);
                e_g = lutq_g(tbl[bank][1][xg(cap_tag[j])]);
                e_b = lutq_b(tbl[bank][2][xb(cap_tag[j])]);
                if ((cap_r[j] !== e_r) || (cap_g[j] !== e_g) || (cap_b[j] !== e_b)) begin
                    nbad = nbad + 1;
                    if (nbad <= 8)
                        $display("      像素#%0d tag=%04h got=(%02h,%02h,%02h) exp=(%02h,%02h,%02h)（bank%0d 表模型）",
                                 j, cap_tag[j], cap_r[j], cap_g[j], cap_b[j], e_r, e_g, e_b, bank);
                end
            end
            $sformat(dtl, "本场 %0d 像素（frame=%0d），与 bank%0d 的表模型不符 %0d", cap_n, cap_frame, bank, nbad);
            checkv(name, (cap_n > 0) && (nbad == 0));
        end
    endtask

    /* ---- T3：整场像素唯一判出"显示的是哪个 bank 的表"，再与 0xB0 回读比 ----
     * 判据只用**像素**（两个 bank 表内容不同 ⇒ 整场能唯一匹配）；0xB0 是被比对的另一方。 */
    task check_bank_pixels;
        input [2047:0] name;
        input integer  exp_bank;
        input [31:0]   rb;                 // 紧邻这次抓帧的 0xB0 回读
        integer j, bad0, bad1, b_obs;
        reg [7:0] e_r, e_g, e_b;
        begin
            bad0 = 0; bad1 = 0;
            for (j = 0; j < cap_n; j = j + 1) begin
                e_r = lutq_r(tbl[0][0][xr(cap_tag[j])]);
                e_g = lutq_g(tbl[0][1][xg(cap_tag[j])]);
                e_b = lutq_b(tbl[0][2][xb(cap_tag[j])]);
                if ((cap_r[j] !== e_r) || (cap_g[j] !== e_g) || (cap_b[j] !== e_b)) bad0 = bad0 + 1;
                e_r = lutq_r(tbl[1][0][xr(cap_tag[j])]);
                e_g = lutq_g(tbl[1][1][xg(cap_tag[j])]);
                e_b = lutq_b(tbl[1][2][xb(cap_tag[j])]);
                if ((cap_r[j] !== e_r) || (cap_g[j] !== e_g) || (cap_b[j] !== e_b)) bad1 = bad1 + 1;
            end
            if (cap_n == 0)                      b_obs = -1;
            else if ((bad0 == 0) && (bad1 != 0)) b_obs = 0;
            else if ((bad1 == 0) && (bad0 != 0)) b_obs = 1;
            else                                 b_obs = -1;    // 两 bank 表相同 / 都对不上
            $sformat(dtl, "像素判定 = %0s（与 bank0 表不符 %0d 个、与 bank1 表不符 %0d 个）；0xB0.bit0 = %0d；期望 bank%0d",
                     (b_obs < 0) ? "无法判定" : ((b_obs == 0) ? "bank0" : "bank1"),
                     bad0, bad1, rb[0], exp_bank);
            checkv(name, (b_obs == exp_bank) && (rb[0] === exp_bank[0]));
        end
    endtask

    /* ---- T4 定责用的逐行对照打印：每个源行标签一行（老输出 vs 恒等表 + 使能） ----
     * 正常（已修）时两列逐位相同；一旦输出级与旁路抽头再分家，这里一眼能看出差在哪个通道。 */
    task dump_rows;
        input [1023:0] name;
        integer j, s, nseen, jc, found;
        reg [15:0] seen [0:63];
        reg [7:0] br, bg2, bb, cr, cg2, cb;
        reg [1:0] hit;
        begin
            nseen = 0;
            $display("      [%0s] 逐行对照：tag（= 源行号+反码） / 老输出(LUT 关) / 恒等表+使能 / 差异通道", name);
            for (j = 0; j < base_n; j = j + 1) begin
                found = 0;
                for (s = 0; s < nseen; s = s + 1)
                    if (seen[s] === base_tag[j]) found = 1;
                if ((found == 0) && (nseen < 64)) begin
                    seen[nseen] = base_tag[j]; nseen = nseen + 1;
                    br = base_r[j]; bg2 = base_g[j]; bb = base_b[j];
                    cr = 8'hxx; cg2 = 8'hxx; cb = 8'hxx; hit = 2'd0;
                    for (jc = 0; jc < cap_n; jc = jc + 1)
                        if ((hit == 2'd0) && (cap_tag[jc] === base_tag[j])) begin
                            cr = cap_r[jc]; cg2 = cap_g[jc]; cb = cap_b[jc]; hit = 2'd1;
                        end
                    $display("        tag=%04h（首次出现 场 x=%0d,y=%0d）老输出=(%02h,%02h,%02h) 恒等+使能=(%02h,%02h,%02h) 差异=%0s%0s%0s",
                             base_tag[j], j % 64, j / 64, br, bg2, bb, cr, cg2, cb,
                             (br !== cr)  ? "R" : "-",
                             (bg2 !== cg2) ? "G" : "-",
                             (bb !== cb)  ? "B" : "-");
                end
            end
        end
    endtask

    /* ---- T1：与"写表前参考场"逐位比较，必须**每一个像素都变了** ---- */
    task check_pixels_changed;
        input [2047:0] name;
        integer j, nchg, nmiss;
        begin
            nchg = 0; nmiss = 0;
            for (j = 0; j < cap_n; j = j + 1) begin
                if (tkv[cap_tag[j]]) begin
                    if ((cap_r[j] !== tkr[cap_tag[j]]) || (cap_g[j] !== tkg[cap_tag[j]]) ||
                        (cap_b[j] !== tkb[cap_tag[j]]))
                        nchg = nchg + 1;
                end else nmiss = nmiss + 1;
            end
            $sformat(dtl, "本场 %0d 像素（frame=%0d）；与写表前参考场（frame=%0d）逐位比较：变了 %0d，参考缺 tag %0d",
                     cap_n, cap_frame, ref_frame, nchg, nmiss);
            checkv(name, (cap_n > 0) && (nchg == cap_n) && (nmiss == 0));
        end
    endtask

    /* ---- T4：与参考**整条流**逐位相同（长度 + tag + 三个通道） ----
     * which=0 → 比 ref（上一次 commit_ref）；which=1 → 比 base（P1 的关 LUT 基准场） */
    task check_stream;
        input [2047:0] name;
        input integer  which;
        integer j, nbad, ntagbad, rn;
        reg [15:0] rt;
        reg [7:0]  rr, rg, rb;
        begin
            nbad = 0; ntagbad = 0;
            if (which == 1) rn = base_n; else rn = ref_n;
            for (j = 0; j < cap_n; j = j + 1) begin
                if (j < rn) begin
                    if (which == 1) begin
                        rt = base_tag[j]; rr = base_r[j]; rg = base_g[j]; rb = base_b[j];
                    end else begin
                        rt = ref_tag[j];  rr = ref_r[j];  rg = ref_g[j];  rb = ref_b[j];
                    end
                    if (cap_tag[j] !== rt) ntagbad = ntagbad + 1;
                    if ((cap_r[j] !== rr) || (cap_g[j] !== rg) || (cap_b[j] !== rb)) begin
                        nbad = nbad + 1;
                        if (nbad <= 8)
                            $display("      像素#%0d（场 x=%0d,y=%0d）tag=%04h got=(%02h,%02h,%02h) 参考=(%02h,%02h,%02h)",
                                     j, j % 64, j / 64, cap_tag[j], cap_r[j], cap_g[j], cap_b[j], rr, rg, rb);
                    end
                end
            end
            $sformat(dtl, "本场 %0d 像素（frame=%0d）vs %0s %0d 像素：值不同 %0d，tag 不同 %0d",
                     cap_n, cap_frame, (which == 1) ? "关 LUT 基准场" : "参考场", rn, nbad, ntagbad);
            checkv(name, (cap_n > 0) && (cap_n === rn) && (nbad == 0) && (ntagbad == 0));
        end
    endtask

    /* ---- 整场只读一张表（fb_scanout 内部锁存的显示 bank 在采样像素之间不许变） ---- */
    task check_single_table;
        input [2047:0] name;
        begin
            $sformat(dtl, "本场 %0d 像素期间内部锁存的显示 bank 变化 %0d 次", cap_n, cap_bk_chg);
            checkv(name, (cap_n > 0) && (cap_bk_chg == 0));
        end
    endtask

    /* =========================================================================
     * 主流程：AdDemo 协议逐轮回放
     * ========================================================================= */
    integer kc;
    initial begin
        watch_on = 1'b0; watch_px = 0; watch_bad = 0; watch_miss = 0; watch_frames = 0;
        cap_n = 0; ref_n = 0; base_n = 0; cap_frame = 0; ref_frame = 0; base_frame = 0;
        cap_bk_chg = 0;
        for (kc = 0; kc < 65536; kc = kc + 1) tkv[kc] = 1'b0;

        /* 与既有 TB 同一套复位约定：core 先放 rst_n，再放 pclk 侧 prst_n */
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (8) @(posedge clk);
        repeat (8) @(posedge pclk);
        prst_n = 1'b1;
        wait_frames(4);                       // 等行缓冲预热（前几场的行还没取到时输出被门控掉）

        /* ---------------- P0 复位状态 ---------------- */
        $display("---- P0 复位：0xB0.bit0 的复位值（显示 bank = ~0xAC.bit1，bit1 复位 0）----");
        axi_read(12'hB0, rv);
        d0 = rv[0];
        $sformat(dtl, "0xB0 回读 = %08h，bit0 = %0d；fb_scanout 内部 lut_bk_lat = %0b", rv, rv[0], u_scan.lut_bk_lat);
        checkv("T3-0 复位后 0xB0.bit0 = 1（显示 bank = ~bit1）", rv[0] === 1'b1);
        dbank = d0;

        /* ---------------- P1 LUT 关闭时的基准场（T4 的固定参照） ----------------
         * 此刻两张表都还没写（BRAM 内容在仿真里是 X），但 en=0 ⇒ 输出必然是老输出。 */
        $display("---- P1 LUT 关闭（复位默认）⇒ 抓老输出基准场 ----");
        capture_frame();
        commit_ref();
        save_base();
        check_frame_expect("T4-0 关闭 LUT 时逐像素 = 老输出（T4 的基准流）", 0);
        axi_read(12'hB0, rv);
        $sformat(dtl, "抓帧首像素时内部 lut_bk_lat = %0b（⇒ 显示 bank = %0d）；0xB0.bit0 = %0d（en=0，像素看不出 bank）",
                 cap_bk[0], ~cap_bk[0], rv[0]);
        checkv("T3-1 关闭 LUT 阶段 0xB0 回读可读且 = 1", rv[0] === 1'b1);

        /* ---------------- P2 开机灌表（AdDemo lut_identity_safe_off 的四步） ----------------
         * ① 读 0xB0（上面已读）= d0=1；② w = ~d0 = 0，0xAC.bit1 = w（写口指向非显示 bank）；
         * ③ 非显示 bank 写"全 0 表"（本台故意不写恒等表：T3 要从像素反推"显示的是哪个
         *    bank"，而恒等表在若干通道上与别的表容易混淆；全 0 表一眼可辨，
         *    且 en=0 ⇒ 这一步屏幕不受任何影响）；
         * ④ 显示 bank 写恒等表（AdDemo 的安全档也刷显示 bank，en=0 无害）；
         * ⑤ 发布：0xAC.bit1 = lut_pub_bank(d0) = 0 ⇒ 帧边界后显示仍是 bank1（恒等表）。 */
        $display("---- P2 开机灌两 bank（en=0；整段逐像素监视）----");
        watch_start();
        axi_write(12'hAC, 32'h0000_0000);        // en=0、写 bank0（复位值，显式写一次）
        wr_tbl(1, 0);                            // bank0 = 全 0 表
        fill_bank(1, 0, 0);                      // bank1 = 恒等表（当时显示的那个 bank，en=0）
        publish(1, 0);                           // ④ bit1 = ~1 = 0 ⇒ 显示 = bank1
        watch_stop();
        check_no_tearing("T2-0 开机灌两个 bank 期间屏幕逐像素零变化（en=0）", 2);
        read_fcnt(fc0);
        wait_frame_change(fc0);                  // 等发布被帧边界锁存
        axi_read(12'hB0, rv);
        $sformat(dtl, "灌表 + 发布并跨帧边界后 0xB0.bit0 = %0d（期望 1 = 恒等表所在的 bank1）", rv[0]);
        checkv("T3-2 灌表后 0xB0.bit0 = 1（bank1 = 恒等表）", rv[0] === 1'b1);
        dbank = rv[0];

        /* ---------------- P3 T4-1：开 LUT，显示 bank 里是恒等表 ----------------
         * 0xAC = bit0=1（en=1，立即生效）+ bit1=~dbank（显示 bank 不变）。
         * 恒等表 + 使能 ⇒ 必须与 P1 的"关 LUT"基准流**逐位相同**。 */
        $display("---- P3 开 LUT（显示 bank 已是恒等表）⇒ T4 兼容性不变量 ----");
        axi_write(12'hAC, (dbank[0] ? 32'd1 : 32'd3));   // bit0=1, bit1=~dbank
        wait_frames(2);                          // 让帧边界把 bit1 采样稳（bit1 未变，只为确定性）
        capture_frame();
        check_stream("T4-1 恒等表 + 使能 = 关闭 LUT（整场逐位相同）", 1);
        dump_rows("T4-1 逐行对照（两列应逐位相同）");
        check_frame_expect("T4-1b 恒等表 + 使能 = 过 LUT 输出级的量化模型（逐像素）", 4);
        check_frame_expect("T4-1c 恒等表 + 使能 = 旁路老输出模型（逐像素）", 0);
        check_single_table("P3 整场只读一个 bank（内部锁存不变）");
        commit_ref();                            // 参考场换成"恒等表使能"这一场
        axi_read(12'hB0, rv);
        check_bank_pixels("T3-3 开启后 像素判定显示 bank = bank1 = 0xB0", 1, rv);

        /* ================= P4 协议回放 #1：非显示 bank ← 全 FF 表，然后发布 ================= */
        $display("---- P4 AdDemo 协议回放 #1：写全 FF 表 → 发布（屏幕应变全白）----");
        axi_read(12'hB0, rv); dbank = rv[0];             // ① 读 0xB0
        wbank = lut_write_bank(dbank);                   // ② w = ~disp
        watch_start();
        axi_write(12'hAC, (32'd1) | (wbank[0] ? 32'd2 : 32'd0));   // ② bit1 = w，bit0 = 已发布的 en=1
        wr_tbl(2, wbank);                                         // ③ 3×256 项全 FF
        wait_frame_phase();                                       // 让发布远离帧边界（判定才确定）
        publish(wbank, 1);                                        // ④ bit1 = ~w = disp
        watch_stop();
        check_no_tearing("T2-1 写全 FF 表期间屏幕逐像素零变化（无撕裂）", 2);

        axi_read(12'hB0, rv);
        $sformat(dtl, "发布后立刻读 0xB0.bit0 = %0d（0xAC.bit1 已 = %0d，期望 0xB0 仍是旧 bank %0d）",
                 rv[0], lut_bank_req, dbank);
        checkv("T3-4 发布后到帧边界前 0xB0 不变（换 bank 只在帧边界）", rv[0] === dbank[0]);

        read_fcnt(fc0);
        wait_frame_change(fc0);
        axi_read(12'hB0, rv);
        $sformat(dtl, "等帧边界读了 %0d 次 0x28；边界后 0xB0.bit0 = %0d（期望 = 刚写的 bank%0d）",
                 nread, rv[0], wbank);
        checkv("T3-5 跨帧边界后 0xB0 = 刚写入的 bank（bank0）", rv[0] === wbank[0]);
        dbank = rv[0];

        capture_frame();
        check_pixels_changed("T1-1 发布并跨帧边界后显示像素整体改变（→全白）");
        check_frame_expect("P4 发布后屏幕 = 刚写的全 FF 表（逐像素）", 2);
        check_single_table("P4 整场只读一个 bank（内部锁存不变）");
        axi_read(12'hB0, rv);
        check_bank_pixels("T3-6 跨帧边界后 像素判定显示 bank0（全 FF 表）= 0xB0", 0, rv);

        /* ================= P5 协议回放 #2：非显示 bank ← 全 0 表，然后发布 ================= */
        $display("---- P5 AdDemo 协议回放 #2：写全 0 表 → 发布（屏幕应变全黑）----");
        commit_ref();                                    // 参考场 = 现在的全白场
        axi_read(12'hB0, rv); dbank = rv[0];             // ①
        wbank = lut_write_bank(dbank);                   // ②
        watch_start();
        axi_write(12'hAC, (32'd1) | (wbank[0] ? 32'd2 : 32'd0));
        wr_tbl(1, wbank);                                // ③ 全 0 表
        wait_frame_phase();
        publish(wbank, 1);                               // ④
        watch_stop();
        check_no_tearing("T2-2 写全 0 表期间屏幕逐像素零变化（无撕裂）", 2);

        axi_read(12'hB0, rv);
        $sformat(dtl, "发布后立刻读 0xB0.bit0 = %0d（0xAC.bit1 已 = %0d，期望仍是旧 bank %0d）",
                 rv[0], lut_bank_req, dbank);
        checkv("T3-7 发布后到帧边界前 0xB0 仍是旧 bank", rv[0] === dbank[0]);

        read_fcnt(fc0);
        wait_frame_change(fc0);
        axi_read(12'hB0, rv);
        $sformat(dtl, "等帧边界读了 %0d 次 0x28；边界后 0xB0.bit0 = %0d（期望 bank%0d）", nread, rv[0], wbank);
        checkv("T3-8 跨帧边界后 0xB0 = 刚写入的 bank（bank1）", rv[0] === wbank[0]);
        dbank = rv[0];

        capture_frame();
        check_pixels_changed("T1-2 发布并跨帧边界后显示像素整体改变（→全黑）");
        check_frame_expect("P5 发布后屏幕 = 刚写的全 0 表（逐像素）", 1);
        check_single_table("P5 整场只读一个 bank（内部锁存不变）");
        axi_read(12'hB0, rv);
        check_bank_pixels("T3-9 跨帧边界后 像素判定显示 bank1（全 0 表）= 0xB0", 1, rv);

        /* ================= P6 协议回放 #3：非显示 bank ← 恒等表，然后发布 =================
         * 既验证"跨了三次 bank 切换之后恒等表的不变量还成立"（T4-2），
         * 又给 T4-3（反向：保持 bank、只关使能）准备一个"使能中的恒等表"场。 */
        $display("---- P6 AdDemo 协议回放 #3：写恒等表 → 发布 → T4 复核 ----");
        commit_ref();                                    // 参考场 = 现在的全黑场
        axi_read(12'hB0, rv); dbank = rv[0];             // ①
        wbank = lut_write_bank(dbank);                   // ②
        watch_start();
        axi_write(12'hAC, (32'd1) | (wbank[0] ? 32'd2 : 32'd0));
        wr_tbl(0, wbank);                                // ③ 恒等表
        wait_frame_phase();
        publish(wbank, 1);                               // ④
        watch_stop();
        check_no_tearing("T2-3 写恒等表期间屏幕逐像素零变化（无撕裂）", 2);

        read_fcnt(fc0);
        wait_frame_change(fc0);
        axi_read(12'hB0, rv);
        $sformat(dtl, "等帧边界读了 %0d 次 0x28；边界后 0xB0.bit0 = %0d（期望 bank%0d）", nread, rv[0], wbank);
        checkv("T3-10 跨帧边界后 0xB0 = 刚写入的 bank（恒等表）", rv[0] === wbank[0]);
        dbank = rv[0];

        capture_frame();
        check_pixels_changed("T1-3 发布并跨帧边界后显示像素整体改变（全黑→老输出）");
        check_frame_expect("P6 发布后屏幕 = 恒等表 + 使能（过 LUT 输出级，逐像素）", 4);
        check_frame_bank("P6 与 bank0 表模型逐像素一致（真的走 0xA4/0xA8 写进去的恒等表）", 0);
        check_frame_expect("P6b 恒等表 + 使能 = 旁路老输出模型（逐像素）", 0);
        check_stream("T4-2 跨三次 bank 切换后：恒等表 + 使能 仍 = 关闭 LUT（对 P1 基准逐位相同）", 1);
        check_single_table("P6 整场只读一个 bank（内部锁存不变）");
        axi_read(12'hB0, rv);
        check_bank_pixels("T3-11 跨帧边界后 像素判定显示 bank0（恒等表）= 0xB0", 0, rv);

        /* T4-3 反向：保持 bank 不变、只把 bit0 关掉 ⇒ 必须与上面那一场逐位相同 */
        commit_ref();                                    // 参考场 = 使能中的恒等表场
        axi_write(12'hAC, (lut_bank_req ? 32'd2 : 32'd0));   // bit0=0，bit1 不动
        wait_frames(2);
        capture_frame();
        check_stream("T4-3 反向复核：关闭 LUT 与恒等表 + 使能 逐位相同（同一 bank）", 0);
        check_frame_expect("T4-3b 关闭 LUT 后逐像素 = 老输出", 0);
        axi_read(12'hB0, rv);
        $sformat(dtl, "只改 bit0 后 0xB0.bit0 = %0d（bit1 未动 ⇒ 显示 bank 应不变 = %0d）", rv[0], dbank);
        checkv("T3-12 只改 bit0 不动 bit1：显示 bank 不变", rv[0] === dbank[0]);

        /* ================= P7 协议回放 #4：分通道表（专查 0xA4[9:8] 的 R/G/B 译码） ======
         * 前几轮都是"三通道同值"的表，查不出通道译码错。这一轮写 R=255-i / G=i>>2 /
         * B=i^0xAA，用 bank1 的表模型逐像素比对。
         * ★ 这一轮的发布同时把 bit0 从 0 抬到 1（使能立即生效）：此刻显示 bank 里是恒等表
         *   ⇒ 使能翻转本身在屏幕上看不出来 —— 监视器覆盖到发布，正好把这一点也验证掉。 */
        $display("---- P7 AdDemo 协议回放 #4：分通道表 R=255-i / G=i>>2 / B=i^0xAA ----");
        commit_ref();                                    // 参考场 = 关 LUT 的老输出
        axi_read(12'hB0, rv); dbank = rv[0];             // ①
        wbank = lut_write_bank(dbank);                   // ②
        watch_start();
        axi_write(12'hAC, (wbank[0] ? 32'd2 : 32'd0));   // bit0=0（此刻 LUT 关着），bit1 = w
        wr_tbl(3, wbank);                                // ③ 分通道表
        wait_frame_phase();
        publish(wbank, 1);                               // ④ 发布 + 开使能（显示 bank 是恒等表 ⇒ 无可见变化）
        watch_stop();
        check_no_tearing("T2-4 写分通道表（含使能 0→1）期间屏幕逐像素零变化", 2);

        read_fcnt(fc0);
        wait_frame_change(fc0);
        axi_read(12'hB0, rv);
        $sformat(dtl, "等帧边界读了 %0d 次 0x28；边界后 0xB0.bit0 = %0d（期望 bank%0d）", nread, rv[0], wbank);
        checkv("T3-13 跨帧边界后 0xB0 = 分通道表所在 bank", rv[0] === wbank[0]);
        dbank = rv[0];

        capture_frame();
        check_pixels_changed("T1-4 发布并跨帧边界后显示像素整体改变（→分通道表）");
        check_frame_bank("P7 分通道表逐像素比对（R/G/B 三通道译码都对）", 1);
        check_single_table("P7 整场只读一个 bank（内部锁存不变）");
        axi_read(12'hB0, rv);
        check_bank_pixels("T3-14 像素判定显示 bank1（分通道表）= 0xB0", 1, rv);

        /* ================= 收尾 ================= */
        $display("================================================================");
        $display("tb_lut_proto：断言 %0d 条，FAIL %0d 条", nchecks, errors);
        $display("  T1 发布后像素真的变 / T2 写表期间整场零变化 / T3 0xB0 与像素一致 / T4 恒等表逐位兼容");
        if (errors != 0) begin
            $display("  注：T4 家族失败 = LUT 输出级与旁路的两套 5/6/5→8bit 抽头又分家了。");
            $display("      两者必须同口径（fb_scanout.v 末尾的输出级与 r8/g8/b8 互为基准）：");
            $display("      旁路补字段低位（r5[2:0]/g6[2:1]/b5[2:0]），输出级就得补同样的位；");
            $display("      不同口径时恒等表 + 使能 ≠ 关闭 LUT（差 1~7 个 LSB，整场全差）。");
        end
        if (errors == 0) $display("========== tb_lut_proto ALL PASS ==========");
        else             $display("========== tb_lut_proto FAILED: %0d ==========", errors);
        $finish;
    end

    /* 看门狗：正常流程应在 ~2ms 内结束（本台要灌 5 张表 + 抓 10 余场） */
    initial begin
        #50_000_000;
        $display("!!!!!!!! tb_lut_proto WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
