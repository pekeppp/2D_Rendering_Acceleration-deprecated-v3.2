/* =========================================================================
 * tb_scanout_lut.v — ★S5（v3.2）扫描输出颜色 LUT 专项（fb_scanout 单元级）
 * -------------------------------------------------------------------------
 * 覆盖四条承诺（`doc/性能优化成果与计划.md` §7.5 的验收标准 ①）：
 *   ① **关闭即逐位兼容**：LUT_CTRL.bit0=0（复位默认）时，屏幕上每个 DE 像素都等于
 *      "RGB565 → RGB888 位复制"的老输出（逐像素比对，不是抽样）；
 *   ② **恒等表逐位无损**：开 LUT 且表内容 LUT[i]=i（三通道各 256 项）时，输出与①
 *      **逐像素相同** —— 表值要量化回 5/6/5、再按**旁路同一抽头**（补字段低位）复制回
 *      8bit，而输入本来就是这套抽头的结果，来回无损；
 *      ★ 本台的 lutq_* 模型就是按"旁路抽头"写的 ⇒ ② 比的是**两级的 8bit 输出**，
 *        输出级与旁路一旦不同口径，② 立刻 FAIL（2026-09-16 之前正是这种状态，
 *        由 rtl/tb/tb_lut_proto.v 的 T4 端到端抓到并已修正）；
 *   ③ **非平凡表映射正确**：bank1 = R 取反 / G 右移 2 / B 与 0xAA 异或；期望值由
 *      TB 用**同一套量化规则**独立算出（表值 → 取字段 → 位复制回 8bit）后逐像素比对；
 *   ④ **bank 切换只在帧边界**：请求切 bank 之后，**整场每一个像素都必须出自同一张表**
 *      （场内换表 = 撕裂，直接判 FAIL）；并且"写非活动 bank"期间屏幕逐像素不变
 *      （一个 always 监视器在整个写表期间盯着 DE 像素）。
 *   另测：LUT_STAT（0xB0）回读的"已生效 bank"与逐场观测一致、关闭后立刻回到老输出。
 *
 * 手法：源帧缓冲每行一个固定标签（16bit 像素 = 该行标签），像素与输出的对应关系
 *   直接用 RTL 内部同一级的 px2（层次引用）拿到 ⇒ 期望值可以逐像素独立算出，
 *   不依赖 hcnt/vcnt 的流水对齐假设。
 *
 * A/B 逃生门：`-DLUT_OFF` ⇒ 使能恒 0 ⇒ ②③④ 的期望值全部退化成"老输出"。
 *
 * 编译（仓库根）：
 *   iverilog -g2001 -s tb_scanout_lut -o sim_tb_scanout_lut.vvp \
 *     ARC_2DRA/rtl/video/fb_scanout.v ARC_2DRA/rtl/video/video_timing_1080p.v \
 *     ARC_2DRA/rtl/common/simple_dual_port_ram.v rtl/tb/tb_scanout_lut.v
 * ========================================================================= */
