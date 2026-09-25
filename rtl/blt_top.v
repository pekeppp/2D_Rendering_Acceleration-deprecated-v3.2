/* =========================================================================
 * blt_top.v — BitBlt 引擎顶层（960×540@60 目标；AXI 128bit 板级）
 * 对外：AXI-Lite 从机 + 两组 AXI4 主机（读 AR/R、写 AW/W/B）
 * ========================================================================= */
module blt_top #(
    parameter AXI_DATA_W = 128,
    parameter CMD_DEPTH  = 256
)(
    input  wire                clk,
    input  wire                rst_n,

    input  wire [11:0]         s_axil_awaddr,
    input  wire                s_axil_awvalid,
    output wire                s_axil_awready,
    input  wire [31:0]         s_axil_wdata,
    input  wire [3:0]          s_axil_wstrb,
    input  wire                s_axil_wvalid,
    output wire                s_axil_wready,
    output wire                s_axil_bvalid,
    output wire [1:0]          s_axil_bresp,
    input  wire                s_axil_bready,
    input  wire [11:0]         s_axil_araddr,
    input  wire                s_axil_arvalid,
    output wire                s_axil_arready,
    output wire [31:0]         s_axil_rdata,
    output wire [1:0]          s_axil_rresp,
    output wire                s_axil_rvalid,
    input  wire                s_axil_rready,

    output wire [31:0]         m_axi_araddr,
    output wire [7:0]          m_axi_arlen,
    output wire [2:0]          m_axi_arsize,
    output wire [1:0]          m_axi_arburst,
    output wire                m_axi_arvalid,
    input  wire                m_axi_arready,
    input  wire [AXI_DATA_W-1:0] m_axi_rdata,
    input  wire [1:0]          m_axi_rresp,
    input  wire                m_axi_rlast,
    input  wire                m_axi_rvalid,
    output wire                m_axi_rready,

    output wire [31:0]         m_axi_awaddr,
    output wire [7:0]          m_axi_awlen,
    output wire [2:0]          m_axi_awsize,
    output wire [1:0]          m_axi_awburst,
    output wire                m_axi_awvalid,
    input  wire                m_axi_awready,
    output wire [AXI_DATA_W-1:0] m_axi_wdata,
    output wire [AXI_DATA_W/8-1:0] m_axi_wstrb,
    output wire                m_axi_wlast,
    output wire                m_axi_wvalid,
    input  wire                m_axi_wready,
    input  wire                m_axi_bvalid,
    input  wire [1:0]          m_axi_bresp,
    output wire                m_axi_bready,

    output wire                irq_done,

    /* 扫描输出健康度（只读诊断，接 fb_scanout 的 dbg_underrun/dbg_abort；
     * 不接就恒 0，不影响功能）。用于在板上量化"显示是否被 DDR 竞争拖垮"。 */
    input  wire [15:0]         scan_underrun,
    input  wire [15:0]         scan_abort,

    /* ★ 显示缓冲翻转（FLIP）：寄存器 0x24/0x28 ↔ fb_scanout 的 fb_sel/fb_cur_sel/frame_cnt。
     *   三个信号都**必须由顶层（ddr3_example_top）接到同一个 fb_scanout 实例**；
     *   不接的话 fb_sel 悬空（无默认值）⇒ 取数地址变 X。见 ddr3_example_top.v 的连线。
     *   ★v2.7：选择位 1 bit → 2 bit（三缓冲）；新增 frame_pulse（帧边界 1 拍脉冲）。 */
    output wire [1:0]          fb_sel,        // 0x24 W：请求显示的缓冲（0/1/2）
    input  wire [1:0]          fb_cur_sel,    // 0x28 R [1:0]   ：已生效的显示缓冲
    input  wire [15:0]         fb_frame_cnt,  // 0x28 R [31:16]：场计数
    input  wire                frame_pulse,   // ★v2.7：帧边界脉冲 → IRQ_STATUS[1]

    /* ★S5（v3.2）扫描输出颜色 LUT（寄存器 0xA4~0xB0 ↔ fb_scanout）。
     * 与 fb_sel 同一套做法：必须由顶层（ddr3_example_top）接到**同一个 fb_scanout 实例**。
     * 不接的话 lut_en 悬空（无默认值）⇒ 按下述"z = 关闭"约定仍是兼容档（见 fb_scanout）。 */
    output wire                lut_wr,        // 0xA8 写脉冲（1 拍）
    output wire [1:0]          lut_ch,        // 0xA4[9:8]：0=R 1=G 2=B
    output wire [7:0]          lut_idx,       // 0xA4[7:0]
    output wire [7:0]          lut_data,      // 0xA8[7:0]
    output wire                lut_en,        // 0xAC bit0（请求，帧边界生效）
    output wire                lut_bank_req,  // 0xAC bit1（请求，帧边界生效）
    input  wire                lut_bank_act   // 0xB0 bit0：已生效 bank（来自 fb_scanout）
);
    /* ---------------- 内部互连声明（先于例化） ---------------- */
    wire soft_rst, ctrl_go, irq_en;
    wire eng_busy, eng_done, eng_err;
    wire cmd_empty, cmd_full;
    wire [8:0]  cmd_cmd_count;
    wire [11:0] cmd_wcount;
    wire [31:0] cmd_dout;
    wire        cmd_pop;
    wire [31:0] dbg_op;
    wire [31:0] perf;

    wire fifo_wr_en;
    wire [31:0] fifo_wr_data;

    wire [127:0] fg_dout, bg_dout;
    wire         fg_empty, bg_empty;      // 数据可用性权威标志（同步读 FIFO 用 empty）
    wire         fg_full, bg_full;
    wire         fg_rd_pp, fg_rd_eng, bg_rd_pp, bg_rd_eng;

    wire [175:0] wd_din, wd_dout;
    wire         wd_wr, wd_empty, wd_full, wd_pop;
    wire         wd_busy;
    wire [4:0]   wd_count;                 // wd FIFO **真实**占用（count 口径）
    wire [4:0]   wr_b_pending;             // 已发 AW、未回 B 的写突发数（观测用，见下方屏障）
    wire         wr_idle_committed;        // 写主机侧：无在飞写突发且本机空闲
    wire         wr_cmd_end;               // ★v2.10 引擎侧"本命令再无写词"提示 → 写主机尾冲刷

    wire [1:0]  pp_op;
    wire [15:0] pp_width;
    wire [31:0] pp_dbase;
    wire [2:0]  pp_dlane0, pp_fskip, pp_bskip;
    wire [7:0]  pp_alpha;
    wire [15:0] pp_color, pp_key;
    wire        pp_start, pp_busy, pp_row_done;
    wire        pp_fg_rd, pp_bg_rd;
    wire        pp_wd_wr;
    wire [175:0] pp_wd_word;

    /* ---------------- ★S5（v3.2）属性侧口 / scissor 互连 ----------------
     * 属性 FIFO 在寄存器组内部（写口 = AXI 握手），引擎侧只连"空/队头/弹"三根线；
     * scissor 四边界 + 使能直接由寄存器组进引擎（引擎在**命令起始**锁存）。 */
    wire        attr_empty, attr_pop;
    wire [31:0] attr_dout;
    wire [15:0] clip_x0, clip_x1, clip_y0, clip_y1;
    wire        clip_en;
    wire [31:0] pp_attr;
    wire        pp_blend;

    /* ---------------- ★v2.7 清屏引擎（并发写主机）互连 ----------------
     * 两个写主机（BitBlt 写主机 / 清屏引擎）经**同一个 axi_wr_arb** 合流：
     *   · BitBlt 侧 = 仲裁器 `c_`（默认 owner / 直通）⇒ **BitBlt 赢**；
     *   · 清屏侧   = 仲裁器 `b_`（次级）        ⇒ **只填空闲档**。
     * 清屏引擎从不启动时（默认软件行为）awvalid 恒 0 ⇒ owner 恒不切换
     * ⇒ BitBlt 写通路与改动前逐位相同。 */
    wire [31:0]         blt_awaddr, clr_awaddr, mrg_awaddr;
    wire [7:0]          blt_awlen,  clr_awlen,  mrg_awlen;
    wire [2:0]          blt_awsize, clr_awsize, mrg_awsize;
    wire [1:0]          blt_awburst,clr_awburst,mrg_awburst;
    wire                blt_awvalid,clr_awvalid,mrg_awvalid;
    wire                blt_awready,clr_awready,mrg_awready;
    wire [AXI_DATA_W-1:0]   blt_wdata, clr_wdata, mrg_wdata;
    wire [AXI_DATA_W/8-1:0] blt_wstrb, clr_wstrb, mrg_wstrb;
    wire                blt_wlast,  clr_wlast,  mrg_wlast;
    wire                blt_wvalid, clr_wvalid, mrg_wvalid;
    wire                blt_wready, clr_wready, mrg_wready;
    wire                blt_bvalid, clr_bvalid, mrg_bvalid;
    wire [1:0]          blt_bresp,  clr_bresp,  mrg_bresp;
    wire                blt_bready, clr_bready, mrg_bready;
    /* 清屏引擎配置/状态（寄存器组 ↔ 引擎） */
    wire [31:0] clr_cfg_addr, clr_cfg_stride;
    wire [15:0] clr_cfg_w, clr_cfg_h, clr_cfg_color;
    wire [1:0]  clr_cfg_sel, draw_sel_w;
    wire        clr_cfg_go, clr_cfg_err_clr, draw_wr_w;
    wire        clr_busy_w, clr_err_w;
    wire [3:0]  clr_clean_w;
    wire [15:0] clr_burst_w;
    wire [31:0] clr_cyc_w;

    wire [1:0]  rd_tag;                    // ★v2.11：00=fg 01=bg 10=desc
    wire        rd_req, rd_busy, rd_done, rd_bg, rd_ready;
    wire [1:0]  rd_rresp;
    wire [31:0] rd_addr;
    wire [7:0]  rd_len;
    wire        rd_fg_valid, rd_bg_valid, rd_desc_valid;
    wire [AXI_DATA_W-1:0] rd_data;

    wire int_rst_n = rst_n & ~soft_rst;

    /* ---------------- ★v2.11 显示列表（S2）互连 ---------------- */
    wire [31:0] dl_base0, dl_base1, dl_geom_base, dl_dst_base;
    wire [15:0] dl_count, dl_geom_max, dl_timeout, dl_dst_stride, dl_fb_w, dl_fb_h;
    wire [3:0]  dl_cfg_chunk, dl_cfg_wm;
    wire        dl_buf_sel, dl_irq_en, dl_auto_go, dl_strict;
    wire        dl_cfg_prefetch, dl_cfg_gec;
    wire        dl_go_pulse, dl_abort_pulse, dl_err_clr_pulse, dl_list_rewr_pulse;
    wire        dl_base_align_err;
    wire [31:0] dl_err_clr_mask;
    wire        dl_cmd_req, dl_cmd_last, dl_cmd_gnt;
    wire [31:0] dl_cmd_data;
    wire        dl_busy, dl_done, dl_err, dl_aborted, dl_stall;
    wire [15:0] dl_consumed;
    wire [1:0]  dl_active_buf;
    wire [31:0] dl_err_word, dl_fault_addr, dl_perf;
    wire        dl_auto_go_hold;
    wire        dl_desc_req, dl_desc_ready, dl_desc_rvalid;
    wire [31:0] dl_desc_addr;
    wire [7:0]  dl_desc_len;
    /* 引擎 go = CTRL.GO | DFU 的 AUTO_GO（首条命令入队后自动拉起，见设计文档 §6） */
    wire        eng_go = ctrl_go | dl_auto_go_hold;

    /* ---------------- 寄存器（AXI-Lite 从机） ---------------- */
    blt_regs_axi_lite #(.ADDR_W(12)) u_regs (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(s_axil_awaddr), .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata), .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid), .s_axil_wready(s_axil_wready),
        .s_axil_bvalid(s_axil_bvalid), .s_axil_bresp(s_axil_bresp),
        .s_axil_bready(s_axil_bready),
        .s_axil_araddr(s_axil_araddr), .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata), .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid), .s_axil_rready(s_axil_rready),
        .ctrl_go(ctrl_go), .soft_rst(soft_rst), .irq_en(irq_en),
        .eng_busy(eng_busy), .eng_done(eng_done), .eng_err(eng_err),
        .fifo_empty(cmd_empty), .fifo_full(cmd_full),
        .fifo_cmd_count(cmd_cmd_count),
        .fifo_wr_en(fifo_wr_en), .fifo_wr_data(fifo_wr_data),
        .dbg_cur(dbg_op), .perf(perf), .irq_done(irq_done),
        .scan_underrun(scan_underrun), .scan_abort(scan_abort),
        .fb_sel(fb_sel), .fb_cur_sel(fb_cur_sel), .fb_frame_cnt(fb_frame_cnt),
        .frame_pulse(frame_pulse),
        /* ★v2.7 清屏引擎寄存器（0x2C~0x48，见 blt_regs_axi_lite.v 头注释） */
        .clr_addr(clr_cfg_addr), .clr_stride(clr_cfg_stride),
        .clr_w(clr_cfg_w), .clr_h(clr_cfg_h), .clr_color(clr_cfg_color),
        .clr_sel(clr_cfg_sel), .clr_go(clr_cfg_go), .clr_err_clr(clr_cfg_err_clr),
        .clr_busy(clr_busy_w), .clr_err(clr_err_w), .clr_clean(clr_clean_w),
        .clr_burst(clr_burst_w), .clr_cyc(clr_cyc_w),
        .draw_sel(draw_sel_w), .draw_wr(draw_wr_w),
        /* ★v2.11 显示列表（0x4C~0x88；DFU 的状态回读 + cmd_fifo 写口仲裁） */
        .dl_base0(dl_base0), .dl_base1(dl_base1), .dl_count(dl_count),
        .dl_buf_sel(dl_buf_sel), .dl_irq_en(dl_irq_en),
        .dl_auto_go(dl_auto_go), .dl_strict(dl_strict),
        .dl_go_pulse(dl_go_pulse), .dl_abort_pulse(dl_abort_pulse),
        .dl_geom_base(dl_geom_base), .dl_geom_max(dl_geom_max),
        .dl_dst_base(dl_dst_base),
        .dl_cfg_chunk(dl_cfg_chunk), .dl_cfg_wm(dl_cfg_wm),
        .dl_cfg_prefetch(dl_cfg_prefetch), .dl_cfg_gec(dl_cfg_gec),
        .dl_timeout(dl_timeout), .dl_dst_stride(dl_dst_stride),
        .dl_fb_w(dl_fb_w), .dl_fb_h(dl_fb_h),
        .dl_err_clr_mask(dl_err_clr_mask), .dl_err_clr_pulse(dl_err_clr_pulse),
        .dl_list_rewr_pulse(dl_list_rewr_pulse),
        .dl_base_align_err(dl_base_align_err),
        .dl_busy(dl_busy), .dl_done(dl_done), .dl_err(dl_err),
        .dl_aborted(dl_aborted), .dl_stall(dl_stall),
        .dl_consumed(dl_consumed), .dl_active_buf(dl_active_buf),
        .dl_err_word(dl_err_word), .dl_fault_addr(dl_fault_addr), .dl_perf(dl_perf),
        .dl_cmd_req(dl_cmd_req), .dl_cmd_data(dl_cmd_data),
        .dl_cmd_last(dl_cmd_last), .dl_cmd_gnt(dl_cmd_gnt),
        /* ★S5（v3.2）属性侧口 / scissor / 扫描输出 LUT */
        .attr_empty(attr_empty), .attr_dout(attr_dout), .attr_pop(attr_pop),
        .clip_x0(clip_x0), .clip_x1(clip_x1), .clip_y0(clip_y0), .clip_y1(clip_y1),
        .clip_en(clip_en),
        .lut_wr(lut_wr), .lut_ch(lut_ch), .lut_idx(lut_idx), .lut_data(lut_data),
        .lut_en(lut_en), .lut_bank_req(lut_bank_req), .lut_bank_act(lut_bank_act)
    );

    /* ---------------- 指令 FIFO ---------------- */
    cmd_fifo #(.CMD_DEPTH(CMD_DEPTH)) u_cmd (
        .clk(clk), .rst_n(int_rst_n),
        .wr_en(fifo_wr_en), .din(fifo_wr_data),
        .rd_en(cmd_pop), .dout(cmd_dout),
        .full(cmd_full), .empty(cmd_empty),
        .word_count(cmd_wcount), .cmd_count(cmd_cmd_count)
    );

    /* ---------------- 数据 FIFO ----------------
     * 深度 256（= 2 行 × 121 词 + 余量）：行级重叠时 FIFO 里最多同时存在
     * 两行（正在处理的行 + 已预取到的下一行），960 宽一行覆盖 121 个 16B 词。 */
    sync_fifo #(.DW(128), .DEPTH(256)) u_src_fifo (
        .clk(clk), .rst_n(int_rst_n),
        .wr_en(rd_fg_valid), .din(rd_data),
        .rd_en(fg_rd_pp | fg_rd_eng), .rd_ack(), .dout(fg_dout),
        .full(fg_full), .empty(fg_empty), .count()
    );
    sync_fifo #(.DW(128), .DEPTH(256)) u_bg_fifo (
        .clk(clk), .rst_n(int_rst_n),
        .wr_en(rd_bg_valid), .din(rd_data),
        .rd_en(bg_rd_pp | bg_rd_eng), .rd_ack(), .dout(bg_dout),
        .full(bg_full), .empty(bg_empty), .count()
    );
    sync_fifo #(.DW(176), .DEPTH(16)) u_wd_fifo (
        .clk(clk), .rst_n(int_rst_n),
        .wr_en(wd_wr), .din(wd_din),
        .rd_en(wd_pop), .rd_ack(), .dout(wd_dout),
        .full(wd_full), .empty(wd_empty), .count(wd_count)
    );

    /* ---------------- 写提交屏障（新增） ----------------
     * 一条指令的"完成"必须是"像素真的交给内存系统了"，判据三合一：
     *   · wd_count == 0 ：wd FIFO 真的空（含"在飞/输出寄存器"那几拍）
     *   · !wd_busy      ：写主机不在收突发
     *   · b_pending == 0：没有任何已受理 AW 还没回 B（写响应是主机能拿到的
     *                     唯一"内存系统已受理"的排序原语）
     * 为什么不能只用 wd_empty：sync_fifo 是**同步读 + 输出寄存器**，empty = !out_v，
     * 最后一个词推进 FIFO 后要 2~3 拍才在 out_v 上可见 —— 这段窗口里 empty=1（假空）。
     * 旧代码正是在这个窗口里判完成：引擎报 IDLE / STATUS.BUSY=0 时，最后一个写词
     * 还躺在 FIFO 里、连 AW 都还没发出去；软件 blt_idle() 却以为像素已落 DDR，
     * 而且下一条指令的读（ALPHA/KEY 的 dst、COPY 的 src）会跑在上一条指令的写前面
     * （写后读危险 → 重叠处混合到旧背景，屏幕上就是 z 序闪/换）。
     * 现在：命令 k+1 的写与读都不可能早于命令 k 的写被内存系统受理。 */
