/* =========================================================================
 * tb_perf_probe.v — 2D BitBlt 引擎「像素吞吐瓶颈定位」只读诊断台
 * -------------------------------------------------------------------------
 * 纪律：本文件**只观察**。不驱动任何内部信号、不改任何 RTL/寄存器图/FSM，
 *       也不进 run_regress.ps1（诊断台，不是 pass/fail 测试）。
 *       所有内部量一律通过层次引用读取（u_blt.u_path.* / u_blt.u_eng.* /
 *       u_blt.u_wr.* / u_blt.u_fgr.* ...）。仿真无综合优化，层次探测安全。
 *
 * 复用的既有资产（不另写内存模型）：
 *   · 夹具 / 寄存器序列 / 命令格式 / 周期测量  = rtl/tb/tb_blt_top.v
 *   · 存储模型                                  = rtl/tb/axi_slave_mem.v
 *     （同一个模块；只把 MEM_BYTES 放大到 1<<22 以容纳 960x540 帧缓冲，
 *       AR_LAT=20 / B_LAT=2 / MAXO=4 与 tb_blt_top 完全一致）
 *
 * 编译/运行（在仓库根目录；与 run_regress.ps1 同一套工具与 flag）：
 *   $env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
 *   iverilog -g2001 -s tb_perf_probe -o sim_tb_perf_probe.vvp `
 *     rtl/sync_fifo.v rtl/cmd_fifo.v rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v `
 *     rtl/axi_rd_master.v rtl/axi_wr_master.v rtl/stream_reader.v rtl/pixel_path.v `
 *     rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v rtl/clr_engine.v rtl/blt_top.v `
 *     rtl/tb/axi_slave_mem.v rtl/tb/tb_perf_probe.v
 *   vvp sim_tb_perf_probe.vvp
 *
 * 直方图口径（每个周期恰好落进一个类别，互斥且完备）：
 *   窗口 = 引擎非 IDLE 的周期（= 引擎 PERF 寄存器 0x1C 的口径，可上板对照）
 *   像素类优先，其次冲刷类，其次数据等待类，最后才是 FSM 开销类。
 *   hist 求和 == PERF 寄存器值（TB 会打印 delta 做对账）。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_perf_probe;

    /* ================= 时钟 / 复位 ================= */
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    /* ================= 地址布局（真实存储只有 32KB = 0x0000..0x7FFF） ================= */
    localparam [31:0] FB_SRC = 32'h0000_0000;   // 960x540 源, stride 1920
    localparam [31:0] FB_DST = 32'h0000_4000;   // 960x540 目的, stride 1920
    localparam [31:0] SM_SRC = 32'h0000_6000;   // 32x32 紧排, stride 64（在 32KB 内，数据是真的）
    localparam [31:0] SM_DST = 32'h0000_6800;
    localparam [31:0] STRIDE_FB = 32'd1920;
    localparam [31:0] STRIDE_SM = 32'd64;

    /* ================= AXI-Lite 主测口（同 tb_blt_top） ================= */
    reg  [11:0] awaddr = 0, araddr = 0;
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] wdata = 0;
    reg  [3:0]  wstrb = 4'hF;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [31:0] rdata;
    reg         bready = 1, rready = 1;

    /* ================= 引擎 AXI 主机 ================= */
    wire [31:0] m_araddr, m_awaddr;
    wire [7:0]  m_arlen, m_awlen;
    wire [2:0]  m_arsize, m_awsize;
    wire [1:0]  m_arburst, m_awburst;
    wire        m_arvalid, m_arready, m_rvalid, m_rlast;
    wire [127:0] m_rdata;
    wire        m_awvalid, m_awready, m_wvalid, m_wlast, m_bvalid;
    wire [127:0] m_wdata;
    wire [15:0] m_wstrb;
    wire        m_bready;
    wire        irq_done;

    reg  [1:0]  fb_cur_sel_r = 2'd0;

    blt_top #(.AXI_DATA_W(128), .CMD_DEPTH(256)) u_blt (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb),
        .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bvalid(bvalid), .s_axil_bresp(), .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(), .s_axil_rvalid(rvalid), .s_axil_rready(rready),
        .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arvalid(m_arvalid), .m_axi_arready(m_arready),
        .m_axi_rdata(m_rdata), .m_axi_rresp(), .m_axi_rlast(m_rlast),
        .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready),
        .m_axi_awaddr(m_awaddr), .m_axi_awlen(m_awlen), .m_axi_awsize(m_awsize),
        .m_axi_awburst(m_awburst), .m_axi_awvalid(m_awvalid), .m_axi_awready(m_awready),
        .m_axi_wdata(m_wdata), .m_axi_wstrb(m_wstrb), .m_axi_wlast(m_wlast),
        .m_axi_wvalid(m_wvalid), .m_axi_wready(m_wready),
        .m_axi_bvalid(m_bvalid), .m_axi_bresp(), .m_axi_bready(m_bready),
        .irq_done(irq_done),
        .scan_underrun(16'd0), .scan_abort(16'd0),
        .fb_sel(), .fb_cur_sel(fb_cur_sel_r), .fb_frame_cnt(16'd0), .frame_pulse(1'b0)
    );

    /* 存储模型：与 tb_blt_top **逐参数相同**（含 MEM_BYTES=1<<15）。
     * 说明：iverilog 对大的 mem 数组编译耗时爆炸（实测 1MB 数组 >100s 不收敛，
     * 4MB 更甚），所以不能放大容量。这不影响周期测量：
     *   · 从机的写路径按 WSTRB 生效、地址越界只是**不落盘**，握手时序与地址无关；
     *   · 读路径对越界字返回 0，而本设计里没有"数据相关"的时序
     *     （COPY/ALPHA 的 keep 恒 1；只有 KEY 的 keep 依赖数据，故 KEY 用 32KB 内的
     *      小区域 src，数据是真的）。
     * 因此：960x540 两个整屏算子的**周期数有效**，但只有前 32KB 的数据被真正存储，
     * 数据校验也只在前 32KB 内做。 */
    axi_slave_mem #(.AXI_DATA_W(128), .MEM_BYTES(1 << 15), .AR_LAT(20), .B_LAT(2), .MAXO(4)) u_mem (
        .clk(clk), .rst_n(rst_n),
        .s_araddr(m_araddr), .s_arlen(m_arlen), .s_arsize(m_arsize),
        .s_arburst(m_arburst), .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata(m_rdata), .s_rresp(), .s_rlast(m_rlast),
        .s_rvalid(m_rvalid), .s_rready(m_rready),
        .s_awaddr(m_awaddr), .s_awlen(m_awlen), .s_awsize(m_awsize),
        .s_awburst(m_awburst), .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata), .s_wstrb(m_wstrb), .s_wlast(m_wlast),
        .s_wvalid(m_wvalid), .s_wready(m_wready),
        .s_bvalid(m_bvalid), .s_bresp(), .s_bready(m_bready)
    );

    /* ================= 层次探测别名（只读） ================= */
    wire        eng_active  = (u_blt.u_eng.st != 3'd0);
    wire [2:0]  eng_st      = u_blt.u_eng.st;
    wire [1:0]  eng_rs      = u_blt.u_eng.rstate;
    wire        eng_row0ok  = u_blt.u_eng.row0_ready;
    wire        eng_pprun   = u_blt.u_eng.pp_run;

    wire        pp_run      = (u_blt.u_path.st == 1'b1);
    wire        pp_can      = u_blt.u_path.can_pp;
    wire        pp_core     = u_blt.u_path.core_can;
    wire        pp_flush_p  = u_blt.u_path.flush_p;
    wire        pp_flush_ok = u_blt.u_path.flush_ok;
    wire        pp_aempty   = u_blt.u_path.aempty;
    wire        pp_keep     = u_blt.u_path.keep;
    wire        pp_need_fg  = u_blt.u_path.need_fg;
    wire        pp_need_bg  = u_blt.u_path.need_bg;
    wire [2:0]  pp_lane     = u_blt.u_path.lane;

    wire        fg_rdy      = u_blt.u_path.u_fgr.ready;
    wire        bg_rdy      = u_blt.u_path.u_bgr.ready;
    wire        fg_empty    = u_blt.fg_empty;
    wire        bg_empty    = u_blt.bg_empty;

    wire        wd_full     = u_blt.wd_full;
    wire        wd_busy     = u_blt.wd_busy;
    wire [4:0]  wd_count    = u_blt.wd_count;
    wire [4:0]  b_pending   = u_blt.wr_b_pending;
    wire        rd_busy     = u_blt.u_rd.rd_busy;

    /* ================= 直方图 / 原始计数 ================= */
    localparam NH = 18;
    localparam H_PIX_KEEP    = 0;   // 打包器推进 1 像素（有写入掩码）
    localparam H_PIX_SKIP    = 1;   // 推进 1 像素但 KEY 跳过（不写）
    localparam H_FLUSH_WORD  = 2;   // 冲刷周期且真的提交了一个 16B 词
    localparam H_FLUSH_HOLE  = 3;   // 冲刷周期但整词被键色跳过（不提交）
    localparam H_FLUSH_WDFUL = 4;   // flush_p 已置但 wd FIFO 满 → 冲刷被挡
    localparam H_STALL_FG    = 5;   // 核心可推进但 fg 侧没像素
    localparam H_STALL_BG    = 6;   // 同上，bg 侧
    localparam H_STALL_FGB   = 7;   // 两侧同时没像素（ALPHA）
    localparam H_ENG_POP     = 8;   // FSM：POP 取 8 字
    localparam H_ENG_DEC     = 9;   // FSM：DEC 译码
    localparam H_ENG_INIT    = 10;  // FSM：EXEC/RS_INIT
    localparam H_ENG_WAITD   = 11;  // FSM：EXEC/RS_LOOP 等本行首词（row0_ready=0）
    localparam H_ENG_GAP     = 12;  // FSM：EXEC/RS_LOOP 行间握手空档（含 pp_start 拍）
    localparam H_ENG_DRAIN   = 13;  // FSM：EXEC/RS_DRAIN
    localparam H_ENG_WDWAIT  = 14;  // FSM：WDWAIT 写提交屏障
    localparam H_IDLE_GAP    = 15;  // 引擎 IDLE（背靠背时命令之间那 1 拍）
    localparam H_OTHER_PIX   = 16;  // 像素通路在跑但无类别可归（应恒 0）
    localparam H_OTHER       = 17;  // 其它（应恒 0）

    integer hist [0:NH-1];
    integer win_cycles;        // 引擎非 IDLE 的周期数（== PERF 口径）
    integer idle_gap_cycles;   // run 窗口内引擎 IDLE 的周期数

    /* 原始计数（每 op 清零） */
    integer px_wr;             // 真正带掩码写出的像素（由 wd 词的 mask 统计）
    integer wd_wr_cnt;         // 提交进 wd FIFO 的 16B 词数
    integer aw_top, aw_wr, w_beats, b_cnt;
    integer rows;              // 行完成次数
    integer wd_full_cycles, wd_count_max;
    integer stall_fg_fifo, stall_fg_reload, stall_bg_fifo, stall_bg_reload;
    integer stall_fg_nordbusy; // fg 饿且读主机无在飞（= 根本没预取）
    integer wr_st_hist [0:4];  // 写主机状态分布 S_IDLE/S_BUF/S_AW/S_W/S_B
    integer burst_max, burst_cnt, burst_sum;
    integer run_len, run_max;  // 连续推进像素的最长连击（判断 1 lane / 2 lane）
    integer px_run_cycles;     // 像素通路处于 S_RUN 的周期数
    integer row_cyc, row_cyc_sum, row_cyc_n, row_cyc_max, row_cyc_min;

    integer k, m;
    integer mi;
    reg [15:0] chk;
    reg [15:0] pre_out;

    /* run 窗口标记（供监视器区分"命令之间的 IDLE 空档"） */
    reg       run_active = 1'b0;
    reg       seen_active = 1'b0;
    integer   t_first, t_last;

    task cnt_clear;
        begin
            for (k = 0; k < NH; k = k + 1) hist[k] = 0;
            for (k = 0; k < 5;  k = k + 1) wr_st_hist[k] = 0;
            win_cycles = 0; idle_gap_cycles = 0;
            px_wr = 0; wd_wr_cnt = 0; aw_top = 0; aw_wr = 0; w_beats = 0; b_cnt = 0;
            rows = 0; wd_full_cycles = 0; wd_count_max = 0;
            stall_fg_fifo = 0; stall_fg_reload = 0; stall_bg_fifo = 0; stall_bg_reload = 0;
            stall_fg_nordbusy = 0;
            burst_max = 0; burst_cnt = 0; burst_sum = 0;
            run_len = 0; run_max = 0; px_run_cycles = 0;
            row_cyc = 0; row_cyc_sum = 0; row_cyc_n = 0; row_cyc_max = 0; row_cyc_min = 100000;
        end
    endtask

    /* ---------------- 每周期的互斥分类 ---------------- */
    always @(posedge clk) begin
        if (rst_n) begin
            /* AXI 侧计数（窗口外也数，但每 op 清零） */
            if (m_awvalid && m_awready)              aw_top  = aw_top  + 1;
            if (u_blt.blt_awvalid && u_blt.blt_awready) aw_wr = aw_wr  + 1;
            if (m_wvalid && m_wready)                w_beats = w_beats + 1;
            if (m_bvalid && m_bready)                b_cnt   = b_cnt   + 1;

            /* 行周期统计（含命令之间的空档） */
            if (u_blt.pp_row_done) begin
                rows = rows + 1;
                if (rows > 1) begin
                    row_cyc_sum = row_cyc_sum + row_cyc;
                    row_cyc_n   = row_cyc_n + 1;
                    if (row_cyc > row_cyc_max) row_cyc_max = row_cyc;
                    if (row_cyc < row_cyc_min) row_cyc_min = row_cyc;
                end
                row_cyc = 0;
            end else
                row_cyc = row_cyc + 1;

            /* 16B 词提交：统计掩码里真正写出的像素 */
            if (u_blt.wd_wr) begin
                wd_wr_cnt = wd_wr_cnt + 1;
                for (m = 0; m < 8; m = m + 1)
                    if (u_blt.pp_wd_word[160 + m*2 +: 2] != 2'b00) px_wr = px_wr + 1;
            end

            /* 连续推进像素连击长度 */
            if (pp_can) begin
                run_len = run_len + 1;
                if (run_len > run_max) run_max = run_len;
            end else
                run_len = 0;

            if (pp_run) px_run_cycles = px_run_cycles + 1;

            /* ---------------- 窗口内分类 ---------------- */
            if (eng_active) begin
                win_cycles = win_cycles + 1;

                if (wd_count > wd_count_max) wd_count_max = wd_count;
                if (wd_full) wd_full_cycles = wd_full_cycles + 1;
                wr_st_hist[u_blt.u_wr.st] = wr_st_hist[u_blt.u_wr.st] + 1;
                if (u_blt.blt_awvalid && u_blt.blt_awready) begin
                    burst_cnt = burst_cnt + 1;
                    burst_sum = burst_sum + u_blt.u_wr.burst_len;
                    if (u_blt.u_wr.burst_len > burst_max) burst_max = u_blt.u_wr.burst_len;
                end

                if (pp_can) begin                               /* 1) 推进像素 */
                    if (pp_keep) hist[H_PIX_KEEP] = hist[H_PIX_KEEP] + 1;
                    else         hist[H_PIX_SKIP] = hist[H_PIX_SKIP] + 1;
                end else if (pp_flush_ok) begin                 /* 2) 冲刷周期 */
                    if (pp_aempty) hist[H_FLUSH_HOLE] = hist[H_FLUSH_HOLE] + 1;
                    else           hist[H_FLUSH_WORD] = hist[H_FLUSH_WORD] + 1;
                end else if (pp_flush_p) begin                  /* 3) 冲刷被 wd 满挡 */
                    hist[H_FLUSH_WDFUL] = hist[H_FLUSH_WDFUL] + 1;
                end else if (pp_core) begin                     /* 4) 等 fg/bg 像素 */
                    if (pp_need_fg && !fg_rdy && pp_need_bg && !bg_rdy) begin
                        hist[H_STALL_FGB] = hist[H_STALL_FGB] + 1;
                        if (fg_empty) stall_fg_fifo = stall_fg_fifo + 1;
                        else          stall_fg_reload = stall_fg_reload + 1;
                    end else if (pp_need_fg && !fg_rdy) begin
                        hist[H_STALL_FG] = hist[H_STALL_FG] + 1;
                        if (fg_empty) stall_fg_fifo = stall_fg_fifo + 1;
                        else          stall_fg_reload = stall_fg_reload + 1;
                        if (!rd_busy) stall_fg_nordbusy = stall_fg_nordbusy + 1;
                    end else if (pp_need_bg && !bg_rdy) begin
                        hist[H_STALL_BG] = hist[H_STALL_BG] + 1;
                        if (bg_empty) stall_bg_fifo = stall_bg_fifo + 1;
                        else          stall_bg_reload = stall_bg_reload + 1;
                    end else
                        hist[H_OTHER_PIX] = hist[H_OTHER_PIX] + 1;
                end else begin                                  /* 5) FSM 开销 */
                    case (eng_st)
                        3'd1: hist[H_ENG_POP]    = hist[H_ENG_POP] + 1;
                        3'd4: hist[H_ENG_DEC]    = hist[H_ENG_DEC] + 1;
                        3'd2: begin
                            if (eng_rs == 2'd0)      hist[H_ENG_INIT]  = hist[H_ENG_INIT]  + 1;
                            else if (eng_rs == 2'd2) hist[H_ENG_DRAIN] = hist[H_ENG_DRAIN] + 1;
                            else if (!eng_row0ok)    hist[H_ENG_WAITD] = hist[H_ENG_WAITD] + 1;
                            else                     hist[H_ENG_GAP]   = hist[H_ENG_GAP]   + 1;
                        end
                        3'd3: hist[H_ENG_WDWAIT] = hist[H_ENG_WDWAIT] + 1;
                        default: hist[H_OTHER]   = hist[H_OTHER] + 1;
                    endcase
                end
            end else if (run_active)
                idle_gap_cycles = idle_gap_cycles + 1;
        end
    end

    /* 名称：纯 ASCII 且 ≤ 28 字符（Verilog 字符串入 256bit 寄存器会左截断，
     * 超长或非 ASCII 的名字在日志里会花掉） */
    function [255:0] hname;
        input integer i;
        begin
            case (i)
                H_PIX_KEEP:    hname = "PIX_KEEP";
                H_PIX_SKIP:    hname = "PIX_SKIP_KEY";
                H_FLUSH_WORD:  hname = "FLUSH_WORD_COMMIT";
                H_FLUSH_HOLE:  hname = "FLUSH_HOLE_ALLKEY";
                H_FLUSH_WDFUL: hname = "FLUSH_BLOCKED_WD_FULL";
                H_STALL_FG:    hname = "STALL_FG_NOPIXEL";
                H_STALL_BG:    hname = "STALL_BG_NOPIXEL";
                H_STALL_FGB:   hname = "STALL_FG_BG_NOPIXEL";
                H_ENG_POP:     hname = "ENG_POP_8WORDS";
                H_ENG_DEC:     hname = "ENG_DEC";
                H_ENG_INIT:    hname = "ENG_EXEC_INIT";
                H_ENG_WAITD:   hname = "ENG_WAIT_ROW0";
                H_ENG_GAP:     hname = "ENG_ROW_GAP";
                H_ENG_DRAIN:   hname = "ENG_DRAIN";
                H_ENG_WDWAIT:  hname = "ENG_WDWAIT";
                H_IDLE_GAP:    hname = "IDLE_GAP";
                H_OTHER_PIX:   hname = "OTHER_PIX";
                default:       hname = "OTHER";
            endcase
        end
    endfunction

    /* ================= AXI-Lite 任务（同 tb_blt_top） ================= */
    /* ★S3：当前命令的透明块掩码（w0[31:16] / w0[2]）。默认 0 = 今天的行为。
     * 必须在 push_cmd 之前声明（iverilog 不允许先用后声明）。 */
    reg [15:0] cur_mask = 16'd0;
    reg        cur_mask_en = 1'b0;

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
        input  [11:0] addr;
        output [31:0] rd;
        begin
            araddr = addr; arvalid = 1'b1;
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata;
            #1;
            arvalid = 1'b0;
        end
    endtask

    task poke16;
        input [31:0] a;
        input [15:0] v;
        begin
            u_mem.mem[a]   = v[7:0];
            u_mem.mem[a+1] = v[15:8];
        end
    endtask

    task peek16;
        input  [31:0] a;
        output [15:0] v;
        begin
            v = {u_mem.mem[a+1], u_mem.mem[a]};
        end
    endtask

    /* 极小自检：证明探针确实观察到了一条真实完成的命令 */
    task sanity16;
        input [31:0]  a;
        input [15:0]  exp;
        input [255:0] tag;
        begin
            peek16(a, chk);
            $display("PROBE SANITY %0s @%h exp=%h got=%h %0s",
                     tag, a, exp, chk, (chk === exp) ? "OK" : "MISMATCH");
        end
    endtask

    task eng_init;
        begin
            axi_write(12'h00, 32'h4);
            axi_write(12'h00, 32'h0);
            axi_write(12'h10, 32'hFFFFFFFF);
            axi_write(12'h14, 32'h0);
            axi_write(12'h00, 32'h1);
        end
    endtask

    task push_cmd;
        input [1:0]  op;
        input [31:0] sa, da, ss, ds;
        input [15:0] W, H;
        input [7:0]  alpha;
        input [15:0] color;
        begin
            /* ★S3：掩码走 w0 的空位 —— 布局必须与 dl_fetch 的展开逐位一致：
             *   w0 = {MASK[15:0], 13'd0, MASK_EN, OP[1:0]}（32bit） */
            axi_write(12'h08, {cur_mask, 13'd0, cur_mask_en, op});
            axi_write(12'h08, sa);
            axi_write(12'h08, da);
            axi_write(12'h08, ss);
            axi_write(12'h08, ds);
            axi_write(12'h08, {H, W});
            axi_write(12'h08, {8'd0, alpha});
            axi_write(12'h08, {16'd0, color});
        end
    endtask

    /* ================= 测量 ================= */
    integer t0, t1, perf_reg;
    reg [31:0] rv;
    integer   i, j, rr, cc;

    /* ★v2.11（S2）：16×16 = demo 当前精灵尺寸，用来把"每块命令开销"拆成
     *   (a) CPU 侧下发/喂 FIFO 与 (b) 引擎自身两条。 */
    localparam [31:0] F16_DST    = 32'h0000_7000;   // 16×16 连续 512B（stride 32）
    localparam [31:0] STRIDE_16  = 32'd32;
    integer push_accum, push_t0;

    /* ================= ★v2.12（S3）透明块跳过 A/B 探针 =================
     * 形状与 demo 的 KEY 精灵同构（圆盘：白环 + 渐变内芯 + 键色四角），
     * 4×4 块掩码由 TB 侧按"整块每个像素都是键色"算出来（= 软件侧该做的事）。
     * 掩码通过命令字 w0[31:16]/w0[2] 下发（CPU 路径），所以同一个 run_op 就能
     * 跑 A/B：cur_mask=0 ⇒ 今天的行为；cur_mask=真值 ⇒ 跳过生效。
     * 数据必须是真的（KEY 的 keep 依赖数据），源区放在 32KB 存储内的 SM 区。 */
    localparam [31:0] S3_SRC = 32'h0000_6000;
    localparam [31:0] S3_DST = 32'h0000_6800;
    localparam [31:0] STRIDE_S3 = 32'd64;
    integer    s3_key;

    task gen_disc;                          // 圆盘：d²≤rin 渐变内芯；≤rout 白环；否则键色
        input [15:0] w, h, rin, rout;
        integer x, y, cx, cy; reg [31:0] d; reg [15:0] c;
        begin
            cx = (w - 1) / 2;  cy = (h - 1) / 2;  s3_key = 0;
            for (y = 0; y < h; y = y + 1)
                for (x = 0; x < w; x = x + 1) begin
                    d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
                    if      (d <= rin)  c = 16'h0800 + ((x * 3 + y * 5) & 16'h00FF);
                    else if (d <= rout) c = 16'hFFFF;
                    else begin          c = 16'hF81F;  s3_key = s3_key + 1; end
                    poke16(S3_SRC + y * STRIDE_S3 + x * 2, c);
                end
        end
    endtask

    task calc_mask4;                        // 4×4 块掩码（1 = 整块全键色 ⇒ 可跳）
        input [15:0] w, h; output [15:0] msk;
        integer rt, ct, x, y; reg allkey; reg [15:0] c;
        begin
            msk = 16'd0;
            for (rt = 0; rt < 4; rt = rt + 1)
                for (ct = 0; ct < 4; ct = ct + 1) begin
                    allkey = 1'b1;
                    for (y = (h*rt)/4; y < (h*(rt+1))/4; y = y + 1)
                        for (x = (w*ct)/4; x < (w*(ct+1))/4; x = x + 1) begin
                            peek16(S3_SRC + y*STRIDE_S3 + x*2, c);
                            if (c !== 16'hF81F) allkey = 1'b0;
                        end
                    if (allkey) msk = msk | (16'd1 << (rt*4 + ct));
                end
        end
    endtask

    task init_s3_dst;
        integer r, c;
        begin
            for (r = 0; r < 32; r = r + 1)
                for (c = 0; c < 32; c = c + 1)
                    poke16(S3_DST + r*STRIDE_S3 + c*2, 16'h1000 + ((r*7 + c*13) & 16'h03FF));
        end
    endtask

    /* 一个形状跑 A/B 两种掩码；op 由调用方给，tag 用来区分 */
    task s3_case;
        input [1:0]  op;
        input [15:0] w, h, rin, rout;
        input [7:0]  alpha;
        input [15:0] color;
        input [255:0] tag;
        reg [15:0] msk;
        begin
            gen_disc(w, h, rin, rout);
            calc_mask4(w, h, msk);
            init_s3_dst();
            $display("S3 SHAPE %0s %0dx%0d key_px=%0d mask=0x%04h", tag, w, h, s3_key, msk);
            cur_mask = 16'd0;    cur_mask_en = 1'b0;          // A：无掩码（= 今天的行为）
            run_op(op, S3_SRC, S3_DST, STRIDE_S3, STRIDE_S3, w, h, alpha, color, tag);
            cur_mask = msk;      cur_mask_en = (op == 2'd3);  // B：KEY 才启用（非 KEY 应无效）
            run_op(op, S3_SRC, S3_DST, STRIDE_S3, STRIDE_S3, w, h, alpha, color,
                   {tag, "_MASK"});
            cur_mask = 16'd0;    cur_mask_en = 1'b0;
        end
    endtask

    task wait_push_slot;
        begin
            for (i = 0; (i < 2000000) && u_blt.cmd_full; i = i + 1) @(posedge clk);
        end
    endtask

    task wait_eng_done_poll;
        begin : wedp
            for (i = 0; i < 2000000; i = i + 1) begin
                axi_read(12'h04, rv);
                if (rv & 32'h2) disable wedp;
            end
            $display("PROBE !! DONE timeout");
        end
    endtask

    always @(posedge clk) begin
        if (run_active && eng_active) begin
            if (!seen_active) begin t_first = cyc; seen_active = 1; end
            t_last = cyc;
        end
    end

    /* 单条孤立命令：清计数 → 推命令 → 等 DONE → 读 PERF */
    task run_op;
        input [1:0]   op;
        input [31:0]  sa, da, ss, ds;
        input [15:0]  W, H;
        input [7:0]   alpha;
        input [15:0]  color;
        input [255:0] tag;
        begin
            cnt_clear();
            t_first = 0; t_last = 0; seen_active = 0;
            run_active = 1'b1;
            t0 = cyc;
            push_cmd(op, sa, da, ss, ds, W, H, alpha, color);
            /* 先等引擎真的开工（否则 DONE 还是上一条/复位后的残留电平） */
            for (i = 0; (i < 200000) && (u_blt.u_eng.st == 3'd0); i = i + 1) @(posedge clk);
            begin : waitloop
                for (i = 0; i < 20000000; i = i + 1) begin
                    axi_read(12'h04, rv);
                    if (rv & 32'h2) disable waitloop;
                    if (rv & 32'h4) begin
                        $display("PROBE !! engine ERR during %0s", tag);
                        disable waitloop;
                    end
                end
                $display("PROBE !! DONE timeout %0s", tag);
            end
            t1 = cyc;
            run_active = 1'b0;
            axi_read(12'h1C, perf_reg);
            print_op(tag, op, W, H, perf_reg, t1 - t0);
        end
    endtask

    /* 背靠背 nblk 条同尺寸 FILL/COPY/ALPHA：整批一次测量 */
    task run_b2b;
        input [1:0]   op;
        input [31:0]  sa, da, ss, ds;
        input [15:0]  W, H;
        input [7:0]   alpha;
        input [15:0]  color;
        input integer nblk;
        input [255:0] tag;
        begin
            cnt_clear();
            t_first = 0; t_last = 0; seen_active = 0;
            run_active = 1'b1;
            t0 = cyc;
            for (j = 0; j < nblk; j = j + 1)
                push_cmd(op, sa, da, ss, ds, W, H, alpha, color);
            /* 等：引擎 IDLE + 指令 FIFO 空 + wd FIFO 空 */
            while (!((u_blt.u_eng.st == 3'd0) &&
                     (u_blt.u_cmd.word_count == 12'd0) &&
                     (u_blt.wd_count == 5'd0))) @(posedge clk);
            t1 = cyc;
            run_active = 1'b0;
            axi_read(12'h1C, perf_reg);
            print_b2b(tag, op, W, H, nblk, perf_reg, t1 - t0);
        end
    endtask

    /* ---------------- 打印 ---------------- */
    integer hs, gsum;
    integer kk;

    task print_hist;
        input [255:0] tag;
        begin
            hs = 0;
            for (kk = 0; kk < NH; kk = kk + 1) hs = hs + hist[kk];
            $display("PROBE HIST-BEGIN %0s  active=%0d hist_sum=%0d", tag, win_cycles, hs);
            for (kk = 0; kk < NH; kk = kk + 1)
                if (hist[kk] != 0)
                    $display("PROBE HIST %0s | %0s | %8d | %6.2f%%",
                             tag, hname(kk), hist[kk],
                             (win_cycles > 0) ? (100.0 * hist[kk] / win_cycles) : 0.0);
            $display("PROBE HIST-END %0s  sum_delta_vs_active=%0d", tag, hs - win_cycles);
        end
    endtask

    task print_op;
        input [255:0] tag;
        input [1:0]   op;
        input [15:0]  W, H;
        input integer perfc, wall;
        begin
            gsum = 0;
            for (kk = 0; kk < NH; kk = kk + 1) gsum = gsum + hist[kk];
            $display("PROBE OP %0s op=%0d %0dx%0d | perf=%0d wall=%0d active=%0d idle_gap=%0d hist_sum=%0d delta=%0d",
                     tag, op, W, H, perfc, wall, win_cycles, idle_gap_cycles, gsum, perfc - gsum);
            $display("PROBE OPSUM %0s | px_cons=%0d px_written=%0d words16B=%0d AW_top=%0d AW_wr=%0d Wbeats=%0d B=%0d rows=%0d",
                     tag, hist[H_PIX_KEEP] + hist[H_PIX_SKIP], px_wr, wd_wr_cnt,
                     aw_top, aw_wr, w_beats, b_cnt, rows);
            $display("PROBE OPRATE %0s | cyc/px=%f px/cyc=%f | max_px_run=%0d px_run_cyc=%0d flush_word=%0d flush_hole=%0d flush_wdful=%0d | wd_full_cyc=%0d wd_peak=%0d burst_max=%0d burst_avg=%f | row_cyc_min=%0d avg=%f max=%0d",
                     tag,
                     (px_wr > 0) ? (1.0 * win_cycles / px_wr) : 0.0,
                     (win_cycles > 0) ? (1.0 * px_wr / win_cycles) : 0.0,
                     run_max, px_run_cycles,
                     hist[H_FLUSH_WORD], hist[H_FLUSH_HOLE], hist[H_FLUSH_WDFUL],
                     wd_full_cycles, wd_count_max, burst_max,
                     (burst_cnt > 0) ? (1.0 * burst_sum / burst_cnt) : 0.0,
                     (row_cyc_min == 100000) ? 0 : row_cyc_min,
                     (row_cyc_n > 0) ? (1.0 * row_cyc_sum / row_cyc_n) : 0.0,
                     row_cyc_max);
            $display("PROBE OPDATA %0s | stall_fg_fifo=%0d stall_fg_reload=%0d stall_fg_nordbusy=%0d stall_bg_fifo=%0d stall_bg_reload=%0d | wrst_idle=%0d buf=%0d AW=%0d W=%0d B=%0d",
                     tag, stall_fg_fifo, stall_fg_reload, stall_fg_nordbusy,
                     stall_bg_fifo, stall_bg_reload,
                     wr_st_hist[0], wr_st_hist[1], wr_st_hist[2], wr_st_hist[3], wr_st_hist[4]);
            $display("PROBE TABLE %0s | %0d | %0d | %f | %0d | %0d",
                     tag, perfc, px_wr,
                     (px_wr > 0) ? (1.0 * perfc / px_wr) : 0.0, wd_wr_cnt, aw_top);
        end
    endtask

    task print_b2b;
        input [255:0] tag;
        input [1:0]   op;
        input [15:0]  W, H;
        input integer nblk;
        input integer perfc, wall;
        begin
            gsum = 0;
            for (kk = 0; kk < NH; kk = kk + 1) gsum = gsum + hist[kk];
            $display("PROBE B2B %0s op=%0d %0dx%0d x%0d | wall=%0d active(hist_sum)=%0d sumPERF=%0d idle_gap=%0d eng_window=%0d inter_gap=%0d",
                     tag, op, W, H, nblk, wall, gsum, perfc, idle_gap_cycles,
                     t_last - t_first + 1, (t_last - t_first + 1) - gsum);
            $display("PROBE B2BSUM %0s | px_written_total=%0d px_per_blk=%f words=%0d AW_top=%0d AW/blk=%f",
                     tag, px_wr, (1.0 * px_wr / nblk), wd_wr_cnt, aw_top, (1.0 * aw_top / nblk));
            $display("PROBE TABLE_B2B %0s | %0d | %0d | %f | %0d | %0d",
                     tag, gsum / nblk, px_wr / nblk,
                     (px_wr > 0) ? (1.0 * gsum / px_wr) : 0.0, wd_wr_cnt / nblk, aw_top / nblk);
            print_hist(tag);
        end
    endtask

    /* 32x32 小区域数据（在 32KB 真实存储内，KEY 的 keep 依赖它 → 必须是真数据） */
    task init_sm;
        begin
            for (rr = 0; rr < 32; rr = rr + 1)
                for (cc = 0; cc < 32; cc = cc + 1) begin
                    if (rr == 0 || (cc % 4) == 0) poke16(SM_SRC + rr*64 + cc*2, 16'hF81F);
                    else                          poke16(SM_SRC + rr*64 + cc*2, 16'hF800 + cc[4:0]);
                    poke16(SM_DST + rr*64 + cc*2, 16'h0010);
                end
        end
    endtask

    /* ================= 主流程 ================= */
    initial begin
        run_active = 0; seen_active = 0; t_first = 0; t_last = 0;
        perf_reg = 0;

        #20 rst_n = 1'b1;

        /* --- 预置数据（只写 TB 自己的存储模型，不动 RTL） --- */
        for (mi = 0; mi < 32768; mi = mi + 1)       /* 真实存储只有 32KB */
            u_mem.mem[mi] = mi[7:0] ^ mi[15:8];
        init_sm();

        eng_init();
        /* ---------------- 1) 960x540 FILL（整屏） ---------------- */
        $display("PROBE ==== T1 960x540 FILL (whole screen) ====");
        run_op(2'd1, 0, FB_DST, 0, STRIDE_FB, 16'd960, 16'd540, 8'hFF, 16'hF800, "T1_960x540_FILL");
        print_hist("T1_960x540_FILL");
        sanity16(FB_DST, 16'hF800, "T1_first_px");
        sanity16(FB_DST + 32'd16382, 16'hF800, "T1_last_stored_px(0x7FFE)");

        /* ---------------- 2) 960x540 COPY（整屏） ---------------- */
        $display("PROBE ==== T2 960x540 COPY (whole screen) ====");
        run_op(2'd0, FB_SRC, FB_DST, STRIDE_FB, STRIDE_FB, 16'd960, 16'd540, 8'hFF, 16'd0, "T2_960x540_COPY");
        print_hist("T2_960x540_COPY");

        /* ---------------- 3) 32x32 FILL 孤立（紧排 stride 64） ----------------
         * 注：整屏 T1/T2 的目的区在"只有 32KB"的模型里会覆盖 32x32 小区域，
         * 所以这里重新预置一次（数据真实、KEY 的 keep 才可信）。 */
        init_sm();
        peek16(SM_DST + 32'd2048, pre_out);
        $display("PROBE ==== T3 32x32 FILL isolated (tight stride 64) ====");
        run_op(2'd1, 0, SM_DST, 0, STRIDE_SM, 16'd32, 16'd32, 8'hFF, 16'h07E0, "T3_32x32_FILL");
        print_hist("T3_32x32_FILL");
        sanity16(SM_DST, 16'h07E0, "T3_first_px");
        sanity16(SM_DST + 32'd2046, 16'h07E0, "T3_last_px");
        peek16(SM_DST + 32'd2048, chk);
        $display("PROBE SANITY T3_outside_untouched pre=%h post=%h %0s",
                 pre_out, chk, (chk === pre_out) ? "OK" : "MISMATCH");

        /* ---------------- 4) 32x32 COPY 孤立 ---------------- */
        $display("PROBE ==== T4 32x32 COPY isolated ====");
        run_op(2'd0, SM_SRC, SM_DST, STRIDE_SM, STRIDE_SM, 16'd32, 16'd32, 8'hFF, 16'd0, "T4_32x32_COPY");
        print_hist("T4_32x32_COPY");
        sanity16(SM_DST + 32'd66, 16'hF801, "T4_copy_row1_px1");

        /* ---------------- 5) 32x32 ALPHA 孤立 ---------------- */
        $display("PROBE ==== T5 32x32 ALPHA isolated ====");
        run_op(2'd2, SM_SRC, SM_DST, STRIDE_SM, STRIDE_SM, 16'd32, 16'd32, 8'd128, 16'd0, "T5_32x32_ALPHA");
        print_hist("T5_32x32_ALPHA");

        /* ---------------- 6) 32x32 KEY 孤立 ---------------- */
        $display("PROBE ==== T6 32x32 KEY isolated ====");
        run_op(2'd3, SM_SRC, SM_DST, STRIDE_SM, STRIDE_SM, 16'd32, 16'd32, 8'hFF, 16'hF81F, "T6_32x32_KEY");
        print_hist("T6_32x32_KEY");
        $display("PROBE KEYCHK words=%0d (expect 124: 128-4 all-key words) px_written=%0d px_skipped=%0d (expect 311: 280 key + 31 accidental 0xF81F at cc=31)",
                 wd_wr_cnt, px_wr, hist[H_PIX_SKIP]);

        /* ---------------- 7) 32x32 FILL 孤立 @ 真实帧缓冲 stride 1920 ---------------- */
        $display("PROBE ==== T7 32x32 FILL isolated @ framebuffer stride 1920 ====");
        run_op(2'd1, 0, FB_DST + 32'd64, 0, STRIDE_FB, 16'd32, 16'd32, 8'hFF, 16'h001F, "T7_32x32_FILL_FBstride");
        print_hist("T7_32x32_FILL_FBstride");

        /* ---------------- 8) 64 x 32x32 FILL 背靠背（紧排） ---------------- */
        $display("PROBE ==== T8 64x back-to-back 32x32 FILL (tight) ====");
        run_b2b(2'd1, 0, SM_DST, 0, STRIDE_SM, 16'd32, 16'd32, 8'hFF, 16'h07E0, 64, "T8_B2B64_32x32_FILL");

        /* ---------------- 9) 32 x 32x32 FILL 背靠背 @ FB stride ---------------- */
        $display("PROBE ==== T9 32x back-to-back 32x32 FILL @ FB stride ====");
        run_b2b(2'd1, 0, FB_DST + 32'd64, 0, STRIDE_FB, 16'd32, 16'd32, 8'hFF, 16'h001F, 32, "T9_B2B32_32x32_FILL_FB");

        /* ---------------- 10) 16 x 32x32 ALPHA 背靠背 ---------------- */
        $display("PROBE ==== T10 16x back-to-back 32x32 ALPHA (tight) ====");
        run_b2b(2'd2, SM_SRC, SM_DST, STRIDE_SM, STRIDE_SM, 16'd32, 16'd32, 8'd128, 16'd0, 16, "T10_B2B16_32x32_ALPHA");

        /* ================= ★v2.11（S2）16×16 每块开销拆分 =================
         * 三种下发口径，同一批 16×16 FILL（demo 当前精灵尺寸）：
         *   T11  孤立一条 + 直方图            → 引擎自身每块的桶分布
         *   T12a GO=0 先灌 32 条（FIFO 吃得住）→ **纯 CPU 侧下发成本**（无引擎）
         *   T12b 灌满后 GO，32 条背靠背        → 下发与执行重叠后的每块墙钟
         *   T12c push 一条 → 等它跑完 → 再 push → CPU 存储延迟全额暴露的每块墙钟
         * (a) = T12c − T12b（CPU 侧那部分），(b) = T12b（引擎自身的地板） */
        $display("PROBE ==== T11 16x16 FILL isolated (demo sprite size) ====");
        run_op(2'd1, 0, F16_DST, 0, STRIDE_16, 16'd16, 16'd16, 8'hFF, 16'hF800, "T11_16x16_FILL");
        print_hist("T11_16x16_FILL");

        $display("PROBE ==== T12a CPU 纯下发 32 条（GO=0，FIFO 吃下，引擎不跑） ====");
        axi_write(12'h00, 32'h0);                    // GO=0
        cnt_clear();
        t0 = cyc; push_accum = 0;
        for (j = 0; j < 32; j = j + 1) begin
            wait_push_slot();
            push_t0 = cyc;
            push_cmd(2'd1, 0, F16_DST, 0, STRIDE_16, 16'd16, 16'd16, 8'hFF, 16'hF800);
            push_accum = push_accum + (cyc - push_t0);
        end
        t1 = cyc;
        $display("PROBE PUSH T12a_PUSHONLY_32 | wall=%0d push=%0d | per_cmd=%f (纯 CPU 侧，1 读 COUNT + 8 写 DATA)",
                 t1-t0, push_accum, (1.0*push_accum)/32.0);
        axi_write(12'h00, 32'h1);                    // GO=1，把这 32 条放掉
        wait_eng_done_poll();

        $display("PROBE ==== T12b 32 条背靠背（下发与执行重叠） ====");
        run_b2b(2'd1, 0, F16_DST, 0, STRIDE_16, 16'd16, 16'd16, 8'hFF, 16'hF800, 32, "T12b_B2B32_16x16_FILL");

        $display("PROBE ==== T12c 32 条串行（push 一条等一条，CPU 延迟全额暴露） ====");
        axi_write(12'h00, 32'h1);
        cnt_clear();
        run_active = 1'b1; seen_active = 0;
        t0 = cyc; push_accum = 0;
        for (j = 0; j < 32; j = j + 1) begin
            wait_push_slot();
            push_t0 = cyc;
            push_cmd(2'd1, 0, F16_DST, 0, STRIDE_16, 16'd16, 16'd16, 8'hFF, 16'hF800);
            push_accum = push_accum + (cyc - push_t0);
            wait_eng_done_poll();
        end
        t1 = cyc;
        run_active = 1'b0;
        $display("PROBE PUSH T12c_SERIAL_32 | wall=%0d push=%0d | per_cmd_wall=%f",
                 t1-t0, push_accum, (1.0*(t1-t0))/32.0);
        print_hist("T12c_SERIAL_32");

        /* ================= ★v2.12（S3）透明块跳过 A/B =================
         * 每个形状先跑"无掩码"（今天的行为），再跑"带掩码"（KEY 才启用）。
         * 形状定义（与 demo 的 KEY 精灵同构，逐像素可复现）：
         *   demo 球 16×16：d²≤36 渐变内芯 / ≤64 白环 / 其余键色 ⇒ 键色 61/256
         *   demo 球 32×32：同上放大 2×（≤144 / ≤256）
         *   典型弹 16×16：d²≤36 实心（键色 143/256）
         *   典型弹 32×32：d²≤121 实心（键色 647/1024）
         *   小弹   32×32：d²≤49 实心（上下两条行带整带透明）
         * FILL 作对照：掩码对 FILL/ALPHA 必须**完全无效**。 */
        $display("PROBE ==== T13 S3 KEY/ALPHA/FILL 掩码 A/B ====");
        axi_write(12'h00, 32'h1);
        $display("PROBE ---- T13a 16x16 demo 球（键色 61/256，四角小块都不满一整块）----");
        s3_case(2'd3, 16'd16, 16'd16, 16'd36, 16'd64, 8'hFF, 16'hF81F, "T13a_KEY_16_demo");
        s3_case(2'd2, 16'd16, 16'd16, 16'd36, 16'd64, 8'h80, 16'd0,    "T13b_ALPHA_16_demo");
        s3_case(2'd1, 16'd16, 16'd16, 16'd36, 16'd64, 8'hFF, 16'hF800, "T13c_FILL_16_demo");
        $display("PROBE ---- T14a 32x32 demo 球（键色 229/1024）----");
        s3_case(2'd3, 16'd32, 16'd32, 16'd144, 16'd256, 8'hFF, 16'hF81F, "T14a_KEY_32_demo");
        s3_case(2'd2, 16'd32, 16'd32, 16'd144, 16'd256, 8'h80, 16'd0,    "T14b_ALPHA_32_demo");
        $display("PROBE ---- T15a 16x16 典型弹幕弹（键色 143/256）----");
        s3_case(2'd3, 16'd16, 16'd16, 16'd36, 16'd36, 8'hFF, 16'hF81F, "T15a_KEY_16_bullet");
        s3_case(2'd2, 16'd16, 16'd16, 16'd36, 16'd36, 8'h80, 16'd0,    "T15b_ALPHA_16_bullet");
        $display("PROBE ---- T16a 32x32 典型弹幕弹（键色 647/1024）----");
        s3_case(2'd3, 16'd32, 16'd32, 16'd121, 16'd121, 8'hFF, 16'hF81F, "T16a_KEY_32_bullet");
        $display("PROBE ---- T17a 32x32 小弹（键色 875/1024，上下整带透明）----");
        s3_case(2'd3, 16'd32, 16'd32, 16'd49, 16'd49, 8'hFF, 16'hF81F, "T17a_KEY_32_small");
        s3_case(2'd2, 16'd32, 16'd32, 16'd49, 16'd49, 8'h80, 16'd0,     "T17b_ALPHA_32_small");

        $display("PROBE ==== DONE ====");
        $finish;
    end

    /* 看门狗 */
    initial begin
        #400_000_000;
        $display("PROBE !!!! WATCHDOG TIMEOUT !!!!");
        $finish;
    end
endmodule
