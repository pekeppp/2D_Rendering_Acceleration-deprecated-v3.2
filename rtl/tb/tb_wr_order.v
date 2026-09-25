/* =========================================================================
 * tb_wr_order.v — 写提交顺序 / "引擎 IDLE 是否能当写完成用" 专项
 * -------------------------------------------------------------------------
 * 上板症状：软件轮询 STATUS.BUSY（blt_idle）后认为"这条指令的像素已经落 DDR"，
 * 但背靠背下发多条写重叠区域的指令时，重叠处 z 序会高频闪/换（纯 CPU 渲染没有）。
 *
 * 本 TB 要证的两件事（与 RTL 的两条判据一一对应）：
 *
 *  H1 洞：引擎完成一条指令（st: WDWAIT→IDLE）的那一拍，写通路是否真的已经干净？
 *        判据 = wd FIFO 真实占用(count)!=0 || 写主机还在忙 || 有已受理未回 B 的突发。
 *        旧 RTL 用 wd_empty(=out_v) 判完成，而 sync_fifo 的同步读流水让这个标志
 *        比"真的空"晚 2~3 拍 → 最后一个写词还在 FIFO 里就报 IDLE。
 *
 *  T1 提交：引擎报 IDLE 的**那一拍**，mem 里是否已经是本条指令的颜色？
 *  T2 RAW：cmd1 是 FILL，cmd2 是 COPY/ALPHA 且要**读回 cmd1 刚写的区域**——
 *        若 cmd2 的读跑在 cmd1 的写还没提交（还没收到 B）前面，读到旧值 → 像素错。
 *        对应屏幕上的 ALPHA/KEY 混合用了旧背景 → 重叠处看起来"层级被换掉"。
 *  T3 WAW：两条写同一区域的 FILL（颜色不同）+ 从机每笔提交延迟随机（可能乱序提交）
 *        → 最终像素必须是后一条指令的颜色（写-写顺序守卫）。
 *  T4 PERF：背靠背 32x32 FILL 的引擎周期数（屏障开/关的吞吐代价，A/B 可量化）。
 *
 * 从机模型 `axi_slave_mem_ord.v`：B 在**真正提交那一拍**才回；读只能看见已提交
 * 数据（写缓冲里未提交的读不到）。所以"提前读"必然读到旧值 —— 这是 TB 侧对
 * "主机不得假设内存系统替它排序"的直接建模，不是模型作弊。
 *
 * A/B：`-DBLT_WR_ORDER_OFF` 关掉新屏障（= 旧行为），H1/T1/T2 必须 FAIL；
 *      默认（屏障开）必须 ALL PASS。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_wr_order;
    localparam FB   = 32'h0000_2000;
    localparam DS   = 32'd64;          // 行距 64B = 32 px/行
    localparam FILL = 2'd1;
    localparam COPY = 2'd0;
    localparam ALPH = 2'd2;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    /* ---- AXI-Lite 主测口 ---- */
    reg  [11:0] awaddr = 0, araddr = 0;
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] wdata = 0;
    reg  [3:0]  wstrb = 4'hF;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [31:0] rdata;
    reg         bready = 1, rready = 1;

    /* ---- 引擎 AXI 主机 ---- */
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

    blt_top #(.AXI_DATA_W(128), .CMD_DEPTH(256)) u_dut (
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
        .irq_done(irq_done)
    );

    /* 行为 DDR：写提交延迟 dly_val（默认 128 拍，与本工程"真实写回延迟"量级一致；
     * 测吞吐时改成 2 拍 = "写通路跟得上"），dly_rand=1 时每笔随机 4..259 拍 */
    reg        dly_rand = 1'b0;
    reg [31:0] dly_val  = 32'd128;
    axi_slave_mem_ord #(.AXI_DATA_W(128), .MEM_BYTES(1 << 15),
                        .AR_LAT(8), .MAXO(4), .WBUF(4)) u_mem (
        .clk(clk), .rst_n(rst_n), .dly_rand(dly_rand), .dly_val(dly_val),
        .s_araddr(m_araddr), .s_arlen(m_arlen), .s_arsize(m_arsize), .s_arburst(m_arburst),
        .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata(m_rdata), .s_rresp(), .s_rlast(m_rlast), .s_rvalid(m_rvalid), .s_rready(m_rready),
        .s_awaddr(m_awaddr), .s_awlen(m_awlen), .s_awsize(m_awsize), .s_awburst(m_awburst),
        .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata), .s_wstrb(m_wstrb), .s_wlast(m_wlast), .s_wvalid(m_wvalid),
        .s_wready(m_wready),
        .s_bvalid(m_bvalid), .s_bresp(), .s_bready(m_bready)
    );

    integer errors = 0;
    integer i, k, r, bad;
    reg [31:0] rv;
    reg [15:0] pv;

    /* ---- 全局周期计数 ---- */
    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    task check;
        input [255:0] name;
        input ok;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* ---- AXI-Lite 读写（与 tb_blt_top.v 同款） ---- */
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
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata;
            #1;
            arvalid = 1'b0;
        end
    endtask

    task poke16;
        input [31:0] a; input [15:0] v;
        begin u_mem.mem[a] = v[7:0]; u_mem.mem[a+1] = v[15:8]; end
    endtask

    task peek16;
        input [31:0] a; output [15:0] v;
        begin v = {u_mem.mem[a+1], u_mem.mem[a]}; end
    endtask

    /* ============ 写通路"是否真的干净"的观测（只用旧 RTL 就有的信号） ============ */
    /* 真实占用 = mem 中未取 + 在飞 + 输出寄存器（sync_fifo 的 count 口径） */
    wire [12:0] wd_occ = u_dut.u_wd_fifo.mcnt
                       + (u_dut.u_wd_fifo.rd_pend ? 13'd1 : 13'd0)
                       + (u_dut.u_wd_fifo.out_v   ? 13'd1 : 13'd0);
    wire [2:0]  wr_st  = u_dut.u_wr.st;
    wire [2:0]  eng_st = u_dut.u_eng.st;

    integer tb_aw = 0, tb_b = 0;         // 主机引脚上数的 AW/B 握手数
    integer idle_cnt = 0, hole_cnt = 0;
    integer idle_occ, idle_wrst, idle_pend;
    integer perf_sum = 0, perf_max = 0, perf_min = 99999999, perf_cnt = 0;
    integer max_pend = 0, max_pend_tb = 0;   // 写突发"在飞"峰值（RTL 计数 / TB 引脚计数）
    reg [2:0] eng_d = 3'd0;

    reg        cap_arm = 1'b0;           // T1：在"报 IDLE 那一拍"抓 mem
    reg [15:0] cap_val = 16'hxxxx;
    reg [31:0] cap_addr = 32'd0;

    always @(posedge clk) begin
        if (m_awvalid && m_awready) tb_aw = tb_aw + 1;
        if (m_bvalid  && m_bready ) tb_b  = tb_b  + 1;
        if (u_dut.u_wr.b_pending > max_pend) max_pend = u_dut.u_wr.b_pending;
        if ((tb_aw - tb_b) > max_pend_tb) max_pend_tb = tb_aw - tb_b;
        if ((eng_d == 3'd3) && (eng_st == 3'd0)) begin     // WDWAIT → IDLE：一条指令"完成"
            idle_cnt  = idle_cnt + 1;
            idle_occ  = wd_occ;
            idle_wrst = wr_st;
            idle_pend = tb_aw - tb_b;
            if ((idle_occ != 0) || (idle_wrst != 0) || (idle_pend != 0)) begin
                hole_cnt = hole_cnt + 1;
                if (hole_cnt <= 4)
                    $display("  [HOLE] 引擎报 IDLE 时写通路未清: wd_occ=%0d wr_st=%0d 未回B=%0d (cyc=%0d)",
                             idle_occ, idle_wrst, idle_pend, cyc);
            end
            perf_sum = perf_sum + u_dut.u_eng.perf_cycles;
            perf_cnt = perf_cnt + 1;
            if (u_dut.u_eng.perf_cycles > perf_max)
                perf_max = u_dut.u_eng.perf_cycles;
            if (u_dut.u_eng.perf_cycles < perf_min)
                perf_min = u_dut.u_eng.perf_cycles;
            if (cap_arm) begin
                cap_val  = {u_mem.mem[cap_addr+1], u_mem.mem[cap_addr]};
                cap_arm  = 1'b0;
            end
        end
        eng_d <= eng_st;          // 非阻塞：t+1 拍才更新，才能当"上一拍状态"用
    end

    /* ---- 初始化 + 下发 8 字指令 ---- */
    reg go_on = 1'b0;
    task eng_init;
        begin
            axi_write(12'h00, 32'h4);          // SOFT_RST
            axi_write(12'h00, 32'h0);
            axi_write(12'h10, 32'hFFFFFFFF);   // 清 IRQ
            axi_write(12'h14, 32'h0);
            axi_write(12'h00, go_on ? 32'h1 : 32'h0);   // GO（顺序测试先不开，把两条都灌进 FIFO）
        end
    endtask

    task push_cmd;
        input [1:0]  op;
        input [31:0] sa, da, ss, ds;
        input [15:0] W, H;
        input [7:0]  alpha;
        input [15:0] color;
        begin
            axi_write(12'h08, {30'd0, op});
            axi_write(12'h08, sa);
            axi_write(12'h08, da);
            axi_write(12'h08, ss);
            axi_write(12'h08, ds);
            axi_write(12'h08, {H, W});
            axi_write(12'h08, {8'd0, alpha});
            axi_write(12'h08, {16'd0, color});
        end
    endtask

    task wait_idle_n;
        input integer n;
        integer base;
        begin
            base = idle_cnt;
            while (idle_cnt < base + n) @(negedge clk);
        end
    endtask

    /* 目标绝对计数版：指令在"推送过程中"就可能做完，必须用绝对目标等，
     * 否则会等一个永远不会再涨的差值（TB 自己坑自己） */
    task wait_idle_to;
        input integer target;
        begin
            while (idle_cnt < target) @(negedge clk);
        end
    endtask

    /* 把写通路 + 从机写缓冲排空（测试之间用；SOFT_RST 不能打断在飞的突发） */
    task drain_all;
        integer g, b2;
        begin
            g = 0;
            while (g < 20) begin
                @(negedge clk);
                b2 = 0;
                for (i = 0; i < 4; i = i + 1) if (u_mem.wb_v[i]) b2 = b2 + 1;
                if ((wd_occ == 0) && (wr_st == 0) && (b2 == 0) && !u_mem.wbusy)
                    g = g + 1;
                else
                    g = 0;
            end
        end
    endtask

    integer t0, base_hole;

    initial begin
        $display("=== tb_wr_order: 写提交顺序 / IDLE 语义专项 ===");
`ifdef BLT_WR_ORDER_OFF
        $display("--- 屏障：OFF（-DBLT_WR_ORDER_OFF，旧行为，A 组） ---");
`else
        $display("--- 屏障：ON（默认，新行为，B 组） ---");
`endif
        rst_n = 1'b0;
        #20 rst_n = 1'b1;
        repeat (5) @(negedge clk);
        go_on = 1'b0;

        /* ================= T1：引擎报 IDLE 那一拍，写是否已提交 ================= */
        /* 用 8x1（=1 个写词）的 FILL：写通路本来就地清空，最后一个词刚推进 FIFO 时
         * wd_empty 还在"假空"窗口里 → 旧 RTL 会在词没写出去时就报 IDLE。 */
        $display("--- T1 FILL 8x1：报告 IDLE 当拍读 mem（应已是本条颜色） ---");
        for (i = 0; i < 256; i = i + 2) poke16(FB + i, 16'h1111);
        drain_all();
        eng_init();
        base_hole = hole_cnt;
        push_cmd(FILL, 32'd0, FB, 32'd0, DS, 16'd8, 16'd1, 8'hFF, 16'hABCD);
        cap_addr = FB + 14;                 // 该词（px0..7）的最后一个像素
        cap_arm  = 1'b1;
        axi_write(12'h00, 32'h1);           // GO
        wait_idle_n(1);
        check("T1 idle => committed", cap_val == 16'hABCD);
        $display("      IDLE 当拍采样: addr=%h val=%h (期望 ABCD)", cap_addr, cap_val);

        /* ================= T2：FILL 之后 COPY 回读同一区域（RAW） ================= */
        $display("--- T2 FILL -> COPY（cmd2 要读 cmd1 刚写的字） ---");
        cap_arm = 1'b0;
        drain_all();
        for (i = 0; i < 16; i = i + 2) poke16(32'h2100 + i, 16'h0000);
        for (i = 0; i < 32; i = i + 2) poke16(32'h2200 + i, 16'hEEEE);
        eng_init();                          // GO 先不开：两条指令一起灌进 FIFO，背靠背执行
        push_cmd(FILL, 32'd0,   32'h2100, 32'd0, DS, 16'd8, 16'd1, 8'hFF, 16'h1234);
        push_cmd(COPY, 32'h2100, 32'h2200, DS,   DS, 16'd8, 16'd1, 8'h00, 16'h0000);
        axi_write(12'h00, 32'h1);            // GO：引擎连着做两条
        wait_idle_n(2);
        bad = 0;
        for (i = 0; i < 16; i = i + 2) begin
            peek16(32'h2200 + i, pv);
            if (pv !== 16'h1234) begin
                bad = bad + 1;
                if (bad <= 3) $display("      COPY 后 x=%0d got=%h exp=1234 (读到旧值)", i/2, pv);
            end
        end
        check("T2 read fresh write OK", bad == 0);

        /* ================= T2b：FILL 之后 ALPHA(a=0) 覆盖同一区域（RAW on dst） ============ */
        $display("--- T2b FILL -> ALPHA(a=0)（dst 读 = cmd1 刚写的字） ---");
        cap_arm = 1'b0;
        drain_all();
        for (i = 0; i < 32; i = i + 2) poke16(32'h2400 + i, 16'h3333);   // fg 源
        for (i = 0; i < 32; i = i + 2) poke16(32'h2300 + i, 16'h4444);   // dst 旧值
        eng_init();
        push_cmd(FILL, 32'd0,   32'h2300, 32'd0, DS, 16'd8, 16'd1, 8'hFF, 16'h5678);
        push_cmd(ALPH, 32'h2400, 32'h2300, DS,   DS, 16'd8, 16'd1, 8'h00, 16'h0000);
        axi_write(12'h00, 32'h1);
        wait_idle_n(2);
        bad = 0;
        for (i = 0; i < 16; i = i + 2) begin
            peek16(32'h2300 + i, pv);
            if (pv !== 16'h5678) begin
                bad = bad + 1;
                if (bad <= 3) $display("      ALPHA(a=0) 后 x=%0d got=%h exp=5678 (读到旧 dst=4444)", i/2, pv);
            end
        end
        check("T2b read fresh dst OK", bad == 0);

        /* ================= T3：两条写重叠区域的 FILL（WAW 守卫，提交延迟随机） ============ */
        $display("--- T3 两条重叠 FILL（颜色不同）+ 每笔提交延迟随机 ---");
        dly_rand = 1'b1;
        cap_arm  = 1'b0;
        drain_all();
        for (r = 0; r < 24; r = r + 6) begin
            drain_all();                     // 保证 SOFT_RST 不打断在飞突发
            eng_init();                      // GO 先不开
            for (i = 0; i < 6; i = i + 1) begin
                push_cmd(FILL, 32'd0, FB + (r+i)*256,      32'd0, DS, 16'd32, 16'd1,
                         8'hFF, 16'h1000 + (r+i));
                push_cmd(FILL, 32'd0, FB + (r+i)*256 + 48, 32'd0, DS, 16'd8,  16'd1,
                         8'hFF, 16'h2000 + (r+i));
            end
            axi_write(12'h00, 32'h1);        // GO：12 条背靠背
            wait_idle_n(12);
        end
        drain_all();                         // 先等写通路/内存排空，再查"写序"本身
        bad = 0;
        for (r = 0; r < 24; r = r + 1)
            for (i = 48; i < 64; i = i + 2) begin
                peek16(FB + r*256 + i, pv);
                if (pv !== (16'h2000 + r[15:0])) begin
                    bad = bad + 1;
                    if (bad <= 3) $display("      重叠处 r=%0d x=%0d got=%h exp=%h (旧指令颜色赢了)",
                                           r, i/2, pv, 16'h2000 + r[15:0]);
                end
            end
        check("T3 last color wins", bad == 0);
        dly_rand = 1'b0;

        /* ================= T4：PERF（背靠背 32x32 FILL，屏障开/关的吞吐代价） ============ */
        $display("--- T4a PERF: 16 x FILL 32x32 背靠背（写回延迟 2 拍 = 写通路跟得上） ---");
        dly_val = 32'd2;
        drain_all();
        eng_init();
        perf_sum = 0; perf_max = 0; perf_min = 99999999; perf_cnt = 0;
        t0 = cyc;
        base_hole = idle_cnt;
        push_cmd(FILL, 32'd0, FB, 32'd0, DS, 16'd32, 16'd32, 8'hFF, 16'h0F0F);
        axi_write(12'h00, 32'h1);
        for (i = 1; i < 16; i = i + 1)
            push_cmd(FILL, 32'd0, FB + i*2, 32'd0, DS, 16'd32, 16'd32, 8'hFF, 16'h0F0F);
        wait_idle_to(base_hole + 16);
        $display("PERF-B2: cmds=%0d perf_min=%0d perf_avg=%0d perf_max=%0d wall=%0d cycles",
                 perf_cnt, perf_min, perf_sum / (perf_cnt == 0 ? 1 : perf_cnt), perf_max, cyc - t0);

        $display("--- T4b PERF: 同 16 条（写回延迟 128 拍 = 写通路成为瓶颈） ---");
        dly_val = 32'd128;
        drain_all();
        eng_init();
        perf_sum = 0; perf_max = 0; perf_min = 99999999; perf_cnt = 0;
        t0 = cyc;
        base_hole = idle_cnt;
        push_cmd(FILL, 32'd0, FB, 32'd0, DS, 16'd32, 16'd32, 8'hFF, 16'h0F0F);
        axi_write(12'h00, 32'h1);
        for (i = 1; i < 16; i = i + 1)
            push_cmd(FILL, 32'd0, FB + i*2, 32'd0, DS, 16'd32, 16'd32, 8'hFF, 16'h0F0F);
        wait_idle_to(base_hole + 16);
        $display("PERF-B128: cmds=%0d perf_min=%0d perf_avg=%0d perf_max=%0d wall=%0d cycles",
                 perf_cnt, perf_min, perf_sum / (perf_cnt == 0 ? 1 : perf_cnt), perf_max, cyc - t0);

        /* 最坏形态：每条指令只写 1 个词 → 指令尾部写通路一定是空的，
         * 屏障的代价 = 完整一次"最后写词 → AW/W → B"往返，不会被队列掩盖。 */
        $display("--- T4c PERF: 16 x FILL 8x1（尾部写通路空）+ 写回延迟 2 拍 ---");
        dly_val = 32'd2;
        drain_all();
        eng_init();
        perf_sum = 0; perf_max = 0; perf_min = 99999999; perf_cnt = 0;
        t0 = cyc;
        base_hole = idle_cnt;
        push_cmd(FILL, 32'd0, FB, 32'd0, DS, 16'd8, 16'd1, 8'hFF, 16'h1111);
        axi_write(12'h00, 32'h1);
        for (i = 1; i < 16; i = i + 1)
            push_cmd(FILL, 32'd0, FB + i*64, 32'd0, DS, 16'd8, 16'd1, 8'hFF, 16'h1111);
        wait_idle_to(base_hole + 16);
        $display("PERF-W1-B2: cmds=%0d perf_min=%0d perf_avg=%0d perf_max=%0d wall=%0d cycles",
                 perf_cnt, perf_min, perf_sum / (perf_cnt == 0 ? 1 : perf_cnt), perf_max, cyc - t0);

        $display("--- T4d PERF: 同 16 条，写回延迟 32 拍 ---");
        dly_val = 32'd32;
        drain_all();
        eng_init();
        perf_sum = 0; perf_max = 0; perf_min = 99999999; perf_cnt = 0;
        t0 = cyc;
        base_hole = idle_cnt;
        push_cmd(FILL, 32'd0, FB, 32'd0, DS, 16'd8, 16'd1, 8'hFF, 16'h1111);
        axi_write(12'h00, 32'h1);
        for (i = 1; i < 16; i = i + 1)
            push_cmd(FILL, 32'd0, FB + i*64, 32'd0, DS, 16'd8, 16'd1, 8'hFF, 16'h1111);
        wait_idle_to(base_hole + 16);
        $display("PERF-W1-B32: cmds=%0d perf_min=%0d perf_avg=%0d perf_max=%0d wall=%0d cycles",
                 perf_cnt, perf_min, perf_sum / (perf_cnt == 0 ? 1 : perf_cnt), perf_max, cyc - t0);
        dly_val = 32'd128;

        /* ============ H1：总洞数（每条指令都必须在写干净之后才报完成） ============ */
        $display("--- H1 洞统计: 完成事件 %0d 次, 写通路未清 %0d 次 ---", idle_cnt, hole_cnt);
        check("H1 no write word left at done", hole_cnt == 0);

        /* ============ H2：写突发在飞数（结构性事实：AW→W→B 串行 → 恒 ≤1） ============ */
        $display("--- H2 写突发在飞峰值: RTL b_pending=%0d, TB 引脚计数=%0d ---",
                 max_pend, max_pend_tb);
        check("H2 <=1 wr burst outstanding", (max_pend <= 1) && (max_pend_tb <= 1));
        check("H2b RTL b_pending == pin count", max_pend == max_pend_tb);

        if (errors == 0) $display("========== tb_wr_order ALL PASS ==========");
        else             $display("========== tb_wr_order FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #40_000_000;
        $display("!!!!!!!! tb_wr_order WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
