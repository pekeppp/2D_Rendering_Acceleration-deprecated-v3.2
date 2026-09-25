/* =========================================================================
 * tb_scanout_bw.v — 扫描输出在"DDR 带宽被引擎抢占"下的**欠载(underrun)**复现
 * -------------------------------------------------------------------------
 * 背景（板级现象）：引擎真正跑起来之后，画面左侧出现"三角形黑色区域、
 * 由上到下往复扫过"。怀疑是 fb_scanout 的行缓冲取数**赶不上显示行**，
 * 显示侧对未就绪的行输出黑（win_d1 = win_now && buf_ok），于是每行**左侧**
 * 出现一段黑；由于取数 FSM 是串行的，一行迟到会让下一行更迟 → 黑区逐行变宽
 * = 三角形。
 *
 * 本 TB 的关键：**保持真实的"取数时间 / 显示行时间"比例**。
 *   真实 1080p：行时间 2200 pclk @148.75MHz = 14.81us = 1481 core 周期(@100MHz)
 *               取一行(960px=120 拍, 每拍 9 core 周期) = 1080 core 周期
 *               → 取数占 73%，只剩 27%(≈400 周期) 的余量
 *   本 TB：FB 128px = 16 拍 → 取一行 = 16*9 = 144 core 周期
 *          显示行 = 160 pclk * 12.5ns = 2000ns = 200 core 周期  → 占 72% ✓
 *   （旧的 tb_fb_scanout 用 19.2us/行 vs 9.6us 取数 = 50% 余量，比例宽松 3.7 倍，
 *     所以它永远测不出这个问题 —— 不是 RTL 没问题，是 TB 时序不真实。）
 *
 * 拓扑 = 板级真实拓扑：扫描输出与"引擎读主机"经两级 axi_rd_arb 共享 DDR 读口。
 * 三个阶段：
 *   P1 引擎空闲            → 期望 0 欠载像素（基线）
 *   P2 引擎满速读 + DDR 周期忙(模拟写突发占口) → 期望出现欠载（复现现象）
 *   P3 引擎停止            → 期望恢复 0（说明是竞争导致，不是逻辑错）
 * 同时打印忙碌期每行的欠载像素数 → 应看到**逐行变宽的楔形**（三角形）。
 * ========================================================================= */