`timescale 1ns/1ps
module tb_scanout_lut;
    localparam FB_W = 12'd32;
    localparam FB_H = 12'd16;
    localparam FB_STRIDE = 32'd64;
    localparam FB_BASE = 32'h0000_1000;
    localparam H_ACTIVE = 12'd64, H_FP = 12'd8, H_SYNC = 12'd8, H_BP = 12'd16;
    localparam V_ACTIVE = 12'd32, V_FP = 12'd2, V_SYNC = 12'd2, V_BP = 12'd4;

    reg clk = 1'b0, pclk = 1'b0, rst_n = 1'b0, prst_n = 1'b0;
    always #5.0 clk  = ~clk;         // core 100MHz
    always #3.4 pclk = ~pclk;        // pixel ~147MHz

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

    reg         lut_wr = 1'b0;
    reg  [1:0]  lut_ch = 2'd0;
    reg  [7:0]  lut_idx = 8'd0;
    reg  [7:0]  lut_data = 8'd0;
    reg         lut_en = 1'b0;
    reg         lut_bank_req = 1'b0;
    wire        lut_bank_act;

    fb_scanout #(
        .FB_BASE(FB_BASE), .FB_STRIDE(FB_STRIDE), .FB_W(FB_W), .FB_H(FB_H),
        .WIN_X(12'd0), .WIN_Y(12'd0),
        .H_ACTIVE(H_ACTIVE), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP),
        .V_ACTIVE(V_ACTIVE), .V_FP(V_FP), .V_SYNC(V_SYNC), .V_BP(V_BP),
        .MAX_BURST(8'd16), .SCALE_SH(1)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .fb_sel(2'b00), .fb_cur_sel(fb_cur_sel), .frame_cnt(frame_cnt),
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

    /* ================= 行为 AXI 读从机：整行 = 该行标签 ================= */
    reg [15:0] line_tag [0:FB_H-1];
    reg [127:0] cur_beat;
    reg [7:0]  beats_left;
    reg [27:0] cur_addr;
    reg        rvalid_r;
    integer    k;
    initial begin
        /* 每行一个可辨认标签：高字节 = 行号，低字节 = 行号的位取反（保证各通道都有变化） */
        for (k = 0; k < FB_H; k = k + 1)
            line_tag[k] = {k[7:0], (~k[7:0])};
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

    /* ================= 期望值工具（与 RTL 同一套抽头/量化） ================= */
    function [7:0] xr; input [15:0] p; begin xr = {p[15:11], p[13:11]}; end endfunction
    function [7:0] xg; input [15:0] p; begin xg = {p[10:5],  p[7:6]};   end endfunction
    function [7:0] xb; input [15:0] p; begin xb = {p[4:0],   p[2:0]};   end endfunction
    /* 8bit 表值 → 量化回 5/6/5 → 按**旁路同一抽头**复制回 8bit（= RTL 的输出级）。
     * ★ 抽头必须与 fb_scanout.v 末尾的 r8/g8/b8 一致：补的是字段**低位**
     *   （r5[2:0] / g6[2:1] / b5[2:0]）。这里与旁路逐位对齐以后，本台的
     *   "恒等表 == 老输出"（T2）才是真的在比"两级的 8bit 输出"，
     *   任何一级的抽头改动（也就是恒等表不变量被破坏）都会立刻打到 T2 上。 */
    function [7:0] lutq_r; input [7:0] t; reg [4:0] f; begin f = t[7:3]; lutq_r = {f, f[2:0]}; end endfunction
    function [7:0] lutq_g; input [7:0] t; reg [5:0] f; begin f = t[7:2]; lutq_g = {f, f[2:1]}; end endfunction
    function [7:0] lutq_b; input [7:0] t; reg [4:0] f; begin f = t[7:3]; lutq_b = {f, f[2:0]}; end endfunction

    /* ================= 表内容 ================= */
    reg [7:0] tbl [0:1][0:2][0:255];
    integer bk, ch, ix, v;
    integer errors = 0;                  // 必须在任务之前声明（iverilog 不允许先用后声明）

    /* 写一张表：写 bank **必须**等于 0xAC bit1 的当前值（= "写入 bank"），
     * 显示的那个 bank 是它的反相 ⇒ 写表碰不到正在显示的表 */
    task wr_tbl;
        input integer bank;
        input integer mode;              // 0=恒等 1=非平凡（R~x / G>>2 / B^AA） 2=全 0
        begin
            if (lut_bank_req !== bank[0]) begin
                errors = errors + 1;
                $display("FAIL: 写 bank(%0d) 与 LUT_CTRL.bit1(%b) 不一致（软件协议违规）", bank, lut_bank_req);
            end
            for (ch = 0; ch < 3; ch = ch + 1) begin
                for (ix = 0; ix < 256; ix = ix + 1) begin
                    case (mode)
                        0: v = ix;
                        1: v = (ch == 0) ? (255 - ix) :
                               (ch == 1) ? (ix >> 2) : (ix ^ 8'hAA);
                        default: v = 0;
                    endcase
                    tbl[bank][ch][ix] = v[7:0];
                    @(posedge clk); #1;
                    lut_wr = 1'b1; lut_ch = ch[1:0]; lut_idx = ix[7:0]; lut_data = v[7:0];
                    @(posedge clk); #1;
                    lut_wr = 1'b0;
                end
            end
        end
    endtask

    /* ================= 检查工具 ================= */
    integer n_px, n_bad;
    reg [7:0] e_r, e_g, e_b;
    reg [15:0] tag;
    reg [1:0]  mode_seen;                 // 自动判定：本场第一像素定调
    integer    mode_bad;
    reg        watch_on;                  // 写非活动 bank 期间的逐像素监视
    integer    watch_px, watch_bad;

    task check;
        input [255:0] name;
        input ok;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* 一次"抓一场"：帧起点（frame_tick）→ 下一个帧起点
     *   want = 0 : 期望"老输出 / bank0 恒等"
     *   want = 1 : 期望 bank1 非平凡表
     *   want = 2 : 自动判定（首像素定调，全场必须同一调） */
    task run_frame;
        input [255:0] name;
        input integer want;
        reg en_eff;
        begin
            n_px = 0; n_bad = 0; mode_bad = 0; mode_seen = 2'd3;
`ifdef LUT_OFF
            en_eff = 1'b0;
