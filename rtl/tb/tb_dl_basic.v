/* =========================================================================
 * tb_dl_basic.v — 显示列表（描述符表）S2 主测试台
 * -------------------------------------------------------------------------
 * 覆盖（对应任务书"必须的证据"第 2 条）：
 *   (i)  **逐像素等价**：同一批精灵，先用"CPU 逐条 8 字 push"画一遍做成金标准，
 *        再用"描述符表 + DFU 展开"画一遍，整幅 FB **逐字节比对**；
 *   (ii) **每精灵开销**：同尺寸（16×16 FILL）下三种下发方式的对比 ——
 *          · cpu_serial：push 一条 → 等它跑完 → 再 push（CPU 存储延迟全暴露）
 *          · cpu_pipe  ：一次 push 完 K 条（FIFO 提前灌满）→ 等跑完（引擎地板）
 *          · list      ：写几个寄存器 + GO，DFU 取指展开（S2 的目标路径）
 *        per_sprite = (总拍数 − K×256) / K；
 *   (iii)**AW / 突发**：列表路径下 AW 笔数、W 拍数、burst_max（合并必须仍是 16）；
 *   (iv) **写序**：全程 b_pending ≤ 1，DONE 时刻写通路必须彻底干净（H1/H2 同口径）。
 *
 * 夹具/存储模型/寄存器序列沿用 tb_blt_top / tb_perf_probe 的既有资产。
 *
 * 编译运行（仓库根目录；A/B 加 `-DDL_OFF`）：
 *   $env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
 *   iverilog -g2001 -s tb_dl_basic -o sim_tb_dl_basic.vvp rtl/sync_fifo.v rtl/cmd_fifo.v \
 *     rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v rtl/axi_rd_master.v rtl/axi_wr_master.v \
 *     rtl/stream_reader.v rtl/pixel_path.v rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v \
 *     rtl/clr_engine.v rtl/dl_fetch.v rtl/blt_top.v rtl/tb/axi_slave_mem.v rtl/tb/tb_dl_basic.v
 *   vvp sim_tb_dl_basic.vvp
 *   `-DDL_OFF` ⇒ 列表路径整体旁路（DL GO 不产生任何命令），本台转为
 *   "只跑 CPU 路径 + 断言 DFU 完全静默"，两个模式都必须 PASS。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_dl_basic;

    /* ================= 时钟 / 复位 ================= */
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    /* ================= 地址布局（真实存储 32KB = 0x0000..0x7FFF） =================
     *   0x0000..0x0FFF  atlas（8 个 16×16 精灵，4×2 网格，行距 128B）
     *   0x1000..0x4FFF  目标 FB（128×64 像素，行距 256B）
     *   0x6000..0x6FFF  描述符表（最多 256 条）
     *   0x7000..0x707F  几何表（8 条 × 16B） */
    localparam [31:0] ATLAS    = 32'h0000_0000;
    localparam [31:0] DST      = 32'h0000_1000;
    localparam [31:0] LIST     = 32'h0000_6000;
    localparam [31:0] GEOM     = 32'h0000_7000;
    localparam [31:0] A_STRIDE = 32'd128;
    localparam [31:0] D_STRIDE = 32'd256;
    localparam [15:0] FB_W = 16'd128, FB_H = 16'd64;
    localparam integer NSPR = 8;             // 几何表条目数
    localparam integer K    = 64;            // 一帧的精灵（描述符）条数
    localparam integer NOVH = 200;           // 开销对照用的 16×16 FILL 条数

    /* ================= AXI-Lite 主测口 ================= */
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
    /* ★ RRESP 必须显式接 0：DFU 用它判 AXI_RRESP 错误，悬空成 Z 会让
     *   `desc_rresp == 2'b00` 变成 X ⇒ 列表路径静默卡死（本 TB 第一版就踩了这个） */
    wire [1:0]  m_rresp = 2'b00;

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
        .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp), .m_axi_rlast(m_rlast),
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

    /* ================= 记分板 / 计数器 ================= */
    integer errors = 0;
    integer aw_cnt, w_cnt, b_cnt, burst_max, bp_max;
    integer eng_act, eng_gap;
    integer bl_hist [0:16];          // AW 突发长度直方图（下标 = burst_len）
    reg     mon_en;

    wire        eng_run = (u_blt.u_eng.st != 3'd0);
    wire [4:0]  b_pend  = u_blt.wr_b_pending;

    always @(posedge clk) if (rst_n) begin
        if (u_blt.blt_awvalid && u_blt.blt_awready) begin
            aw_cnt = aw_cnt + 1;
            if (u_blt.u_wr.burst_len > burst_max) burst_max = u_blt.u_wr.burst_len;
            if (u_blt.u_wr.burst_len <= 16) bl_hist[u_blt.u_wr.burst_len] = bl_hist[u_blt.u_wr.burst_len] + 1;
        end
        if (m_wvalid && m_wready) w_cnt = w_cnt + 1;
        if (m_bvalid && m_bready) b_cnt = b_cnt + 1;
        if (b_pend > bp_max) bp_max = b_pend;
        if (mon_en) begin
            if (eng_run) eng_act = eng_act + 1;
            else         eng_gap = eng_gap + 1;
        end
    end

    task chk;
        input ok;
        input [255:0] name;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* ================= AXI-Lite 任务 ================= */
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

    /* ================= 存储模型直写 ================= */
    task poke16;
        input [31:0] a; input [15:0] v;
        begin u_mem.mem[a] = v[7:0]; u_mem.mem[a+1] = v[15:8]; end
    endtask
    task poke32;
        input [31:0] a; input [31:0] v;
        begin u_mem.mem[a]   = v[7:0];   u_mem.mem[a+1] = v[15:8];
              u_mem.mem[a+2] = v[23:16]; u_mem.mem[a+3] = v[31:24]; end
    endtask

    /* ================= 场景 / 金标准 ================= */
    reg [15:0] sx[0:NOVH-1], sy[0:NOVH-1], sspr[0:NOVH-1];
    reg [1:0]  sop[0:NOVH-1];
    reg [7:0]  salpha[0:NOVH-1];
    reg [15:0] skey[0:NOVH-1];
    reg [7:0]  gold [0:16383];
    reg [7:0]  shot [0:16383];
    reg [31:0] g_dstride;            // 当前场景的目标行距（混合场景 256 / 纯 FILL 场景 32）
    integer i, j, n, mism, t0, rv;
    integer ser_cyc, pipe_cyc, list_cyc, list_perf;
    integer ser_eng, pipe_eng, list_eng;
    reg [31:0] q0, q1, q2, q3, q4, q5, q6, q7;

    task init_atlas;
        integer r, c;
        begin
            for (i = 0; i < 32; i = i + 1)
                for (j = 0; j < 64; j = j + 1)
                    poke16(ATLAS + i*A_STRIDE + j*2, 16'h0000);
            for (n = 0; n < NSPR; n = n + 1)
                for (r = 0; r < 16; r = r + 1)
                    for (c = 0; c < 16; c = c + 1)
                        /* 每个精灵一个基色，行内再变化（错位/取错像素必暴露） */
                        poke16(ATLAS + ((n/4)*16 + r)*A_STRIDE + ((n%4)*16 + c)*2,
                               16'h0800 + (n << 8) + (r << 4) + c);
        end
    endtask

    task init_geom;
        begin
            for (n = 0; n < NSPR; n = n + 1) begin
                poke32(GEOM + n*16 + 0,  ATLAS);
                poke16(GEOM + n*16 + 4,  A_STRIDE[15:0]);
                poke16(GEOM + n*16 + 6,  16'hF81F);            // KEY_DEFAULT
                poke16(GEOM + n*16 + 8,  16'd16);              // W
                poke16(GEOM + n*16 + 10, 16'd16);              // H
                poke16(GEOM + n*16 + 12, ((n % 4) * 16));      // SX
                poke16(GEOM + n*16 + 14, ((n / 4) * 16));      // SY
            end
        end
    endtask

    task init_dst;
        integer r, c;
        begin
            for (r = 0; r < FB_H; r = r + 1)
                for (c = 0; c < FB_W; c = c + 1)
                    poke16(DST + r*D_STRIDE + c*2,
                           16'h1000 + ((r*7 + c*13) & 16'h03FF));
        end
    endtask

    task init_scene;
        begin
            g_dstride = D_STRIDE;
            for (n = 0; n < K; n = n + 1) begin
                sx[n]     = (n * 13) % 112;                  // 0..111，全部在屏内
                sy[n]     = (n * 7)  % 48;                   // 0..47
                sspr[n]   = n % NSPR;
                sop[n]    = n % 4;                           // 0=COPY 1=FILL 2=ALPHA 3=KEY
                salpha[n] = 32 + (n * 3) % 224;              // 32..255
                skey[n]   = 16'hF81F;
            end
        end
    endtask

    /* 纯 16×16 FILL ×NOVH：全部落在**同一块连续 512B**（行距 32B），
     * 这样一次命令的写就是 32 个连续 16B 词 ⇒ 写突发合并能真正跑满 16 拍，
     * AW ≈ ⌈词数/16⌉ 才有意义（混合场景各行不连续，天生合不到 16）。 */
    task init_scene_fill;
        begin
            g_dstride = 32'd32;
            for (n = 0; n < NOVH; n = n + 1) begin
                sx[n] = 16'd0; sy[n] = 16'd0; sspr[n] = 16'd0;
                sop[n] = 2'd1; salpha[n] = 8'hFF; skey[n] = 16'h07E0;
            end
        end
    endtask

    /* 把第 idx 条精灵展开成"和 DFU 完全一致"的 8 字（手工算，做金标准） */
    task cmd_of;
        input  integer idx;
        reg [15:0] sxx, syy;
        begin
            sxx = (sspr[idx] % 4) * 16;
            syy = (sspr[idx] / 4) * 16;
            q0 = {30'd0, sop[idx]};
            q1 = (sop[idx] == 2'd1) ? 32'd0 : (ATLAS + syy*A_STRIDE + sxx*2);
            q2 = DST + sy[idx]*g_dstride + sx[idx]*2;
            q3 = A_STRIDE;
            q4 = g_dstride;
            q5 = {16'd16, 16'd16};
            q6 = {24'd0, salpha[idx]};
            q7 = (sop[idx] == 2'd1) ? {16'd0, skey[idx]}
                 : ((skey[idx] == 16'hFFFF) ? 32'h0000_F81F : {16'd0, skey[idx]});
        end
    endtask

    task push_cmd;
        begin
            axi_write(12'h08, q0); axi_write(12'h08, q1);
            axi_write(12'h08, q2); axi_write(12'h08, q3);
            axi_write(12'h08, q4); axi_write(12'h08, q5);
            axi_write(12'h08, q6); axi_write(12'h08, q7);
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

    task wait_eng_start;
        begin
            for (i = 0; (i < 200000) && (u_blt.u_eng.st == 3'd0); i = i + 1) @(posedge clk);
        end
    endtask

    task wait_done_level;
        begin : wdl
            for (i = 0; i < 2000000; i = i + 1) begin
                axi_read(12'h04, rv);
                if (rv & 32'h2) disable wdl;
                if (rv & 32'h4) begin
                    $display("FAIL: 引擎 ERR（STATUS=0x%h）", rv);
                    errors = errors + 1;
                    dbg_dump();
                    disable wdl;
                end
            end
            $display("FAIL: DONE 超时");
            errors = errors + 1;
            dbg_dump();
        end
    endtask

    task snap_dst;
        input integer which;
        integer a;
        begin
            for (a = 0; a < 16384; a = a + 1) begin
                if (which == 0) shot[a] = u_mem.mem[DST + a];
                else            gold[a] = u_mem.mem[DST + a];
            end
        end
    endtask

    task cmp_dst;
        integer a;
        begin
            mism = 0;
            for (a = 0; a < 16384; a = a + 1)
                if (shot[a] !== gold[a]) begin
                    if (mism < 6)
                        $display("      MISMATCH off=%0d (x=%0d y=%0d) got=%02h exp=%02h",
                                 a, (a % 256) / 2, a / 256, shot[a], gold[a]);
                    mism = mism + 1;
                end
        end
    endtask

    /* ================= 描述符表 ================= */
    task build_list;
        input integer cnt;
        integer di;
        reg [15:0] fl;
        begin
            for (di = 0; di < cnt; di = di + 1) begin
                fl = {14'd0, sop[di]};                       // FLAGS[1:0] = OP
                if (di == cnt-1) fl = fl | 16'h0400;         // END_OF_LIST
                poke16(LIST + di*16 + 0,  sx[di]);           // X
                poke16(LIST + di*16 + 2,  sy[di]);           // Y
                poke16(LIST + di*16 + 4,  sspr[di]);         // SPR_ID
                poke16(LIST + di*16 + 6,  fl);               // FLAGS
                poke16(LIST + di*16 + 8,  skey[di]);         // KEY / FILL 色
                poke16(LIST + di*16 + 10, {8'd0, salpha[di]}); // ALPHA / PRIO
                poke16(LIST + di*16 + 12, 16'd0);            // MASK_ID（S3 预留）
                poke16(LIST + di*16 + 14, 16'd0);            // W_OVR / H_OVR
            end
        end
    endtask

    task dl_config;
        input [15:0] cnt;
        input [15:0] stride;
        begin
            axi_write(12'h4C, LIST);               // DL_BASE0
            axi_write(12'h50, LIST);               // DL_BASE1
            axi_write(12'h68, GEOM);               // DL_GEOM_BASE
            axi_write(12'h6C, 16'd8);              // DL_GEOM_MAX = 8
            axi_write(12'h70, DST);                // DL_DST_BASE
            axi_write(12'h84, stride);             // DL_DST_STRIDE
            axi_write(12'h88, {FB_H, FB_W});       // DL_FB_WH
            axi_write(12'h74, 32'h0000_0483);      // CHUNK=8 WM=4 PREFETCH=1 GEC=1
            axi_write(12'h78, 32'd4096);           // DL_TIMEOUT
            axi_write(12'h54, {16'd0, cnt});       // DL_COUNT
            axi_write(12'h60, 32'hFFFF_FFFF);      // 清 DL_ERR（W1C）
        end
    endtask

    task dl_go;
        begin
            /* bit0=GO bit4=AUTO_GO bit5=STRICT_BOUNDS（默认 1，显式写上） */
            axi_write(12'h58, 32'h31);
        end
    endtask

    task dl_wait_done;
        input integer t_start;
        begin : dwd
            for (i = 0; i < 2000000; i = i + 1) begin
                axi_read(12'h5C, rv);
                if ((rv & 32'h2) && !(rv & 32'h1)) begin   // DONE=1 && BUSY=0
                    list_cyc = cyc - t_start;
                    disable dwd;
                end
                if (rv & 32'h4) begin
                    $display("FAIL: 列表路径报错 DL_STATUS=0x%h", rv);
                    errors = errors + 1;
                    dbg_dump();
                    list_cyc = cyc - t_start;
                    disable dwd;
                end
            end
            $display("FAIL: 列表 DONE 超时（DL_STATUS=0x%h）", rv);
            errors = errors + 1;
            dbg_dump();
            list_cyc = cyc - t_start;
        end
    endtask

    /* 失败现场转储（诊断用；只在出错路径调用） */
    task dbg_dump;
        integer e, fa;
        begin
            axi_read(12'h5C, e);
            axi_read(12'h60, fa);
            $display("      [DBG] DL_STATUS=0x%h DL_ERR=0x%h", e, fa);
            axi_read(12'h64, fa);
            $display("      [DBG] FAULT_ADDR=0x%h", fa);
`ifndef DL_OFF
            $display("      [DBG] dl.st=%0d dl.wd_cnt=%0d consumed=%0d",
                     u_blt.u_dl.st, u_blt.u_dl.wd_cnt, u_blt.u_dl.consumed_r);
`endif
            $display("      [DBG] eng.st=%0d cmd_wcount=%0d wd_count=%0d b_pending=%0d ctrl_go=%b auto_go=%b",
                     u_blt.u_eng.st, u_blt.u_cmd.word_count, u_blt.wd_count,
                     u_blt.wr_b_pending, u_blt.ctrl_go, u_blt.dl_auto_go_hold);
            $display("      [DBG] fifo_cmd_count=%0d full=%b empty=%b",
                     u_blt.cmd_cmd_count, u_blt.cmd_full, u_blt.cmd_empty);
        end
    endtask

    /* 计时包装：把每次 push_cmd 的 CPU 侧拍数累加 */
    integer push_accum;
    task push_cmd_timed;
        integer tp;
        begin
            tp = cyc;
            push_cmd();
            push_accum = push_accum + (cyc - tp);
        end
    endtask

    /* ================= DFU 逐拍追踪（+trc 打开，仅诊断用） ================= */
`ifndef DL_OFF
    reg     trc = 1'b0;
    integer trc_n = 0;
    initial trc = $test$plusargs("trc");
    always @(posedge clk) begin
        if (trc && trc_n < 120 && (u_blt.u_dl.st != 4'd0)) begin
            trc_n = trc_n + 1;
            $display("[DLT] t=%0d st=%0d pcnt=%0d dreq=%b drdy=%b drv=%b len=%0d addr=%h gc_hit=%b issued=%0d dfc=%0d rdb=%0d rdc=%0d",
                cyc, u_blt.u_dl.st, u_blt.u_dl.pcnt, u_blt.u_dl.desc_req,
                u_blt.u_dl.desc_ready, u_blt.u_dl.desc_rvalid, u_blt.u_dl.desc_len,
                u_blt.u_dl.desc_addr, u_blt.u_dl.gc_hit, u_blt.u_dl.issued,
                u_blt.u_dl.df_count, u_blt.u_dl.rd_beats, u_blt.u_dl.rd_cnt);
        end
    end
`endif

    /* ================= 主流程 ================= */
    initial begin
        errors = 0; mon_en = 0;
        aw_cnt = 0; w_cnt = 0; b_cnt = 0; burst_max = 0; bp_max = 0;
        eng_act = 0; eng_gap = 0;

        #20 rst_n = 1'b1;
        #200;

        init_atlas();
        init_geom();
        init_scene();
        eng_init();

        /* ---------------- 0) 寄存器回读自检 ---------------- */
        $display("==== DL 寄存器映射自检 ====");
        axi_write(12'h4C, 32'h0000_6000);
        axi_read (12'h4C, rv); chk(rv === 32'h0000_6000, "DL_BASE0(0x4C) 回读");
        axi_write(12'h54, 32'd64);
        axi_read (12'h54, rv); chk(rv === 32'd64,        "DL_COUNT(0x54) 回读");
        axi_write(12'h88, {FB_H, FB_W});
        axi_read (12'h88, rv); chk(rv === {FB_H, FB_W},  "DL_FB_WH(0x88) 回读");
        axi_read (12'h80, rv); chk(rv === 32'h0210_0002, "DL_VERSION(0x80)=0x02100002");
        axi_write(12'h84, D_STRIDE[15:0]);
        axi_read (12'h84, rv); chk(rv === D_STRIDE,      "DL_DST_STRIDE(0x84) 回读");
        axi_read (12'h74, rv); chk(rv === 32'h0000_0483, "DL_CFG(0x74) 复位默认 0x483");
        axi_read (12'h78, rv); chk(rv === 32'd4096,      "DL_TIMEOUT(0x78) 复位默认 4096");
        /* 未对齐基地址：忽略写入（+ 置 DESC_RANGE，只有 DFU 存在时才会锁存） */
        axi_write(12'h4C, 32'h0000_6008);
        axi_read (12'h4C, rv); chk(rv === 32'h0000_6000, "未对齐 DL_BASE0 被忽略");
`ifndef DL_OFF
        axi_read (12'h60, rv); chk(rv[0] === 1'b1,       "未对齐写 ⇒ DL_ERR.DESC_RANGE");
        axi_write(12'h60, 32'hFFFF_FFFF);
        axi_read (12'h60, rv); chk(rv === 32'd0,         "DL_ERR W1C 清零");
`endif
        axi_write(12'h4C, 32'h0000_6000);

        /* ---------------- 1a) CPU 串行 push（金标准像素） ---------------- */
        $display("==== 1a) CPU push（串行口径，做金标准） ====");
        init_dst();
        t0 = cyc;
        for (n = 0; n < K; n = n + 1) begin
            cmd_of(n);
            push_cmd();
            wait_eng_start;
            wait_done_level;
        end
        ser_cyc = cyc - t0;
        snap_dst(1);

        /* ---------------- 1b) CPU 流水 push（只看引擎地板） ---------------- */
        $display("==== 1b) CPU push（流水口径） ====");
        init_dst();
        t0 = cyc; eng_act = 0; eng_gap = 0; mon_en = 1;
        for (n = 0; n < K; n = n + 1) begin
            cmd_of(n);
            push_cmd();
        end
        wait_eng_start;
        wait_done_level;
        mon_en = 0;
        pipe_cyc = cyc - t0;  pipe_eng = eng_act;
        snap_dst(0); cmp_dst();
        chk(mism == 0, "cpu_pipe 与 cpu_serial 像素一致（自检）");

        /* ---------------- 2) 描述符表路径 ---------------- */
        $display("==== 2) 描述符表 + DFU（S2 路径） ====");
        init_dst();
        build_list(K);
`ifdef DL_OFF
        snap_dst(1);                   // A/B：参考 = 刚铺好的背景（DFU 应当一个像素都不写）
`endif
        axi_write(12'h00, 32'h0);      // 关 CTRL.GO，让 AUTO_GO 真正成为启动源
        dl_config(16'd64, D_STRIDE[15:0]);
        aw_cnt = 0; w_cnt = 0; b_cnt = 0; burst_max = 0; bp_max = 0;
        eng_act = 0; eng_gap = 0; mon_en = 1;
        t0 = cyc;
`ifdef DL_OFF
        dl_go();
        for (i = 0; i < 20000; i = i + 1) @(posedge clk);
        mon_en = 0;
        list_cyc = cyc - t0; list_eng = eng_act;
        axi_read(12'h5C, rv);
        $display("DL-OFF: DL_STATUS=0x%h", rv);
        chk(eng_act === 0,                 "DL_OFF: 列表路径不产生任何命令（引擎零活动）");
        chk(u_blt.u_cmd.word_count === 12'd0, "DL_OFF: cmd_fifo 里一个字都没有");
        snap_dst(0); cmp_dst();
        chk(mism == 0, "DL_OFF: 列表路径一个像素都没写（画面 = 背景，逐字节）");
`else
        dl_go();
        dl_wait_done(t0);
        mon_en = 0;
        list_eng = eng_act;
        axi_read(12'h7C, list_perf);
        axi_read(12'h5C, rv);
        $display("DL: DL_STATUS=0x%h consumed=%0d dl_perf=%0d", rv, rv[31:16], list_perf);
        chk(rv[31:16] === 16'd64,                     "列表路径 consumed == K");
        chk(rv[1] === 1'b1 && rv[0] === 1'b0,         "列表路径 DONE=1 且 BUSY=0");
        chk((rv & 32'h4) === 0,                       "列表路径无 DL_ERR");
        snap_dst(0); cmp_dst();
        chk(mism == 0, "★列表路径与 CPU 路径逐字节相同");
        chk(bp_max <= 1,                              "写突发在飞峰值 b_pending <= 1（H2）");
        chk(u_blt.wd_count === 5'd0 && !u_blt.wd_busy && (b_pend === 5'd0),
            "DONE 时刻写通路彻底干净（H1）");
        $display("DL MIXED AW=%0d W=%0d B=%0d burst_max=%0d （混合场景各行不连续，突发天生合不到 16）",
                 aw_cnt, w_cnt, b_cnt, burst_max);
        $display("DL 每精灵总拍数 | cpu_serial=%0d (%0d/精灵) cpu_pipe=%0d (%0d/精灵) list=%0d DL_PERF=%0d",
                 ser_cyc, (ser_cyc - K*256)/K, pipe_cyc, (pipe_cyc - K*256)/K, list_cyc, list_perf);
`endif

        /* ---------------- 3) 16×16 FILL ×N：三种下发方式的开销对照 ----------------
         * 引擎地板（16 行 FILL）= POP15 + DEC1 + INIT1 + ROW_GAP16×3 + DRAIN16 + WDWAIT30 ≈ 111 拍 */
        $display("==== 3) 16x16 FILL x%0d 开销对照 ====", NOVH);
        begin : ovh
            integer t_a, t_b, t_c;
            init_scene_fill();
            /* 3a) CPU 串行：push 一条等一条（CPU 存储延迟全额暴露） */
            init_dst();
            axi_write(12'h00, 32'h1);              // 恢复 CTRL.GO
            push_accum = 0;
            ser_cyc = 0; mon_en = 1; eng_act = 0; eng_gap = 0;
            t_a = cyc;
            for (n = 0; n < NOVH; n = n + 1) begin
                cmd_of(n);
                push_cmd_timed();
                wait_eng_start;
                wait_done_level;
            end
            t_a = cyc - t_a;
            mon_en = 0;
            ser_eng = eng_act;
            ser_cyc = t_a;
            $display("DL OVH cpu_serial | K=%0d total=%0d push(CPU侧)=%0d (%.1f/精灵) eng_active=%0d | per_sprite=%0d",
                     NOVH, t_a, push_accum, push_accum*1.0/NOVH, ser_eng, (t_a - NOVH*256)/NOVH);

            /* 3b) CPU 流水：FIFO 预灌满，只剩引擎地板（同时量 CPU 路径的 AW/突发，
             *     用来证明"每条命令多 1 笔尾突发"是既有行为、与列表路径无关） */
            init_dst();
            aw_cnt = 0; w_cnt = 0; b_cnt = 0; burst_max = 0; bp_max = 0;
            for (i = 0; i <= 16; i = i + 1) bl_hist[i] = 0;
            eng_act = 0; eng_gap = 0; mon_en = 1;
            t_b = cyc;
            for (n = 0; n < NOVH; n = n + 1) begin
                cmd_of(n);
                push_cmd();
            end
            wait_eng_start;
            wait_done_level;
            t_b = cyc - t_b;
            mon_en = 0;
            pipe_eng = eng_act; pipe_cyc = t_b;
            $display("DL OVH cpu_pipe   | K=%0d total=%0d per_sprite=%0d eng_active=%0d AW=%0d W=%0d burst_max=%0d (AW-len 1/15/16 = %0d/%0d/%0d)",
                     NOVH, t_b, (t_b - NOVH*256)/NOVH, pipe_eng,
                     aw_cnt, w_cnt, burst_max, bl_hist[1], bl_hist[15], bl_hist[16]);

            /* 3c) 描述符表路径：写若干 MMIO + GO，展开与执行全部由硬件完成。
             *     纯 FILL ×NOVH 全部落在同一块连续 512B ⇒ 写突发能真正跑满 16 拍，
             *     于是 AW ≈ ⌈词数/16⌉ 这条口径才有意义。 */
`ifndef DL_OFF
            init_dst();
            build_list(NOVH);
            axi_write(12'h00, 32'h0);
            dl_config(NOVH[15:0], 16'd32);
            aw_cnt = 0; w_cnt = 0; b_cnt = 0; burst_max = 0; bp_max = 0;
            for (i = 0; i <= 16; i = i + 1) bl_hist[i] = 0;
            t_c = cyc;
            dl_go();
            dl_wait_done(t_c);
            axi_read(12'h7C, list_perf);
            $display("DL OVH list       | K=%0d total=%0d per_sprite=%0d (DL_PERF=%0d) AW=%0d W=%0d B=%0d burst_max=%0d",
                     NOVH, list_cyc, (list_cyc - NOVH*256)/NOVH, list_perf,
                     aw_cnt, w_cnt, b_cnt, burst_max);
            $display("DL OVH list AW理论 | ⌈6400/16⌉ = 400 笔（实测 %0d，多出 %0d）",
                     aw_cnt, aw_cnt - 400);
            for (i = 1; i <= 16; i = i + 1)
                if (bl_hist[i] != 0) $display("      AW-len %0d : %0d 笔", i, bl_hist[i]);
            chk(w_cnt === NOVH*32,        "列表路径 W 拍数 == 词数（纯 FILL 场景）");
            chk(burst_max === 16,         "★列表路径 burst_max == 16（写突发合并未失效）");
            chk(aw_cnt <= 400 + NOVH,     "列表路径 AW <= ⌈词数/16⌉ + 每条命令 1 笔（尾部常数）");
            chk(bp_max <= 1,              "列表路径 b_pending 峰值 <= 1");
`else
            $display("DL OVH list       | (DL_OFF：列表路径已旁路，无读数)");
`endif
        end

        if (errors == 0) $display("========== tb_dl_basic ALL PASS ==========");
        else             $display("========== tb_dl_basic FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #120_000_000;
        $display("!!!!!!!! tb_dl_basic WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end
endmodule