`timescale 1ns/1ps

/* ------------------------------------------------------------------ *
 * 行为模型：DDR AXI 读从机（AR 队列 4 深 + 周期 busy 窗口）
 * busy=1 表示读通道被写突发占用，这一拍不返回数据（模拟 DDR 读写转向）。
 * ------------------------------------------------------------------ */
module ddr_rd_slave #(
    parameter AW = 28, DW = 128, IDW = 4, QD = 8
)(
    input  wire            clk,
    input  wire            rst_n,
    input  wire [AW-1:0]   araddr,
    input  wire [7:0]      arlen,
    input  wire            arvalid,
    output wire            arready,
    output wire [DW-1:0]   rdata,
    output wire            rlast,
    output wire            rvalid,
    input  wire            rready,
    input  wire            busy
);
    reg [AW-1:0] qa [0:15];          /* 指针是 4 位 → 数组必须 16 深（QD 只是"满"阈值） */
    reg [7:0]    ql [0:15];
    reg [3:0]    q_cnt, q_head, q_tail;

    reg [AW-1:0] cur_a;
    reg [7:0]    cur_l, cur_b;
    reg          cur_go;
    reg [3:0]    lat;
    reg [1:0]    pace;

    reg [DW-1:0] rdata_r;
    reg          rvalid_r, rlast_r;

    assign arready = (q_cnt < QD[3:0]);
    assign rdata   = rdata_r;
    assign rvalid  = rvalid_r;
    assign rlast   = rlast_r;

    /* 数据内容：非零伪随机，便于确认数据真的取到了 */
    function [DW-1:0] beat_of;
        input [AW-1:0] a;
        integer b;
        reg [15:0] p;
        begin
            beat_of = {DW{1'b0}};
            for (b = 0; b < (DW/16); b = b + 1) begin
                p = 16'h0800 | ((a[15:1] + b) & 16'h07FF);
                beat_of[b*16 +: 16] = p;
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_cnt <= 4'd0; q_head <= 4'd0; q_tail <= 4'd0;
            cur_go <= 1'b0; cur_l <= 8'd0; cur_b <= 8'd0; cur_a <= {AW{1'b0}};
            lat <= 4'd0; pace <= 2'd0;
            rvalid_r <= 1'b0; rlast_r <= 1'b0; rdata_r <= {DW{1'b0}};
        end else begin
            /* AR 入队（q_cnt 一次算清：入队 +1 / 完成 -1） */
            if (arvalid && arready) begin
                qa[q_tail] <= araddr;
                ql[q_tail] <= arlen;
                q_tail     <= q_tail + 4'd1;
            end
            q_cnt <= q_cnt + ((arvalid && arready) ? 4'd1 : 4'd0)
                           - ((rvalid_r && rready && cur_go && (cur_b == cur_l)) ? 4'd1 : 4'd0);

            /* 取新突发（q_cnt==0 且本拍正在入队第 1 笔时必须等一拍，数组写是寄存的） */
            if (!cur_go && (q_cnt != 4'd0) && !(arvalid && arready && (q_cnt == 4'd0))) begin
                cur_a  <= qa[q_head];
                cur_l  <= ql[q_head];
                cur_b  <= 8'd0;
                cur_go <= 1'b1;
                lat    <= 4'd10;                 /* DDR 读延迟 */
                q_head <= q_head + 4'd1;
                rvalid_r <= 1'b0;
            end else if (cur_go) begin
                if (rvalid_r && rready) begin
                    rvalid_r <= 1'b0;
                    if (cur_b == cur_l)
                        cur_go <= 1'b0;
                    else
                        cur_b <= cur_b + 8'd1;
                end else if (!rvalid_r) begin
                    if (lat != 4'd0)
                        lat <= lat - 4'd1;
                    else if (!busy) begin
                        rdata_r  <= beat_of(cur_a + {16'd0, cur_b, 4'd0});
                        rlast_r  <= (cur_b == cur_l);
                        rvalid_r <= 1'b1;
                    end
                end
            end
        end
    end
endmodule

/* ------------------------------------------------------------------ *
 * 行为模型：引擎读主机（4 笔在飞、16 拍突发背靠背、连续不断）
 * 对应 axi_rd_master 的 credit=4 + 行级重叠突发流水。
 * ------------------------------------------------------------------ */
module blt_rd_gen #(
    parameter AW = 28, IDW = 4
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          en,
    input  wire [AW-1:0] base,
    output reg  [AW-1:0] araddr,
    output reg  [7:0]    arlen,
    output reg           arvalid,
    input  wire          arready,
    input  wire          rvalid,
    input  wire          rlast,
    output wire          rready
);
    reg [3:0] out_cnt;      /* 在飞突发数 */
    reg [AW-1:0] nxt;
    assign rready = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_cnt <= 4'd0; arvalid <= 1'b0; araddr <= {AW{1'b0}};
            arlen <= 8'd15; nxt <= {AW{1'b0}};
        end else begin
            if (!en) begin
                out_cnt <= 4'd0; arvalid <= 1'b0;
                nxt <= base;
            end else begin
                if (arvalid && arready) begin
                    out_cnt <= out_cnt + 4'd1;
                    araddr  <= nxt + {16'd0, 8'd16, 4'd0};   /* 16 拍 = 256B */
                    nxt     <= nxt + {16'd0, 8'd16, 4'd0};
                end else
                    araddr <= nxt;
                if (rvalid && rlast)
                    out_cnt <= out_cnt - 4'd1;

                /* 4 笔在飞、背靠背 */
                if ((out_cnt < 4'd4) && !(arvalid && arready))
                    arvalid <= 1'b1;
                else if (arvalid && arready)
                    arvalid <= (out_cnt + 4'd1 < 4'd4);
                arlen  <= 8'd15;
            end
        end
    end
endmodule

/* ================================================================== */
module tb_scanout_bw;
    localparam FB_W = 128, FB_H = 32, STRIDE = 256;
    localparam BEATS = FB_W*2/16;          /* 16 拍/行 */
    localparam MB    = 8;                  /* 每突发 ≤8 拍 → 2 突发/行 */

    reg clk = 1'b0, pclk = 1'b0, rst_n = 1'b0, prst_n = 1'b0;
    always #5    clk  = ~clk;              /* core 100MHz */
    always #6.25 pclk = ~pclk;             /* 像素行 = 160*12.5ns = 200 core 周期 */

    /* ---------------- 扫描输出 ---------------- */
    wire [27:0]  s_araddr; wire [7:0] s_arlen; wire [2:0] s_arsize;
    wire [1:0]   s_arburst; wire s_arvalid, s_arready;
    wire [127:0] s_rdata;  wire [1:0] s_rresp; wire s_rlast, s_rvalid, s_rready;

    wire vde, vhs, vvs, frame_tick;
    wire [7:0] vr, vg, vb;
    wire       scan_hold;

    fb_scanout #(
        .FB_BASE(32'h0030_1000), .FB_STRIDE(32'd256), .FB_W(12'd128), .FB_H(12'd32),
        .WIN_X(12'd0), .WIN_Y(12'd0),
        .H_ACTIVE(12'd128), .H_FP(12'd8), .H_SYNC(12'd8), .H_BP(12'd16),
        .V_ACTIVE(12'd32), .V_FP(12'd2), .V_SYNC(12'd2), .V_BP(12'd4),
        .MAX_BURST(MB[7:0])
    ) dut (
        .clk(clk), .rst_n(rst_n),
        /* v2.6/v2.7 新增端口：本 TB 只测带宽，翻转路径由 tb_scanout_flip 覆盖 */
        .fb_sel(2'b00),
        .m_axi_araddr(s_araddr), .m_axi_arlen(s_arlen), .m_axi_arsize(s_arsize),
        .m_axi_arburst(s_arburst), .m_axi_arid(),
        .m_axi_arvalid(s_arvalid), .m_axi_arready(s_arready),
        .m_axi_rdata(s_rdata), .m_axi_rresp(s_rresp), .m_axi_rid(4'd1),
        .m_axi_rlast(s_rlast), .m_axi_rvalid(s_rvalid), .m_axi_rready(s_rready),
        .m_axi_hold(scan_hold),
        .pclk(pclk), .prst_n(prst_n),
        .vde(vde), .vhs(vhs), .vvs(vvs), .vr(vr), .vg(vg), .vb(vb),
        .frame_tick(frame_tick), .dbg_line(), .dbg_underrun(), .dbg_abort()
    );

    /* ---------------- 引擎读主机（BitBlt） ---------------- */
    wire [27:0] b_araddr; wire [7:0] b_arlen; wire b_arvalid, b_arready;
    wire [127:0] b_rdata; wire [1:0] b_rresp; wire b_rlast, b_rvalid, b_rready;
    wire        blt_en;

    blt_rd_gen #(.AW(28), .IDW(4)) u_blt_rd (
        .clk(clk), .rst_n(rst_n), .en(blt_en),
        .base(32'h0010_1000),
        .araddr(b_araddr), .arlen(b_arlen), .arvalid(b_arvalid), .arready(b_arready),
        .rvalid(b_rvalid), .rlast(b_rlast), .rready(b_rready)
    );

    /* ---------------- CPU 读通道：模拟 SoC 外存口的引导期读数 ----------------
     * ★ 之前的 TB 把 CPU 侧一直拉成 idle，等于**根本没测**"扫描输出会不会把 CPU 饿死"，
     *   而这正是上板"串口一个字都没有"最可能的原因。这里接一个真实的读主机：
     *   一次一笔突发、背靠背请求，统计"AR 从拉起到被受理"的最大等待与完成笔数。 */
    wire [27:0]  c_araddr; wire [7:0] c_arlen; wire [3:0] c_arid;
    wire         c_arvalid, c_arready, c_rvalid, c_rlast; wire [127:0] c_rdata;
    wire         c_rready;
    wire [31:0]  c_nburst, c_nbeat, c_errs;
    arb_master #(.BASE(28'h800_0000), .STRIDE(28'h000_0100), .NAME("CPU")) u_cpu (
        .clk(clk), .rst_n(rst_n),
        .araddr(c_araddr), .arlen(c_arlen), .arvalid(c_arvalid), .arready(c_arready),
        .rdata(c_rdata), .rvalid(c_rvalid), .rlast(c_rlast), .rready(c_rready),
        .nburst(c_nburst), .nbeat(c_nbeat), .errs(c_errs)
    );

    /* CPU AR 等待统计（拉起到受理的拍数） */
    integer cpu_wait_cur, cpu_wait_max, cpu_wait_sum, cpu_wait_cnt;
    reg     c_arvalid_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_wait_cur = 0; cpu_wait_max = 0; cpu_wait_sum = 0; cpu_wait_cnt = 0;
            c_arvalid_d = 1'b0;
        end else begin
            if (c_arvalid) cpu_wait_cur = cpu_wait_cur + 1;
            if (c_arvalid && !c_arvalid_d) cpu_wait_cur = 0;
            if (c_arvalid && c_arready) begin
                if (cpu_wait_cur > cpu_wait_max) cpu_wait_max = cpu_wait_cur;
                cpu_wait_sum = cpu_wait_sum + cpu_wait_cur;
                cpu_wait_cnt = cpu_wait_cnt + 1;
                cpu_wait_cur = 0;
            end
            c_arvalid_d = c_arvalid;
        end
    end

    /* ---------------- 读 L1：CPU / BitBlt（BitBlt 为 s = 优先） ---------------- */
    wire [27:0]  m1_araddr; wire [7:0] m1_arlen; wire [2:0] m1_arsize;
    wire [1:0]   m1_arburst; wire [3:0] m1_arid; wire m1_arvalid, m1_arready;
    wire [127:0] m1_rdata; wire [1:0] m1_rresp; wire [3:0] m1_rid;
    wire m1_rlast, m1_rvalid, m1_rready;

    axi_rd_arb #(.AW(28), .DW(128), .IDW(4)) u_l1 (
        .clk(clk), .rst_n(rst_n),
        .c_araddr(c_araddr), .c_arlen(c_arlen), .c_arsize(3'd4),
        .c_arburst(2'b01), .c_arid(c_arid), .c_arvalid(c_arvalid),
        .c_arready(c_arready),
        .c_rdata(c_rdata), .c_rresp(), .c_rid(), .c_rlast(c_rlast),
        .c_rvalid(c_rvalid), .c_rready(1'b1),
        .s_araddr(b_araddr), .s_arlen(b_arlen), .s_arsize(3'd4),
        .s_arburst(2'b01), .s_arvalid(b_arvalid), .s_arready(b_arready),
        .s_hold(1'b0),
        .s_rdata(b_rdata), .s_rresp(b_rresp), .s_rlast(b_rlast),
        .s_rvalid(b_rvalid), .s_rready(b_rready),
        .m_araddr(m1_araddr), .m_arlen(m1_arlen), .m_arsize(m1_arsize),
        .m_arburst(m1_arburst), .m_arid(m1_arid), .m_arvalid(m1_arvalid),
        .m_arready(m1_arready),
        .m_rdata(m1_rdata), .m_rresp(m1_rresp), .m_rid(m1_rid), .m_rlast(m1_rlast),
        .m_rvalid(m1_rvalid), .m_rready(m1_rready)
    );

    /* ---------------- 读 L2：(CPU/BitBlt) / 扫描输出（扫描为 s = 最高优先） ------------- */
    wire m2_arvalid, m2_arready, m2_rvalid, m2_rlast, m2_rready;
    wire [27:0] m2_araddr; wire [7:0] m2_arlen; wire [2:0] m2_arsize;
    wire [1:0]  m2_arburst; wire [3:0] m2_arid;
    wire [127:0] m2_rdata; wire [1:0] m2_rresp; wire [3:0] m2_rid;

    axi_rd_arb #(.AW(28), .DW(128), .IDW(4), .S_PRIO(1)) u_l2 (
        .clk(clk), .rst_n(rst_n),
        .c_araddr(m1_araddr), .c_arlen(m1_arlen), .c_arsize(m1_arsize),
        .c_arburst(m1_arburst), .c_arid(m1_arid), .c_arvalid(m1_arvalid),
        .c_arready(m1_arready),
        .c_rdata(m1_rdata), .c_rresp(m1_rresp), .c_rid(m1_rid), .c_rlast(m1_rlast),
        .c_rvalid(m1_rvalid), .c_rready(m1_rready),
        .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arsize(s_arsize),
        .s_arburst(s_arburst), .s_arvalid(s_arvalid), .s_arready(s_arready),
        .s_hold(scan_hold),
        .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
        .s_rvalid(s_rvalid), .s_rready(s_rready),
        .m_araddr(m2_araddr), .m_arlen(m2_arlen), .m_arsize(m2_arsize),
        .m_arburst(m2_arburst), .m_arid(m2_arid), .m_arvalid(m2_arvalid),
        .m_arready(m2_arready),
        .m_rdata(m2_rdata), .m_rresp(m2_rresp), .m_rid(m2_rid), .m_rlast(m2_rlast),
        .m_rvalid(m2_rvalid), .m_rready(m2_rready)
    );

    /* ---------------- DDR 读从机 + 周期 busy（写突发占用读口） ---------------- */
    reg [15:0] cyc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cyc <= 16'd0;
        else        cyc <= cyc + 16'd1;
    end
    /* 忙碌窗口：每 100 周期忙 25 周期（= 250ns，接近真实 DDR 写突发的转向/排空时间；
     * 注意不要把"读通道完全停住"建模成整行(14.8us)量级 —— 那是非物理的，
     * 真实控制器是读写按 ~10~100ns 粒度交替的）。 */
    wire ddr_busy = blt_en && ((cyc % 16'd100) >= 16'd75);

    ddr_rd_slave #(.AW(28), .DW(128), .IDW(4)) u_ddr (
        .clk(clk), .rst_n(rst_n),
        .araddr(m2_araddr), .arlen(m2_arlen), .arvalid(m2_arvalid), .arready(m2_arready),
        .rdata(m2_rdata), .rlast(m2_rlast), .rvalid(m2_rvalid), .rready(m2_rready),
        .busy(ddr_busy)
    );

    /* ================= 阶段控制 + 显示侧欠载统计 =================
     * 一行 = 200 core 周期，一帧 = 40 行 = 8000 core 周期。
     * 第 1 帧是启动瞬态（行缓冲还没取到数），不统计。 */
    localparam integer T_SKIP = 8000;      /* 跳过第 1 帧 */
    localparam integer P1_END = 24000;     /* P1：引擎空闲（基线） */
    localparam integer P2_END = 40000;     /* P2：引擎满载 */
    localparam integer P3_END = 56000;     /* P3：引擎再次停止 */

    integer cyc_core;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cyc_core <= 0;
        else        cyc_core <= cyc_core + 1;
    end

    assign blt_en = (cyc_core >= P1_END) && (cyc_core < P2_END);

    integer p1_px, p2_px, p3_px;          /* 各阶段"窗口内被判未就绪"的像素数 */
    integer p1_ln, p2_ln, p3_ln;          /* 各阶段窗口行数 */
    integer p1_worst, p2_worst, p3_worst; /* 单行最坏欠载像素数 */
    integer line_px;                      /* 当前行欠载像素数 */
    integer ln_idx;
    integer prof [0:47];                  /* 忙碌期逐行欠载像素数 */
    integer prof_v [0:47];
    integer prof_n;

    wire in_win_now = dut.win_now;
    wire ok_now     = dut.buf_ok;

    task commit_line;
        begin
            if (cyc_core >= T_SKIP) begin
                if (cyc_core < P1_END) begin
                    p1_px = p1_px + line_px; p1_ln = p1_ln + 1;
                    if (line_px > p1_worst) p1_worst = line_px;
                end else if (cyc_core < P2_END) begin
                    p2_px = p2_px + line_px; p2_ln = p2_ln + 1;
                    if (line_px > p2_worst) p2_worst = line_px;
                    if (prof_n < 48) begin
                        prof[prof_n]   = line_px;
                        prof_v[prof_n] = dut.vcnt;
                        prof_n = prof_n + 1;
                    end
                end else if (cyc_core < P3_END) begin
                    p3_px = p3_px + line_px; p3_ln = p3_ln + 1;
                    if (line_px > p3_worst) p3_worst = line_px;
                end
            end
            line_px = 0;
            ln_idx  = ln_idx + 1;
        end
    endtask

    always @(negedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            p1_px = 0; p2_px = 0; p3_px = 0;
            p1_ln = 0; p2_ln = 0; p3_ln = 0;
            p1_worst = 0; p2_worst = 0; p3_worst = 0;
            line_px = 0; ln_idx = 0; prof_n = 0;
        end else begin
            if (dut.hcnt == 12'd0)
                commit_line;
            if (in_win_now && !ok_now)
                line_px = line_px + 1;
        end
    end

    /* 取数耗时统计（core 周期）：st != S_IDLE 的周期数 / 取行次数
     * 并按 [S_FETCH 开始 → 第一个 R 握手]（=等仲裁+等 DDR 里排队的旧请求）
     * 与 [第一个 R → 最后一个 R]（=本行数据搬移）拆分，用来判断瓶颈在哪。*/
    integer fetch_cyc, fetch_cnt, fetch_max, fetch_cur;
    integer w_sum, w_cnt, w_max;          /* 等首拍 */
    integer d_sum, d_cnt, d_max;          /* 数据搬移 */
    integer idle_sum;                     /* S_IDLE 周期 */
    integer own_s_cyc, own_c_cyc;         /* L2 归属周期 */
    reg     st_d;
    reg     got_first;
    integer in_fetch;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_cyc = 0; fetch_cnt = 0; fetch_max = 0; fetch_cur = 0; st_d = 1'b0;
            w_sum = 0; w_cnt = 0; w_max = 0;
            d_sum = 0; d_cnt = 0; d_max = 0;
            idle_sum = 0; own_s_cyc = 0; own_c_cyc = 0;
            got_first = 1'b0; in_fetch = 0;
        end else begin
            st_d <= (dut.st != 2'd0);
            if (cyc_core >= T_SKIP) begin
                if (u_l2.owner) own_s_cyc = own_s_cyc + 1;
                else            own_c_cyc = own_c_cyc + 1;
            end
            if (dut.st != 2'd0) begin
                fetch_cyc = fetch_cyc + 1;
                fetch_cur = fetch_cur + 1;
                in_fetch  = in_fetch + 1;
                if (!got_first && dut.m_axi_rvalid && dut.m_axi_rready) begin
                    got_first = 1'b1;
                    w_sum = w_sum + in_fetch;
                    w_cnt = w_cnt + 1;
                    if (in_fetch > w_max) w_max = in_fetch;
                end
            end else begin
                if (cyc_core >= T_SKIP) idle_sum = idle_sum + 1;
                if (st_d) begin
                    fetch_cnt = fetch_cnt + 1;
                    if (fetch_cur > fetch_max) fetch_max = fetch_cur;
                    fetch_cur = 0;
                end
                if (got_first) begin
                    d_sum = d_sum + in_fetch;
                    d_cnt = d_cnt + 1;
                    if (in_fetch > d_max) d_max = in_fetch;
                end
                got_first = 1'b0;
                in_fetch  = 0;
            end
        end
    end

    /* 关键指标：相邻"整行就绪"之间隔了多少 core 周期 —— 必须 ≤ 显示行(200)，
     * 否则扫描输出在平均意义上就追不上显示（再多缓冲也只能拖时间）。 */
    integer rdy_evt, rdy_gap_sum, rdy_gap_max, rdy_gap_cur;
    reg [3:0] br_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdy_evt = 0; rdy_gap_sum = 0; rdy_gap_max = 0; rdy_gap_cur = 0; br_d = 4'd0;
        end else begin
            rdy_gap_cur = rdy_gap_cur + 1;
            if (|(dut.buf_ready & ~br_d) && (cyc_core >= T_SKIP)) begin
                if (rdy_evt > 0) begin
                    rdy_gap_sum = rdy_gap_sum + rdy_gap_cur;
                    if (rdy_gap_cur > rdy_gap_max) rdy_gap_max = rdy_gap_cur;
                end
                rdy_evt = rdy_evt + 1;
                rdy_gap_cur = 0;
            end
            br_d = dut.buf_ready;
        end
    end

    /* 卡死检测：取数 FSM 连续 >2000 周期没进展就打印一次现场 */
    integer stuck_cur; reg stuck_done;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin stuck_cur = 0; stuck_done = 1'b0; end
        else if (dut.st != 1'b0) begin
            stuck_cur = stuck_cur + 1;
            if ((stuck_cur > 2000) && !stuck_done) begin
                stuck_done = 1'b1;
                $display("STUCK @t=%0d st=%b next=%0d cons=%0d br=%b | arv=%b arr=%b rv=%b rr=%b beat=%0d ari=%0d | own=%b cnt_c=%0d cnt_s=%0d wait_c=%0d | q=%0d",
                         cyc_core, dut.st, dut.next_y, dut.cons_s, dut.buf_ready,
                         dut.m_axi_arvalid, dut.m_axi_arready, dut.m_axi_rvalid, dut.m_axi_rready,
                         dut.beat_idx, dut.ar_idx, u_l2.owner, u_l2.cnt_c, u_l2.cnt_s, u_l2.wait_c,
                         u_ddr.q_cnt);
            end
        end else begin
            stuck_cur = 0; stuck_done = 1'b0;
        end
    end

    /* CPU 读数通路一次性体检（P1 期间） */
    always @(posedge clk) begin
        if (cyc_core == 3000 || cyc_core == 6000 || cyc_core == 20000)
            $display("CPUCHK t=%0d cpu_st=%0d c_arv=%b c_arr=%b c_rv=%b c_rl=%b c_rr=%b | L1 own=%b cc=%0d cs=%0d wc=%0d m1arv=%b m1arr=%b m1rv=%b m1rr=%b | L2 own=%b cc=%0d cs=%0d m2arv=%b m2arr=%b m2rv=%b m2rr=%b",
                     cyc_core, u_cpu.st, c_arvalid, c_arready, c_rvalid, c_rlast, c_rready,
                     u_l1.owner, u_l1.cnt_c, u_l1.cnt_s, u_l1.wait_c,
                     m1_arvalid, m1_arready, m1_rvalid, m1_rready,
                     u_l2.owner, u_l2.cnt_c, u_l2.cnt_s,
                     m2_arvalid, m2_arready, m2_rvalid, m2_rready);
    end

    integer i;
    initial begin
        #200 rst_n = 1'b1;
        #300 prst_n = 1'b1;
        #600000;                        /* 600us = 60000 core 周期 ≈ 7.5 帧 */
        $display("");
        $display("================ 扫描输出欠载(underrun)统计 ================");
        $display("P1 引擎空闲 : 窗口行 %0d, 欠载像素 %0d (最坏单行 %0d/128)",
                 p1_ln, p1_px, p1_worst);
        $display("P2 引擎满载 : 窗口行 %0d, 欠载像素 %0d (最坏单行 %0d/128)",
                 p2_ln, p2_px, p2_worst);
        $display("P3 引擎停止 : 窗口行 %0d, 欠载像素 %0d (最坏单行 %0d/128)",
                 p3_ln, p3_px, p3_worst);
        $display("取数: 次数 %0d, 平均 %0d core 周期/行, 最大 %0d (显示行 = 200 周期)",
                 fetch_cnt, (fetch_cnt == 0) ? 0 : (fetch_cyc / fetch_cnt), fetch_max);
        $display("  拆分: 等首拍 平均%0d 最大%0d (%0d次) | 数据搬移 平均%0d 最大%0d (%0d次)",
                 (w_cnt == 0) ? 0 : (w_sum / w_cnt), w_max, w_cnt,
                 (d_cnt == 0) ? 0 : (d_sum / d_cnt), d_max, d_cnt);
        $display("  空闲(S_IDLE) %0d 周期 | L2 归属: 扫描 %0d / 引擎 %0d 周期",
                 idle_sum, own_s_cyc, own_c_cyc);
        $display("  整行就绪间隔: %0d 次, 平均 %0d, 最大 %0d (必须 ≤200 = 显示行)",
                 rdy_evt, (rdy_evt > 1) ? (rdy_gap_sum / (rdy_evt - 1)) : 0, rdy_gap_max);
        $display("  CPU 读数: 完成突发 %0d 笔 / %0d 拍 | AR 等待 平均 %0d 最大 %0d 拍 (受理 %0d 次)",
                 c_nburst, c_nbeat, (cpu_wait_cnt == 0) ? 0 : (cpu_wait_sum / cpu_wait_cnt),
                 cpu_wait_max, cpu_wait_cnt);
        $display("--- 忙碌期逐行欠载像素（行首 = 屏幕左侧；逐行变宽 = 三角形黑区）---");
        for (i = 0; i < prof_n; i = i + 1)
            $display("  P2 line[%0d] vcnt=%0d : %0d px 黑", i, prof_v[i], prof[i]);

        if (p1_px == 0 && p2_px == 0 && p3_px == 0)
            $display("========== tb_scanout_bw PASS: 引擎满载下 0 欠载 ==========");
        else if (p1_px == 0 && p3_px == 0)
            $display("========== tb_scanout_bw: 复现欠载（引擎繁忙期黑楔）==========");
        else
            $display("========== tb_scanout_bw FAIL: P1/P3(引擎空闲)也有欠载 ==========");
        $finish;
    end
endmodule