`else
            en_eff = lut_en;
`endif
            @(posedge pclk);
            while (!frame_tick) @(posedge pclk);      // 等帧起点
            @(posedge pclk);
            while (!frame_tick) begin
                @(posedge pclk);
                /* ctrl2[2] = de && 窗口内 && 行缓冲就绪 —— 与输出级同一个门控。
                 * 帧首那几行还没取到时输出是黑（这是 fb_scanout 的既有行为，
                 * tb_scanout_flip 也是用同一个门控跳过这些像素的），这里同样跳过。 */
                if (dut.ctrl2[2]) begin
                    tag = dut.px2;                     // 与输出同一级的源像素
                    if (en_eff) begin
                        /* 两张表的期望值都算出来，want=2 时用首像素定调 */
                        if (want == 1) begin
                            e_r = lutq_r(tbl[1][0][xr(tag)]);
                            e_g = lutq_g(tbl[1][1][xg(tag)]);
                            e_b = lutq_b(tbl[1][2][xb(tag)]);
                        end else if (want == 0) begin
                            e_r = lutq_r(tbl[0][0][xr(tag)]);
                            e_g = lutq_g(tbl[0][1][xg(tag)]);
                            e_b = lutq_b(tbl[0][2][xb(tag)]);
                        end else begin
                            if (mode_seen == 2'd3) begin
                                if ((vr === lutq_r(tbl[0][0][xr(tag)])) &&
                                    (vg === lutq_g(tbl[0][1][xg(tag)])) &&
                                    (vb === lutq_b(tbl[0][2][xb(tag)]))) mode_seen = 2'd0;
                                else mode_seen = 2'd1;
                            end
                            if (mode_seen == 2'd0) begin
                                e_r = lutq_r(tbl[0][0][xr(tag)]);
                                e_g = lutq_g(tbl[0][1][xg(tag)]);
                                e_b = lutq_b(tbl[0][2][xb(tag)]);
                            end else begin
                                e_r = lutq_r(tbl[1][0][xr(tag)]);
                                e_g = lutq_g(tbl[1][1][xg(tag)]);
                                e_b = lutq_b(tbl[1][2][xb(tag)]);
                            end
                        end
                    end else begin
                        e_r = xr(tag); e_g = xg(tag); e_b = xb(tag);   // 老输出
                    end
                    n_px = n_px + 1;
                    if ((vr !== e_r) || (vg !== e_g) || (vb !== e_b)) begin
                        n_bad = n_bad + 1;
                        if (n_bad <= 4)
                            $display("      px tag=%04h got=(%02h,%02h,%02h) exp=(%02h,%02h,%02h) en=%b",
                                     tag, vr, vg, vb, e_r, e_g, e_b, en_eff);
                    end
                end
            end
            check(name, (n_px > 0) && (n_bad == 0));
            $display("      场内 DE 像素 = %0d，错 %0d", n_px, n_bad);
        end
    endtask

    /* 写"另一个 bank"期间的逐像素监视器（T5 用）：
     * 期望 = bank0 恒等表的输出；`-DLUT_OFF` 下使能被 RTL 恒定关掉 ⇒ 期望退化成老输出。 */
    always @(posedge pclk) begin
        if (prst_n && watch_on && dut.ctrl2[2]) begin
            watch_px = watch_px + 1;
`ifdef LUT_OFF
            if ((vr !== xr(dut.px2)) || (vg !== xg(dut.px2)) || (vb !== xb(dut.px2))) begin
`else
            if ((vr !== lutq_r(tbl[0][0][xr(dut.px2)])) ||
                (vg !== lutq_g(tbl[0][1][xg(dut.px2)])) ||
                (vb !== lutq_b(tbl[0][2][xb(dut.px2)]))) begin
`endif
                watch_bad = watch_bad + 1;
                if (watch_bad <= 4)
                    $display("      [watch] 写表期间屏幕变了：tag=%04h got=(%02h,%02h,%02h)",
                             dut.px2, vr, vg, vb);
            end
        end
    end

    /* ================= 主流程 ================= */
    initial begin
        lut_wr = 0; lut_ch = 0; lut_idx = 0; lut_data = 0; lut_en = 0; lut_bank_req = 0;
        watch_on = 0; watch_px = 0; watch_bad = 0;
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (8) @(posedge pclk);
        prst_n = 1'b1;

        /* 表与 bank 协议（见 fb_scanout.v 的 LUT 一节）：
         *   bit1 = "LUT_DATA 写进哪个 bank"；**显示的是另一个 bank**（帧边界锁存）。
         *   复位值 bit1=0 ⇒ 写 bank0、显示 bank1。 */
        lut_en = 1'b0;                    // 装表期间 LUT 关闭（屏幕不受影响）
        lut_bank_req = 1'b0;              // 写 bank0（此时显示 bank1）
        wr_tbl(0, 0);                     // bank0 = 恒等表
        lut_bank_req = 1'b1;              // 写 bank1（此时显示 bank0 = 恒等）
        wr_tbl(1, 1);                     // bank1 = 非平凡表
        repeat (40) @(posedge clk);

        /* ---- T1 LUT 关闭 ⇒ 逐位等于老输出 ---- */
        $display("--- T1 LUT 关闭（复位默认）⇒ 逐像素等于老输出 ---");
        run_frame("T1 LUT 关闭 = 老输出", 0);

        /* ---- T2 开 LUT：显示 bank0（恒等）⇒ 也逐位等于老输出 ---- */
        $display("--- T2 开 LUT + 恒等表 ⇒ 与老输出逐位相同 ---");
        lut_en = 1'b1;
        /* bit1=1 ⇒ 写 bank1、显示 bank0（恒等） */
        repeat (4000) @(posedge clk);     // 等帧边界把 en 锁存生效
        run_frame("T2 恒等表 = 老输出（逐位）", 0);

        /* ---- T3 切到 bank1（非平凡表）：bit1=0 ⇒ 显示 bank1 ---- */
        $display("--- T3 非平凡表（bank1）逐像素比对 ---");
        lut_bank_req = 1'b0;              // 显示 bank1（写口此时指向 bank0）
        repeat (4000) @(posedge clk);
        run_frame("T3 非平凡表映射正确", 1);

        /* ---- T4 切回 bank0：抓"切换过程中"的那一场，必须全场同一张表 ---- */
        $display("--- T4 bank 切换：整场同表（绝不半场换表） ---");
        lut_bank_req = 1'b1;              // 请求显示 bank0
        run_frame("T4a 切换请求后的一场：全场同表", 2);
        repeat (4000) @(posedge clk);
        run_frame("T4b 切换已生效：bank0 恒等 = 老输出", 0);
        check("T4c LUT_STAT 报告的显示 bank = 0", lut_bank_act === 1'b0);

        /* ---- T5 写"另一个 bank"（写口 = bit1 = bank1）期间屏幕逐像素不变 ---- */
        $display("--- T5 写另一个 bank 时屏幕不变（逐像素监视） ---");
        lut_bank_req = 1'b1;              // 显示 bank0（恒等）、写 bank1
        repeat (4000) @(posedge clk);
        watch_px = 0; watch_bad = 0; watch_on = 1'b1;
        wr_tbl(1, 2);                     // 把 bank1 整张写 0（若错写到 bank0 会立刻全黑）
        repeat (2000) @(posedge pclk);
        watch_on = 1'b0;
        $display("      写表期间监视 DE 像素 = %0d，异常 %0d", watch_px, watch_bad);
        check("T5a 写另一个 bank 期间屏幕零变化", (watch_px > 0) && (watch_bad == 0));
        run_frame("T5b 写完后屏幕仍是恒等", 0);
        check("T5c LUT_STAT 仍为 0", lut_bank_act === 1'b0);

        /* ---- T6 把非平凡表（bank1）切上来，逐场观测 ---- */
        $display("--- T6 切到 bank1（非平凡），逐场观测 ---");
        wr_tbl(1, 1);                     // 恢复 bank1 的非平凡表（写口就是 bank1）
        lut_bank_req = 1'b0;              // 显示 bank1
        repeat (4000) @(posedge clk);
        run_frame("T6 切换后全场都是 bank1", 1);
        check("T6b LUT_STAT 报告的显示 bank = 1", lut_bank_act === 1'b1);

        /* ---- T7 关掉 LUT ⇒ 立刻回到老输出（使能同样走帧边界锁存） ---- */
        $display("--- T7 关闭 LUT ⇒ 回到老输出 ---");
        lut_en = 1'b0;
        repeat (4000) @(posedge clk);
        run_frame("T7 关闭后 = 老输出", 0);

        if (errors == 0) $display("========== tb_scanout_lut ALL PASS ==========");
        else             $display("========== tb_scanout_lut FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #200_000_000;
        $display("!!!!!!!! tb_scanout_lut WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