`ifdef BLT_WR_ORDER_OFF
    wire wr_commit_idle = 1'b1;            // A/B 对照：关掉屏障（= 旧行为：wd_empty 判完成）
`else
    wire wr_commit_idle = wr_idle_committed && (wd_count == 5'd0) && !wd_busy;
`endif

    /* ---------------- 像素通路 ---------------- */
    pixel_path u_path (
        .clk(clk), .rst_n(int_rst_n),
        .start(pp_start), .busy(pp_busy), .row_done(pp_row_done),
        .op(pp_op), .width(pp_width),
        .d_base(pp_dbase), .d_lane0(pp_dlane0),
        .fg_skip(pp_fskip), .bg_skip(pp_bskip),
        .alpha(pp_alpha), .color(pp_color), .key(pp_key),
        .blend(pp_blend), .attr(pp_attr),                 // ★S5 属性侧口
        .fg_empty(fg_empty), .fg_dout(fg_dout), .fg_rd(pp_fg_rd),
        .bg_empty(bg_empty), .bg_dout(bg_dout), .bg_rd(pp_bg_rd),
        .wd_full(wd_full), .wd_wr(pp_wd_wr), .wd_word(pp_wd_word)
    );
    assign wd_wr  = pp_wd_wr;
    assign wd_din = pp_wd_word;
    assign fg_rd_pp = pp_fg_rd;
    assign bg_rd_pp = pp_bg_rd;

    /* ---------------- AXI 读主机（多笔在飞 / 突发流水 / 三流 tag） ---------------- */
    axi_rd_master #(.AXI_DATA_W(AXI_DATA_W), .MAX_BEATS(16), .OUTSTAND(4)) u_rd (
        .clk(clk), .rst_n(int_rst_n),
        .rd_req(rd_req), .rd_addr(rd_addr), .rd_len(rd_len),
        /* ★v2.11：引擎的 rd_bg（1bit）映射成 rd_sel[1:0]：0=fg 1=bg（引擎 FSM 未改） */
        .rd_sel(rd_bg ? 2'b01 : 2'b00),
        .rd_ready(rd_ready),
        .rd_busy(rd_busy), .rd_done(rd_done), .rd_tag_out(rd_tag),
        /* ★v2.11 第三路：显示列表取指器的描述符/几何表读（优先级最低 + AGE 提权） */
        .dl_req(dl_desc_req), .dl_addr(dl_desc_addr), .dl_len(dl_desc_len),
        .dl_ready(dl_desc_ready),
        .fg_rready(!fg_full), .bg_rready(!bg_full), .desc_rready(1'b1),
        .fg_rvalid(rd_fg_valid), .bg_rvalid(rd_bg_valid),
        .desc_rvalid(rd_desc_rvalid),
        .rdata(rd_data), .rd_rresp(rd_rresp),
        .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize), .m_axi_arburst(m_axi_arburst),
        .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)
    );

    /* ---------------- AXI 写主机（BitBlt） ----------------
     * ★v2.7：它的 AXI 写口不再直接出顶层，而是接**内部仲裁器**的 `c_` 侧
     *   （默认 owner / 直通），与清屏引擎的 `b_` 侧合流后再出顶层。 */
    axi_wr_master #(.AXI_DATA_W(AXI_DATA_W), .MAX_BEATS(16)) u_wr (
        .clk(clk), .rst_n(int_rst_n),
        .wd_empty(wd_empty), .wd_dout(wd_dout), .wd_pop(wd_pop),
        /* ★v2.9：把 wd FIFO 的**真实占用**（count 口径）交给写主机做合并判据。
         * 只改这一根连线 + axi_wr_master 内部判据：旧行为只看 wd_empty(=!out_v)，
         * 而同步读 FIFO 弹字后输出寄存器有 1 拍空窗 ⇒ 合并从来没触发过
         * （探针实测 burst_max=1、AW_top=64,800）。写主机用 count 派生
         * dout_v/cnt_more 分开判"本拍 dout 上真有新词"与"队头之后还有货"，
         * 详见 axi_wr_master.v 头注释；-DWR_MERGE_HOLD_OFF 可逐字回到旧行为。 */
        .wd_count(wd_count),
        .wd_busy(wd_busy),
        /* ★v2.10：引擎的原位提示（ST_WDWAIT）——命令末尾没有别的词会来了，
         * 尾突发按"排空即发车"处理，不再等满 HOLD_MAX=16 拍。只改冲刷时机，
         * 不改 AW→W→B 结构/顺序与完成判据；-DWR_CMD_END_FLUSH_OFF 可关掉。 */
        .cmd_end_flush(wr_cmd_end),
        .b_pending(wr_b_pending), .wr_idle_committed(wr_idle_committed),
        .m_axi_awaddr(blt_awaddr), .m_axi_awlen(blt_awlen),
        .m_axi_awsize(blt_awsize), .m_axi_awburst(blt_awburst),
        .m_axi_awvalid(blt_awvalid), .m_axi_awready(blt_awready),
        .m_axi_wdata(blt_wdata), .m_axi_wstrb(blt_wstrb),
        .m_axi_wlast(blt_wlast), .m_axi_wvalid(blt_wvalid),
        .m_axi_wready(blt_wready),
        .m_axi_bvalid(blt_bvalid), .m_axi_bresp(blt_bresp),
        .m_axi_bready(blt_bready)
    );

    /* ---------------- ★v2.7 并发清屏引擎 ----------------
     * 纯写主机：把一块矩形清成常量色，与 BitBlt 并行跑在**另一块**缓冲上。
     * 互斥（目标 == 正在显示 / 正在画 ⇒ 拒绝写）在 clr_engine 内部硬件实现。 */
    clr_engine #(.AW(32), .DW(AXI_DATA_W), .MAX_BEATS(16)) u_clr (
        .clk(clk), .rst_n(int_rst_n),
        .cfg_addr(clr_cfg_addr), .cfg_stride(clr_cfg_stride),
        .cfg_w(clr_cfg_w), .cfg_h(clr_cfg_h), .cfg_color(clr_cfg_color),
        .cfg_sel(clr_cfg_sel), .cfg_go(clr_cfg_go), .cfg_err_clr(clr_cfg_err_clr),
        .fb_cur_sel(fb_cur_sel), .draw_sel(draw_sel_w), .draw_wr(draw_wr_w),
        .busy(clr_busy_w), .err(clr_err_w), .clean(clr_clean_w),
        .burst_cnt(clr_burst_w), .cyc_cnt(clr_cyc_w),
        .m_axi_awaddr(clr_awaddr), .m_axi_awlen(clr_awlen),
        .m_axi_awsize(clr_awsize), .m_axi_awburst(clr_awburst),
        .m_axi_awvalid(clr_awvalid), .m_axi_awready(clr_awready),
        .m_axi_wdata(clr_wdata), .m_axi_wstrb(clr_wstrb),
        .m_axi_wlast(clr_wlast), .m_axi_wvalid(clr_wvalid),
        .m_axi_wready(clr_wready),
        .m_axi_bvalid(clr_bvalid), .m_axi_bresp(clr_bresp),
        .m_axi_bready(clr_bready)
    );

    /* ---------------- ★v2.7 写通道合流：BitBlt 赢，清屏引擎填空闲档 ----------------
     * 复用 rtl/video/axi_wr_arb.v（与顶层 CPU/BitBlt 那级同一个模块、同一套规则）：
     *   c_ 侧 = BitBlt 写主机（默认 owner、直通）；b_ 侧 = 清屏引擎（次级、可被抢）。
     * 仲裁器只在"次级当前没有在飞写突发"时才切换 owner ⇒ 绝不会把一笔突发的
     * AW/W/B 拆到两侧（这是它在 §12 修好的那条不变量）。 */
    axi_wr_arb #(.AW(32), .DW(AXI_DATA_W), .IDW(1)) u_wr_merge (
        .clk(clk), .rst_n(int_rst_n),
        /* BitBlt 侧（默认 owner） */
        .c_awaddr(blt_awaddr), .c_awlen(blt_awlen), .c_awsize(blt_awsize),
        .c_awburst(blt_awburst), .c_awid(1'b0),
        .c_awvalid(blt_awvalid), .c_awready(blt_awready),
        .c_wdata(blt_wdata), .c_wstrb(blt_wstrb), .c_wlast(blt_wlast),
        .c_wvalid(blt_wvalid), .c_wready(blt_wready),
        .c_bvalid(blt_bvalid), .c_bresp(blt_bresp), .c_bid(), .c_bready(blt_bready),
        /* 清屏引擎侧（次级：只填空闲档） */
        .b_awaddr(clr_awaddr), .b_awlen(clr_awlen), .b_awsize(clr_awsize),
        .b_awburst(clr_awburst), .b_awvalid(clr_awvalid), .b_awready(clr_awready),
        .b_wdata(clr_wdata), .b_wstrb(clr_wstrb), .b_wlast(clr_wlast),
        .b_wvalid(clr_wvalid), .b_wready(clr_wready),
        .b_bvalid(clr_bvalid), .b_bresp(clr_bresp), .b_bready(clr_bready),
        /* 顶层写口（本模块端口表**没有变**：仍是同一组 m_axi_aw/w/b） */
        .m_awaddr(mrg_awaddr), .m_awlen(mrg_awlen), .m_awsize(mrg_awsize),
        .m_awburst(mrg_awburst), .m_awid(), .m_awvalid(mrg_awvalid), .m_awready(mrg_awready),
        .m_wdata(mrg_wdata), .m_wstrb(mrg_wstrb), .m_wlast(mrg_wlast),
        .m_wvalid(mrg_wvalid), .m_wready(mrg_wready),
        .m_bvalid(mrg_bvalid), .m_bresp(mrg_bresp), .m_bid(1'b0), .m_bready(mrg_bready)
    );

    assign m_axi_awaddr  = mrg_awaddr;
    assign m_axi_awlen   = mrg_awlen;
    assign m_axi_awsize  = mrg_awsize;
    assign m_axi_awburst = mrg_awburst;
    assign m_axi_awvalid = mrg_awvalid;
    assign mrg_awready    = m_axi_awready;
    assign m_axi_wdata   = mrg_wdata;
    assign m_axi_wstrb   = mrg_wstrb;
    assign m_axi_wlast   = mrg_wlast;
    assign m_axi_wvalid  = mrg_wvalid;
    assign mrg_wready     = m_axi_wready;
    assign mrg_bvalid     = m_axi_bvalid;
    assign mrg_bresp      = m_axi_bresp;
    assign m_axi_bready  = mrg_bready;

    /* ---------------- ★v2.11 显示列表取指器（DFU，S2） ----------------
     * 只做三件事：从 DDR 取 16B 描述符 → 展开成现有 8 字命令 → 推进现有 cmd_fifo。
     * 引擎 FSM / 像素通路 / 地址生成 / 写主机 / 扫描输出一行未改（I1）。
     * 描述符读复用 axi_rd_master 的 desc 流（tag=2'b10），不新增 AXI 端口。
     * `-DDL_OFF`：整个模块不例化，dl_cmd_req 恒 0、desc 口恒闲 ⇒ 与 S1 之后
     *   的行为逐位一致（A/B 逃生门，见设计文档 §12）。 */
`ifdef DL_OFF
    assign dl_cmd_req  = 1'b0;
    assign dl_cmd_data = 32'd0;
    assign dl_cmd_last = 1'b0;
    assign dl_desc_req = 1'b0;
    assign dl_desc_addr= 32'd0;
    assign dl_desc_len = 8'd0;
    assign dl_busy     = 1'b0;
    assign dl_done     = 1'b0;
    assign dl_err      = 1'b0;
    assign dl_aborted  = 1'b0;
    assign dl_stall    = 1'b0;
    assign dl_consumed = 16'd0;
    assign dl_active_buf = 2'd0;
    assign dl_err_word = 32'd0;
    assign dl_fault_addr = 32'd0;
    assign dl_perf     = 32'd0;
    assign dl_auto_go_hold = 1'b0;
`else
    dl_fetch #(.DESC_DEPTH(16)) u_dl (
        .clk(clk), .rst_n(int_rst_n),
        .cfg_base0(dl_base0), .cfg_base1(dl_base1), .cfg_count(dl_count),
        .cfg_buf_sel(dl_buf_sel), .cfg_auto_go(dl_auto_go), .cfg_strict(dl_strict),
        .cfg_geom_base(dl_geom_base), .cfg_geom_max(dl_geom_max),
        .cfg_dst_base(dl_dst_base), .cfg_dst_stride(dl_dst_stride),
        .cfg_fb_w(dl_fb_w), .cfg_fb_h(dl_fb_h),
        .cfg_chunk(dl_cfg_chunk), .cfg_wm(dl_cfg_wm),
        .cfg_prefetch(dl_cfg_prefetch), .cfg_gec(dl_cfg_gec),
        .cfg_timeout(dl_timeout),
        .go_pulse(dl_go_pulse), .abort_pulse(dl_abort_pulse),
        .err_clr_pulse(dl_err_clr_pulse), .err_clr_mask(dl_err_clr_mask),
        .list_rewr_pulse(dl_list_rewr_pulse), .base_align_err(dl_base_align_err),
        .desc_req(dl_desc_req), .desc_addr(dl_desc_addr), .desc_len(dl_desc_len),
        .desc_ready(dl_desc_ready), .desc_rvalid(rd_desc_rvalid),
        .desc_rdata(rd_data), .desc_rresp(rd_rresp), .desc_rready(),
        .dl_cmd_req(dl_cmd_req), .dl_cmd_data(dl_cmd_data),
        .dl_cmd_last(dl_cmd_last), .dl_cmd_gnt(dl_cmd_gnt),
        .eng_done(eng_done), .rd_busy(rd_busy),
        .busy(dl_busy), .done(dl_done), .err(dl_err), .aborted(dl_aborted),
        .stall(dl_stall), .consumed(dl_consumed), .active_buf(dl_active_buf),
        .err_word(dl_err_word), .fault_addr(dl_fault_addr),
        .perf_cycles(dl_perf), .auto_go_hold(dl_auto_go_hold)
    );
`endif

    /* ---------------- 引擎 FSM ---------------- */
    blt_engine_fsm u_eng (
        .clk(clk), .rst_n(int_rst_n),
        .go(eng_go), .err_out(eng_err), .done_out(eng_done),
        .busy_out(eng_busy),
        .cmd_wcount(cmd_wcount), .cmd_empty(cmd_empty), .cmd_dout(cmd_dout), .cmd_pop(cmd_pop),
        .fg_empty(fg_empty), .bg_empty(bg_empty),
        .fg_drain(fg_rd_eng), .bg_drain(bg_rd_eng),
        .wd_empty(wd_empty), .wd_busy(wd_busy),
        .wr_commit_idle(wr_commit_idle),
        .wr_cmd_end(wr_cmd_end),
        .pp_start(pp_start), .pp_busy(pp_busy), .pp_row_done(pp_row_done),
        .pp_op(pp_op), .pp_width(pp_width),
        .pp_dbase(pp_dbase), .pp_dlane0(pp_dlane0),
        .pp_fskip(pp_fskip), .pp_bskip(pp_bskip),
        .pp_alpha(pp_alpha), .pp_color(pp_color), .pp_key(pp_key),
        /* ★S5：属性侧口（FIFO 空 ⇒ 引擎用默认字）+ 本命令的属性/混合标志 + scissor */
        .attr_dout(attr_dout), .attr_empty(attr_empty), .attr_pop(attr_pop),
        .pp_attr(pp_attr), .pp_blend(pp_blend),
        .clip_x0(clip_x0), .clip_x1(clip_x1), .clip_y0(clip_y0), .clip_y1(clip_y1),
        .clip_en(clip_en),
        .rd_req(rd_req), .rd_addr(rd_addr), .rd_len(rd_len), .rd_bg(rd_bg),
        .rd_ready(rd_ready), .rd_busy(rd_busy), .rd_done(rd_done), .rd_tag(rd_tag[0]),
        .dbg_opword(dbg_op), .perf_cycles(perf)
    );
endmodule
