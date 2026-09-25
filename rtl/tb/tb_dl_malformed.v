/* =========================================================================
 * tb_dl_malformed.v — 显示列表畸形列表保护（S2）
 * -------------------------------------------------------------------------
 * 覆盖（任务书"必须的证据"第 3 条 + 设计文档 §8）：
 *   M1  条数超上限：DL_COUNT = 5000 (> DL_COUNT_MAX=4095)          → DESC_COUNT
 *   M2  条数 = 0（合法空列表）：GO 后应立刻 DONE，不取指、不报错
 *   M3  描述符 SPR_ID 越出几何表（DL_GEOM_MAX=8，用 SPR_ID=9）      → GEOM_INDEX
 *   M4  列表源地址跑出映射内存（BASE 靠 32bit 顶端，COUNT 使尾部回绕）→ DESC_RANGE
 *   M5  ABORT 在列表中途：只停"还没进 FIFO 的命令"，已入队跑完      → ABORTED
 *   M6  描述符 W=0（SIZE_OVR 给 0）                                  → ZERO_SIZE
 *   M7  从机永不回 R（读通道被钉住）→ 看门狗                         → WATCHDOG
 *   M8a 未对齐 DL_BASE                                               → DESC_RANGE
 *   M8b X 越屏 + STRICT_BOUNDS=1                                     → SPRITE_BOUNDS
 *   M8c X 越屏 + CLIP_EN=1（自动裁剪，不报错）
 *   M9  MIRROR_X 置位（S2 明确不实现）                               → UNSUPPORTED(bit24)
 *   收尾 清错后同一张表可正常跑完（恢复路径，不需要 SOFT_RST）
 *
 * 每种都必须：在**有限拍内**落到 BUSY=0 + 正确的 DL_ERR 位 + 正确的 DL_ERR[23:16]
 * 序号 + DL_FAULT_ADDR；已入 FIFO 的命令必须跑完（不撕裂）。
 * 编译运行同 tb_dl_basic（把模块名换掉即可）。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_dl_malformed;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    localparam [31:0] ATLAS    = 32'h0000_0000;
    localparam [31:0] DST      = 32'h0000_1000;
    localparam [31:0] LIST     = 32'h0000_6000;
    localparam [31:0] GEOM     = 32'h0000_7000;
    localparam [31:0] A_STRIDE = 32'd128;
    localparam [31:0] D_STRIDE = 32'd256;
    localparam [15:0] FB_W = 16'd128, FB_H = 16'd64;
    localparam integer NSPR = 8;

    reg  [11:0] awaddr = 0, araddr = 0;
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] wdata = 0;
    reg  [3:0]  wstrb = 4'hF;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [31:0] rdata;
    reg         bready = 1, rready = 1;

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
    wire        m_rready;
    wire        irq_done;

    reg  [1:0]  fb_cur_sel_r = 2'd0;
    wire [1:0]  m_rresp = 2'b00;   // RRESP 必须显式接 0（悬空成 Z 会让判据变 X）

    /* ★ M7 用：把读通道钉死（AR 永不受理、R 永不接收），逼出看门狗。
     *   两侧都要挡：只把 rvalid 从主机视野藏起来，从机照样认为数据发走了
     *   （它看的是自己的 rvalid&rready）；只挡从机的 arready，从机仍会自己
     *   受理 AR（它看的是自己寄存的 arready）而主机的 AR 永不完成 —— 两者都是
     *   死锁模型，不是"从机不回 R"。只影响本 TB 的从机模型，RTL 一行没改。 */
    reg         stall_reads = 1'b0;
    wire        m_arvalid_g;
    wire        m_arready_g;
    wire        m_rready_g;
    assign      m_arvalid_g = stall_reads ? 1'b0 : m_arvalid;   // 从机侧：看不到请求
    assign      m_arready_g = stall_reads ? 1'b0 : m_arready;   // 主机侧：看不到受理
    assign      m_rready_g  = stall_reads ? 1'b0 : m_rready;    // 从机侧：收不到接收

    blt_top #(.AXI_DATA_W(128), .CMD_DEPTH(256)) u_blt (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb),
        .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bvalid(bvalid), .s_axil_bresp(), .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(), .s_axil_rvalid(rvalid), .s_axil_rready(rready),
        .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arvalid(m_arvalid), .m_axi_arready(m_arready_g),
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
        .s_arburst(m_arburst), .s_arvalid(m_arvalid_g), .s_arready(m_arready),
        .s_rdata(m_rdata), .s_rresp(), .s_rlast(m_rlast),
        .s_rvalid(m_rvalid), .s_rready(m_rready_g),
        .s_awaddr(m_awaddr), .s_awlen(m_awlen), .s_awsize(m_awsize),
        .s_awburst(m_awburst), .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata), .s_wstrb(m_wstrb), .s_wlast(m_wlast),
        .s_wvalid(m_wvalid), .s_wready(m_wready),
        .s_bvalid(m_bvalid), .s_bresp(), .s_bready(m_bready)
    );

    integer errors = 0;
    integer i, n, rv, ev, fv;

    /* DFU 状态追踪（诊断；trace_on 由用例打开） */
    reg     trace_on = 1'b0;
    integer trc_n = 0;
    always @(posedge clk) begin
        if (trace_on && (trc_n < 80) && (u_blt.u_dl.st != 4'd0)) begin
            trc_n = trc_n + 1;
            $display("   [T] t=%0d st=%0d wdcnt=%0d issued=%0d consumed=%0d err=0x%h unsync=%b dfc=%0d rdb=%0d rdc=%0d",
                cyc, u_blt.u_dl.st, u_blt.u_dl.wd_cnt, u_blt.u_dl.issued,
                u_blt.u_dl.consumed_r, u_blt.u_dl.err_r, u_blt.u_dl.unsync,
                u_blt.u_dl.df_count, u_blt.u_dl.rd_beats, u_blt.u_dl.rd_cnt);
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

    task axi_write;
        input [11:0] addr; input [31:0] data;
        begin
            awaddr = addr; awvalid = 1'b1;
            wdata  = data; wstrb  = 4'hF; wvalid = 1'b1;
            while (!(bvalid && bready)) @(posedge clk);
            #1; awvalid = 1'b0; wvalid = 1'b0;
        end
    endtask

    task axi_read;
        input [11:0] addr; output [31:0] rd;
        begin
            araddr = addr; arvalid = 1'b1;
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata; #1; arvalid = 1'b0;
        end
    endtask

    task poke16;
        input [31:0] a; input [15:0] v;
        begin u_mem.mem[a] = v[7:0]; u_mem.mem[a+1] = v[15:8]; end
    endtask
    task poke32;
        input [31:0] a; input [31:0] v;
        begin u_mem.mem[a]   = v[7:0];   u_mem.mem[a+1] = v[15:8];
              u_mem.mem[a+2] = v[23:16]; u_mem.mem[a+3] = v[31:24]; end
    endtask

    /* 一条描述符：位置 / 几何索引 / FLAGS / KEY / W_OVR / H_OVR */
    task put_desc;
        input integer idx;
        input [15:0] x, y, spr;
        input [15:0] flags;
        input [15:0] key;
        input [7:0]  wovr, hovr;
        begin
            poke16(LIST + idx*16 + 0,  x);
            poke16(LIST + idx*16 + 2,  y);
            poke16(LIST + idx*16 + 4,  spr);
            poke16(LIST + idx*16 + 6,  flags);
            poke16(LIST + idx*16 + 8,  key);
            poke16(LIST + idx*16 + 10, 16'd0);
            poke16(LIST + idx*16 + 12, 16'd0);
            poke16(LIST + idx*16 + 14, {hovr, wovr});
        end
    endtask

    task init_geom;
        begin
            for (n = 0; n < NSPR; n = n + 1) begin
                poke32(GEOM + n*16 + 0,  ATLAS);
                poke16(GEOM + n*16 + 4,  A_STRIDE[15:0]);
                poke16(GEOM + n*16 + 6,  16'hF81F);
                poke16(GEOM + n*16 + 8,  16'd16);
                poke16(GEOM + n*16 + 10, 16'd16);
                poke16(GEOM + n*16 + 12, 16'd0);
                poke16(GEOM + n*16 + 14, 16'd0);
            end
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

    task dl_cfg_common;
        begin
            axi_write(12'h4C, LIST);
            axi_write(12'h50, LIST);
            axi_write(12'h68, GEOM);
            axi_write(12'h6C, 16'd8);              // DL_GEOM_MAX = 8
            axi_write(12'h70, DST);
            axi_write(12'h84, 16'd32);
            axi_write(12'h88, {FB_H, FB_W});
            axi_write(12'h74, 32'h0000_0483);
            axi_write(12'h78, 32'd400);            // 看门狗 400 拍（缩短用例时长）
            axi_write(12'h60, 32'hFFFF_FFFF);      // 清 DL_ERR
            /* 注意：这里**不能**写 DL_CTRL.GO —— 那会立刻启动一次列表。
             * AUTO_GO / STRICT 的复位默认就是 1，由 run_case 里的 GO 一并写入。 */
        end
    endtask

    /* 等列表落定（BUSY=0）；有限拍内必须落 */
    integer wait_cycles;
    task dl_settle;
        input integer limit;
        begin
            wait_cycles = 0;
            for (i = 0; i < limit; i = i + 1) begin
                axi_read(12'h5C, rv);
                wait_cycles = wait_cycles + 1;
                if (!(rv & 32'h1)) disable dl_settle;
            end
            $display("FAIL: 列表未在 %0d 次轮询内落定（DL_STATUS=0x%h）", limit, rv);
            errors = errors + 1;
        end
    endtask

    /* 完整用例：配置 → GO → 落定 → 回读 DL_STATUS / DL_ERR / DL_FAULT_ADDR */
    task run_case;
        input [15:0] count;
        input [31:0] base;
        input [255:0] name;
        output [31:0] st_out;
        output [31:0] err_out;
        output [31:0] flt_out;
        reg [31:0] cfg_rd;
        begin
            axi_read (12'h5C, st_out);
            axi_write(12'h54, {16'd0, count});
            axi_write(12'h4C, base);
            axi_write(12'h60, 32'hFFFF_FFFF);      // 清 DL_ERR
            axi_read (12'h54, cfg_rd);
            if (cfg_rd !== {16'd0, count}) begin
                $display("FAIL: [%0s] DL_COUNT 写不进去（读回 %0d，期望 %0d），入口 STATUS=0x%h",
                         name, cfg_rd, count, st_out);
                errors = errors + 1;
            end
            axi_write(12'h58, 32'h31);             // GO | AUTO_GO | STRICT
            dl_settle(4000);
            axi_read(12'h5C, st_out);
            axi_read(12'h60, err_out);
            axi_read(12'h64, flt_out);
            $display("  [%0s] STATUS=0x%h ERR=0x%h FAULT=0x%h idx=%0d wait=%0d | arq=%0d rq=%0d rdbusy=%b",
                     name, st_out, err_out, flt_out, err_out[23:16], wait_cycles,
                     u_blt.u_rd.arq_cnt, u_blt.u_rd.rq_cnt, u_blt.u_rd.rd_busy);
        end
    endtask

    initial begin
        errors = 0;
        #20 rst_n = 1'b1;
        #200;

        for (i = 0; i < 32; i = i + 1)
            for (n = 0; n < 64; n = n + 1)
                poke16(ATLAS + i*A_STRIDE + n*2, 16'h0800 + i*4 + (n & 3));
        init_geom();
        for (i = 0; i < 64; i = i + 1)
            for (n = 0; n < 128; n = n + 1)
                poke16(DST + i*D_STRIDE + n*2, 16'h1000);

        eng_init();
        dl_cfg_common();

        /* ---------------- M1 条数超上限 ---------------- */
        $display("==== M1 DL_COUNT > 4095 ====");
        put_desc(0, 0, 0, 0, 16'h0001, 16'h07E0, 8'd0, 8'd0);
        run_case(16'd5000, LIST, "M1", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M1 BUSY=0");
        chk(ev[6] === 1'b1,            "M1 DL_ERR.DESC_COUNT(bit6)");
        chk((rv & 32'h4) === 32'h4,    "M1 DL_STATUS.ERR=1");
        chk(ev[23:16] === 8'd0,        "M1 出错序号=0");
        chk(fv === LIST,               "M1 DL_FAULT_ADDR = 列表基地址");
        chk(u_blt.u_dl.consumed_r === 16'd0, "M1 一条描述符都没下发");

        /* ---------------- M2 条数 = 0（合法空列表） ---------------- */
        $display("==== M2 DL_COUNT = 0 ====");
        run_case(16'd0, LIST, "M2", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M2 BUSY=0");
        chk((rv & 32'h2) === 32'h2,    "M2 DONE=1（空列表立刻完成）");
        chk((rv & 32'h4) === 0,        "M2 无 ERR");
        chk(rv[31:16] === 16'd0,       "M2 consumed=0");

        /* ---------------- M3 SPR_ID 越出几何表 ---------------- */
        $display("==== M3 SPR_ID=9 >= DL_GEOM_MAX=8 ====");
        put_desc(0, 0, 0, 0, 16'h0001, 16'h07E0, 8'd0, 8'd0);
        put_desc(1, 16, 0, 9, 16'h0001, 16'h07E0, 8'd0, 8'd0);
        put_desc(2, 32, 0, 0, 16'h0401, 16'h07E0, 8'd0, 8'd0);
        run_case(16'd3, LIST, "M3", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M3 BUSY=0");
        chk(ev[1] === 1'b1,            "M3 DL_ERR.GEOM_INDEX(bit1)");
        chk(ev[23:16] === 8'd1,        "M3 出错序号=1（第 2 条）");
        chk(fv === GEOM + 32'd144,     "M3 DL_FAULT_ADDR = GEOM_BASE + 9*16");
        chk(u_blt.u_dl.consumed_r === 16'd1, "M3 序号 0 已下发，序号 1 起停止");

        /* ---------------- M4 列表源地址跑出映射内存（32bit 回绕） ---------------- */
        $display("==== M4 列表尾越出 32bit 地址空间 ====");
        put_desc(0, 0, 0, 0, 16'h0001, 16'h07E0, 8'd0, 8'd0);
        run_case(16'd16, 32'hFFFF_FFF0, "M4", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M4 BUSY=0");
        chk(ev[0] === 1'b1,            "M4 DL_ERR.DESC_RANGE(bit0)");
        chk(fv === 32'hFFFF_FFF0,      "M4 DL_FAULT_ADDR = 越界基地址");
        chk(u_blt.u_dl.consumed_r === 16'd0, "M4 一条都没取");

        /* ---------------- M5 ABORT 中途 ---------------- */
        $display("==== M5 中途 ABORT ====");
        for (n = 0; n < 64; n = n + 1)
            put_desc(n, ((n*13) % 112), ((n*7) % 48), (n % NSPR),
                     ((n == 63) ? 16'h0401 : 16'h0001), 16'h07E0, 8'd0, 8'd0);
        axi_read (12'h5C, rv);
        axi_write(12'h54, 16'd64);
        axi_write(12'h4C, LIST);
        axi_write(12'h60, 32'hFFFF_FFFF);
        axi_write(12'h58, 32'h31);              // GO
        for (i = 0; (i < 200000) && (u_blt.u_dl.consumed_r < 16'd12); i = i + 1)
            @(posedge clk);
        axi_read(12'h5C, rv);
        $display("  ABORT 前: consumed=%0d STATUS=0x%h", rv[31:16], rv);
        axi_write(12'h58, 32'h02);              // ABORT（只写 bit1）
        dl_settle(8000);
        axi_read(12'h5C, rv);
        axi_read(12'h60, ev);
        $display("  ABORT 后: STATUS=0x%h ERR=0x%h consumed=%0d", rv, ev, rv[31:16]);
        chk((rv & 32'h1) === 0,        "M5 BUSY=0（已入 FIFO 的命令跑完）");
        chk(rv[3] === 1'b1,            "M5 DL_STATUS.ABORTED=1");
        chk((rv & 32'h4) === 0,        "M5 ABORT 不写 DL_ERR");
        chk(ev === 32'd0,              "M5 DL_ERR 全 0");
        chk(rv[31:16] < 16'd64,        "M5 consumed < COUNT（取指真的被停住）");
        chk(u_blt.u_cmd.word_count === 12'd0 && u_blt.wd_count === 5'd0 &&
            !u_blt.wd_busy && (u_blt.wr_b_pending === 5'd0),
            "M5 停止时写通路彻底干净（没有半条命令被撕开）");

        /* ---------------- M6 尺寸为 0（SIZE_OVR 给 0） ---------------- */
        $display("==== M6 W=0（SIZE_OVR） ====");
        put_desc(0, 0, 0, 0, 16'h0021, 16'h07E0, 8'd0, 8'd0);   // SIZE_OVR=1, W_OVR=0
        put_desc(1, 16, 0, 0, 16'h0401, 16'h07E0, 8'd0, 8'd0);
        run_case(16'd2, LIST, "M6", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M6 BUSY=0");
        chk(ev[7] === 1'b1,            "M6 DL_ERR.ZERO_SIZE(bit7)");
        chk(ev[23:16] === 8'd0,        "M6 出错序号=0");
        chk(u_blt.u_dl.consumed_r === 16'd0, "M6 一条都没下发");

        /* ---------------- M7 从机永不回 R → 看门狗 ---------------- */
        $display("==== M7 读通道钉死 → WATCHDOG ====");
        put_desc(0, 0, 0, 0, 16'h0401, 16'h07E0, 8'd0, 8'd0);
        stall_reads = 1'b1;
        run_case(16'd1, LIST, "M7", rv, ev, fv);
        stall_reads = 1'b0;
        for (i = 0; i < 4000; i = i + 1) @(posedge clk);   // 让残留 AR 走完
        chk((rv & 32'h1) === 0,        "M7 BUSY=0（看门狗把它变成一次可诊断的 ERR）");
        chk(ev[4] === 1'b1,            "M7 DL_ERR.WATCHDOG(bit4)");
        chk(fv === LIST,               "M7 DL_FAULT_ADDR = 停住那一步的地址");
        chk(u_blt.u_dl.consumed_r === 16'd0, "M7 一条都没下发");

        /* ---------------- M8a 未对齐基地址 ---------------- */
        $display("==== M8a DL_BASE 未 16B 对齐 ====");
        axi_write(12'h60, 32'hFFFF_FFFF);
        axi_write(12'h4C, LIST + 32'd8);
        axi_read (12'h60, ev);
        axi_read (12'h4C, rv);
        chk(ev[0] === 1'b1,            "M8a DL_ERR.DESC_RANGE");
        chk(rv === LIST,               "M8a 未对齐写入被忽略（读回仍是旧值）");

        /* ---------------- M8b 越屏且 STRICT_BOUNDS=1 ---------------- */
        $display("==== M8b X 越屏 + STRICT_BOUNDS=1 ====");
        put_desc(0, 120, 0, 0, 16'h0401, 16'h07E0, 8'd0, 8'd0);  // X=120, W=16 → 出屏
        run_case(16'd1, LIST, "M8b", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M8b BUSY=0");
        chk(ev[3] === 1'b1,            "M8b DL_ERR.SPRITE_BOUNDS(bit3)");
        chk(u_blt.u_dl.consumed_r === 16'd0, "M8b 一条都没下发");

        /* ---------------- M8c CLIP_EN=1 时不报错（自动裁剪） ---------------- */
        $display("==== M8c X 越屏 + CLIP_EN=1 ====");
        put_desc(0, 120, 0, 0, 16'h0411, 16'h07E0, 8'd0, 8'd0);  // CLIP_EN=1
        run_case(16'd1, LIST, "M8c", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M8c BUSY=0");
        chk((rv & 32'h4) === 0,        "M8c CLIP_EN 不报 SPRITE_BOUNDS");
        chk((rv & 32'h2) === 32'h2,    "M8c DONE=1");

        /* ---------------- M9 MIRROR_X（S2 明确不实现） ---------------- */
        $display("==== M9 MIRROR_X → UNSUPPORTED ====");
        put_desc(0, 0, 0, 0, 16'h0405, 16'h07E0, 8'd0, 8'd0);    // FLAGS[2]=MIRROR_X
        run_case(16'd1, LIST, "M9", rv, ev, fv);
        chk((rv & 32'h1) === 0,        "M9 BUSY=0");
        chk(ev[24] === 1'b1,           "M9 DL_ERR.UNSUPPORTED(bit24，保留位)");
        chk(ev[7:0] === 8'd0,          "M9 低 8 位错误位全 0");

        /* ---------------- 收尾：清错后恢复 ---------------- */
        axi_write(12'h60, 32'hFFFF_FFFF);
        axi_read (12'h60, ev);
        chk(ev === 32'd0,              "全部 DL_ERR W1C 可清（无需 SOFT_RST）");
        put_desc(0, 0, 0, 0, 16'h0401, 16'h07E0, 8'd0, 8'd0);
        run_case(16'd1, LIST, "RECOVER", rv, ev, fv);
        chk((rv & 32'h2) === 32'h2 && (rv & 32'h4) === 0,
            "清错后同一张表可正常跑完（恢复路径）");

        if (errors == 0) $display("========== tb_dl_malformed ALL PASS ==========");
        else             $display("========== tb_dl_malformed FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #120_000_000;
        $display("!!!!!!!! tb_dl_malformed WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end
endmodule
