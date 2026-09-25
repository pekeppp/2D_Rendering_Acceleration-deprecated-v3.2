/* =========================================================================
 * tb_alpha.v — ALPHA 定点混合专项测试（复现上板 D1/D2/D3/D4 + 逐级数据通路追踪）
 * -------------------------------------------------------------------------
 * 上板现象（fulltest 簇 4）：ALPHA 全错，而白/黑金标准（D3 α=128 白叠黑=7BEF）通过。
 *    D1 α=0    fg=FFFF bg=C618 期望纯背景 C618
 *    D2 α=255  fg=FD20 bg=0010 期望纯前景 FD20
 *    D4 α=32/64/96/160/192/224 fg=FD20 bg=0010 期望 = 定点混合金标准
 *
 * 本测试台的做法：
 *   1) 金标准模型 model_blend()：与 RTL 相同的位复制展开（r/r[4:2]、g/g[5:4]、b/b[4:2]）
 *      + `(fg*a + bg*(255-a) + 127) >> 8` 舍入 + `{r8[7:3],g8[7:2],b8[7:3]}` 打包；
 *   2) 另给 model_blend_old()：把展开换成**修复前**的三个抽头（px[13:11]/px[7:6]/px[2:0]），
 *      回归证据：修复前的 sim/上板结果与它逐位相同 → 差异只来自展开表达式；
 *   3) 逐拍打印 pixel_path 内部每一级（fg_px/bg_px → 展开 → m → r8/g8/b8 → out），
 *      便于定位是"乘加/舍入"还是"通道展开"还是"bg 读回/对齐"；
 *   4) 非 16B 对齐 dst/src 的几何用例（lane 0..7、行距 34B 每行 lane 都不同、W 压/越词边界），
 *      每像素取不同值 + 超时判定（卡死即 FAIL 并 dump rdy/take/fifo empty 现场）。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_alpha;
    reg clk = 1'b0;
    reg rst_n = 1'b0;

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
        .irq_done(irq_done)
    );

    axi_slave_mem #(.AXI_DATA_W(128), .MEM_BYTES(1 << 16), .AR_LAT(20), .B_LAT(2), .MAXO(4)) u_mem (
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

    always #5 clk = ~clk;

    integer errors = 0, trace = 0, quiet = 0;
    integer i, k, idx, mism, n, ai;
    reg [31:0] rv;
    reg [15:0] pv, exp, exp_rtl;
    integer t_start, t_end;
    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    /* ================= 金标准模型 =================
     * 标准 RGB565 → RGB888 位复制（高 3/2 位复制进低位）：
     *   R8={r[4:0],r[4:2]}  G8={g[5:0],g[5:4]}  B8={b[4:0],b[4:2]}
     * 混合：m = fg*α + bg*(255−α) + 127；取 m>>8；打包 {r8[7:3],g8[7:2],b8[7:3]}。 */
    function [7:0] e_r; input [4:0] v; begin e_r = {v, v[4:2]}; end endfunction
    function [7:0] e_g; input [5:0] v; begin e_g = {v, v[5:4]}; end endfunction
    function [7:0] e_b; input [4:0] v; begin e_b = {v, v[4:2]}; end endfunction

    function [15:0] model_blend;        // 金标准（标准位复制展开）
        input [15:0] fg; input [15:0] bg; input [7:0] al;
        reg [15:0] mr, mg, mb;
        begin
            mr = e_r(fg[15:11]) * al + e_r(bg[15:11]) * (8'hFF - al) + 16'd127;
            mg = e_g(fg[10:5])  * al + e_g(bg[10:5])  * (8'hFF - al) + 16'd127;
            mb = e_b(fg[4:0])   * al + e_b(bg[4:0])   * (8'hFF - al) + 16'd127;
            model_blend = {mr[15:11], mg[15:10], mb[15:11]};
        end
    endfunction

    /* 按**修复前**的展开表达式逐字照抄算一遍（回归证据：修复前的 sim/上板结果与它
     * 逐位相同，说明差异只来自那几个展开表达式，而不是 FIFO/对齐/舍入）。 */
    function [15:0] model_blend_old;
        input [15:0] fg; input [15:0] bg; input [7:0] al;
        reg [15:0] mr, mg, mb;
        begin
            mr = {fg[15:11], fg[13:11]} * al + {bg[15:11], bg[13:11]} * (8'hFF - al) + 16'd127;
            mg = {fg[10:5],  fg[7:6]}   * al + {bg[10:5],  bg[7:6]}   * (8'hFF - al) + 16'd127;
            mb = {fg[4:0],   fg[2:0]}   * al + {bg[4:0],   bg[2:0]}   * (8'hFF - al) + 16'd127;
            model_blend_old = {mr[15:11], mg[15:10], mb[15:11]};
        end
    endfunction

    /* ================= 测试台基础设施 ================= */
    task check;
        input [255:0] name; input ok;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else if (!quiet) $display("PASS: %0s", name);
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

    task peek16;
        input [31:0] a; output [15:0] v;
        begin v = {u_mem.mem[a+1], u_mem.mem[a]}; end
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

    task wait_done;
        input [255:0] name;
        begin : wd
            t_start = cyc;
            for (n = 0; n < 30000; n = n + 1) begin
                axi_read(12'h04, rv);
                if (rv & 32'h2) begin
                    t_end = cyc;
                    if (!quiet) $display("PERF %0s: %0d cycles", name, t_end - t_start);
                    disable wd;
                end
                if (rv & 32'h4) begin
                    $display("FAIL: 引擎 ERR 状态 (%0s)", name);
                    errors = errors + 1; disable wd;
                end
            end
            $display("FAIL: 等待 DONE 超时 (%0s)", name);
            dump_state;
            errors = errors + 1;
        end
    endtask

    task dump_state;
        begin
            $display("    [state] st=%0d rstate=%0d proc_r=%0d issue_r=%0d bi_fg=%0d bi_bg=%0d dr_fg=%0d dr_bg=%0d pp_run=%0d cur_H=%0d",
                u_blt.u_eng.st, u_blt.u_eng.rstate, u_blt.u_eng.proc_r, u_blt.u_eng.issue_r,
                u_blt.u_eng.bi_fg, u_blt.u_eng.bi_bg, u_blt.u_eng.dr_fg, u_blt.u_eng.dr_bg,
                u_blt.u_eng.pp_run, u_blt.u_eng.cur_H);
            $display("    [state] fg_empty=%b bg_empty=%b wd_empty=%b wd_busy=%b rd_busy=%b rd_ready=%b rd_req=%b wr_busy=%b awvalid=%b wvalid=%b bvalid=%b",
                u_blt.fg_empty, u_blt.bg_empty, u_blt.wd_empty, u_blt.wd_busy,
                u_blt.rd_busy, u_blt.rd_ready, u_blt.rd_req, u_blt.u_wr.wd_busy,
                m_awvalid, m_wvalid, m_bvalid);
            $display("    [state] pp: st=%0d i=%0d i_done=%0d flush_p=%0d fg_rdy=%b bg_rdy=%b wd_full=%b",
                u_blt.u_path.st, u_blt.u_path.i, u_blt.u_path.i_done, u_blt.u_path.flush_p,
                u_blt.u_path.fg_rdy, u_blt.u_path.bg_rdy, u_blt.u_path.wd_full);
            $display("    [state] pp: fg_take=%b bg_take=%b fg_rd=%b bg_rd=%b | reader fg[loaded=%b lane=%0d first_w=%b] bg[loaded=%b lane=%0d first_w=%b]",
                u_blt.u_path.fg_take, u_blt.u_path.bg_take, u_blt.u_path.fg_rd, u_blt.u_path.bg_rd,
                u_blt.u_path.u_fgr.loaded, u_blt.u_path.u_fgr.lane, u_blt.u_path.u_fgr.first_w,
                u_blt.u_path.u_bgr.loaded, u_blt.u_path.u_bgr.lane, u_blt.u_path.u_bgr.first_w);
            $display("    [state] pp 参数: d_base=%h d_lane0=%0d fg_skip=%0d bg_skip=%0d width=%0d alpha=%0d",
                u_blt.u_path.d_base, u_blt.u_path.d_lane0, u_blt.u_path.fg_skip,
                u_blt.u_path.bg_skip, u_blt.u_path.width, u_blt.u_path.alpha);
        end
    endtask

    /* ================= AXI 读侧事务追踪（+dbg 打开） ================= */
    integer dbg = 0, dbg_n = 0;
    initial dbg = $test$plusargs("dbg");
    always @(posedge clk) begin
        if (dbg && dbg_n < 400) begin
            if (m_arvalid && m_arready) begin
                dbg_n = dbg_n + 1;
                $display("    [AXI-AR] t=%0t addr=%h beats=%0d bg=%b | slave q_cnt=%0d wp=%0d rp=%0d | mst arq=%0d rq=%0d",
                    $time, m_araddr, m_arlen + 1, u_blt.u_rd.arq_sel[u_blt.u_rd.arp],
                    u_mem.q_cnt, u_mem.q_wp, u_mem.q_rp, u_blt.u_rd.arq_cnt, u_blt.u_rd.rq_cnt);
            end
            if (m_rvalid && m_rready && m_rlast) begin
                dbg_n = dbg_n + 1;
                $display("    [AXI-RL] t=%0t | slave q_cnt=%0d wp=%0d rp=%0d | mst arq=%0d rq=%0d",
                    $time, u_mem.q_cnt, u_mem.q_wp, u_mem.q_rp, u_blt.u_rd.arq_cnt, u_blt.u_rd.rq_cnt);
            end
        end
    end

    /* ================= 逐级追踪（pixel_path 内部） ================= */
    always @(posedge clk) begin
        if (trace && u_blt.u_path.can_pp) begin
            $display("    [trace] a=%03d fg_px=%04h bg_px=%04h | ar=%02h ag=%02h ab=%02h br=%02h bg2=%02h bb2=%02h | m_r=%05h m_g=%05h m_b=%05h | r8=%02h g8=%02h b8=%02h | out=%04h",
                u_blt.u_path.alpha,
                u_blt.u_path.fg_px, u_blt.u_path.bg_px,
                u_blt.u_path.ar, u_blt.u_path.ag, u_blt.u_path.ab,
                u_blt.u_path.br, u_blt.u_path.bg2, u_blt.u_path.bb2,
                u_blt.u_path.m_r, u_blt.u_path.m_g, u_blt.u_path.m_b,
                u_blt.u_path.r8, u_blt.u_path.g8, u_blt.u_path.b8,
                u_blt.u_path.out_alpha);
        end
    end

    /* ================= ALPHA 用例执行器 =================
     * g_sa/g_da/g_ss/g_ds/g_W/g_H/g_fg/g_bg/g_al 为输入，整块逐像素比对金标准。 */
    reg [31:0] g_sa, g_da, g_ss, g_ds;
    reg [15:0] g_W, g_H, g_fg, g_bg;
    reg [7:0]  g_al;
    reg        g_trace_this;
    integer    g_vary;          // 1 = src/dst 每像素取不同值（能抓水平错位/取错像素）

    task alpha_case;
        input [255:0] name;
        reg [15:0] fp, bp;
        begin
            eng_init();
            for (k = 0; k < g_H; k = k + 1) begin
                for (idx = 0; idx < g_W; idx = idx + 1) begin
                    poke16(g_sa + k * g_ss + idx * 2, g_vary ? (g_fg + idx)      : g_fg);
                    poke16(g_da + k * g_ds + idx * 2, g_vary ? (g_bg + idx * 3)  : g_bg);
                end
                poke16(g_da + k * g_ds + g_W * 2, 16'hDEAD);   // 行尾哨兵
                poke16(g_da + k * g_ds - 2,        16'h1234);   // 行首前哨兵
            end
            trace = g_trace_this;
            push_cmd(2'd2, g_sa, g_da, g_ss, g_ds, g_W, g_H, g_al, 16'd0);
            wait_done(name);
            trace = 0;

            mism = 0;
            for (k = 0; k < g_H; k = k + 1) begin
                for (idx = 0; idx < g_W; idx = idx + 1) begin
                    fp = g_vary ? (g_fg + idx)     : g_fg;
                    bp = g_vary ? (g_bg + idx * 3) : g_bg;
                    exp = model_blend(fp, bp, g_al);
                    exp_rtl = model_blend_old(fp, bp, g_al);
                    peek16(g_da + k * g_ds + idx * 2, pv);
                    if (pv !== exp) begin
                        mism = mism + 1;
                        if (mism <= 4)
                            $display("      MISMATCH row=%0d col=%0d got=%04h exp=%04h (当前RTL表达式模型=%04h)  got(R,G,B)=(%0d,%0d,%0d) exp=(%0d,%0d,%0d)",
                                k, idx, pv, exp, exp_rtl,
                                pv[15:11], pv[10:5], pv[4:0],
                                exp[15:11], exp[10:5], exp[4:0]);
                    end
                end
                peek16(g_da + k * g_ds + g_W * 2, pv);
                if (pv !== 16'hDEAD) begin
                    mism = mism + 1;
                    $display("      OVERRUN row=%0d col=%0d got=%04h exp=DEAD", k, g_W, pv);
                end
                peek16(g_da + k * g_ds - 2, pv);
                if (pv !== 16'h1234) begin
                    mism = mism + 1;
                    $display("      UNDERRUN row=%0d col=-1 got=%04h exp=1234", k, pv);
                end
            end
            if (mism != 0) $display("      mism=%0d (共 %0d 像素)", mism, g_W * g_H);
            check(name, mism == 0);
        end
    endtask

    /* 便捷封装：填 src/dst、跑一条、比一整块 */
    task alpha_blk;
        input [255:0] name;
        input [31:0] sa, da, ss, ds;
        input [15:0] W, H, fg, bg;
        input [7:0]  al;
        begin
            g_sa = sa; g_da = da; g_ss = ss; g_ds = ds;
            g_W = W; g_H = H; g_fg = fg; g_bg = bg; g_al = al;
            g_trace_this = 0; g_vary = 0;
            alpha_case(name);
        end
    endtask

    /* 非对齐 ALPHA：dst（和/或 src）行首落在 lane 1..7；每像素取不同值 */
    task alpha_unalign;
        input [255:0] name;
        input [31:0] sa, da, ss, ds;
        input [15:0] W, H;
        input [7:0]  al;
        begin
            g_sa = sa; g_da = da; g_ss = ss; g_ds = ds;
            g_W = W; g_H = H; g_fg = 16'hFD20; g_bg = 16'h0010; g_al = al;
            g_trace_this = 0; g_vary = 1;
            alpha_case(name);
        end
    endtask

    /* ================= 主流程 ================= */
    initial begin
        #20 rst_n = 1'b1;

        /* ---------- D1：α=0 → 必须逐像素等于纯背景 0xC618 ---------- */
        $display("--- D1 α=0  fg=FFFF bg=C618 (期望纯背景 C618) ---");
        alpha_blk("D1 α=0  fg=FFFF bg=C618 16x8 == C618", 32'h3000, 32'h2000, 32'd64, 32'd64,
                  16'd16, 16'd8, 16'hFFFF, 16'hC618, 8'd0);

        /* ---------- D2：α=255 → 必须逐像素等于纯前景 0xFD20 ---------- */
        $display("--- D2 α=255 fg=FD20 bg=0010 (期望纯前景 FD20) ---");
        alpha_blk("D2 α=255 fg=FD20 bg=0010 16x8 == FD20", 32'h3000, 32'h2000, 32'd64, 32'd64,
                  16'd16, 16'd8, 16'hFD20, 16'h0010, 8'd255);

        /* ---------- D3：白/黑金标准 α=128 → 0x7BEF ---------- */
        $display("--- D3 α=128 fg=FFFF bg=0000 (金标准 7BEF) ---");
        alpha_blk("D3 α=128 fg=FFFF bg=0000 16x8 == 7BEF", 32'h3000, 32'h2000, 32'd64, 32'd64,
                  16'd16, 16'd8, 16'hFFFF, 16'h0000, 8'd128);

        /* ---------- D4：1x1 α 扫描（上板给的全套 α） ---------- */
        $display("--- D4 1x1 fg=FD20 bg=0010 α 扫描（期望 = 金标准） ---");
        g_sa = 32'h3000; g_da = 32'h2000; g_ss = 32'd64; g_ds = 32'd64;
        g_W  = 16'd1;    g_H  = 16'd1;    g_fg = 16'hFD20; g_bg = 16'h0010;
        g_trace_this = 1;                       // 第一发打印内部各级
        for (ai = 0; ai < 9; ai = ai + 1) begin
            case (ai)
                0: g_al = 8'd0;   1: g_al = 8'd255; 2: g_al = 8'd32;  3: g_al = 8'd64;
                4: g_al = 8'd96;  5: g_al = 8'd160; 6: g_al = 8'd192; 7: g_al = 8'd224;
                default: g_al = 8'd128;
            endcase
            g_trace_this = (ai == 0) ? 1 : 0;
            exp = model_blend(g_fg, g_bg, g_al);
            exp_rtl = model_blend_old(g_fg, g_bg, g_al);
            $display("  [D4 α=%0d] 金标准=%04h  修复前展开模型=%04h  (R,G,B)=(%0d,%0d,%0d)", g_al, exp, exp_rtl,
                     exp[15:11], exp[10:5], exp[4:0]);
            // 手工复核任务给出的上板期望值
            case (ai)
                2: if (exp !== 16'h20AE) begin $display("  模型与任务期望不符! exp=%04h", exp); errors = errors + 1; end
                3: if (exp !== 16'h414C) begin $display("  模型与任务期望不符! exp=%04h", exp); errors = errors + 1; end
                4: if (exp !== 16'h61EA) begin $display("  模型与任务期望不符! exp=%04h", exp); errors = errors + 1; end
                5: if (exp !== 16'h9B46) begin $display("  模型与任务期望不符! exp=%04h", exp); errors = errors + 1; end
                6: if (exp !== 16'hBBE4) begin $display("  模型与任务期望不符! exp=%04h", exp); errors = errors + 1; end
                7: if (exp !== 16'hDC82) begin $display("  模型与任务期望不符! exp=%04h", exp); errors = errors + 1; end
                default: ;
            endcase
            alpha_case("D4 1x1 fg=FD20 bg=0010");
        end

        /* ---------- D1'/D2'：白/深灰 16x8 的 α=0 / 255（任务要求覆盖） ---------- */
        $display("--- D1'/D2' fg=FFFF bg=C618 α=0/255 ---");
        alpha_blk("A0 fg=FFFF bg=C618 α=0   16x8 == C618", 32'h3000, 32'h2000, 32'd64, 32'd64,
                  16'd16, 16'd8, 16'hFFFF, 16'hC618, 8'd0);
        alpha_blk("A1 fg=FFFF bg=C618 α=255 16x8 == FFFF", 32'h3000, 32'h2000, 32'd64, 32'd64,
                  16'd16, 16'd8, 16'hFFFF, 16'hC618, 8'd255);

        /* ---------- ALPHA + 非 16B 对齐 dst/src（上板压测路径） ----------
         * ALPHA 要从 dst 的**对齐基址**读 cover_beats 个 16B 词、再按 px_skip 对齐取像素；
         * 这里覆盖 lane 0..7、W 跨词/不跨词、行距 16B 对齐与非对齐（每行 lane 都不同），
         * 每个像素取不同值（错位/取错像素必定暴露），并带超时=FAIL 的卡死判定。 */
        $display("--- ALPHA + 非对齐 dst/src（lane 0..7，逐像素比对 + 卡死判定） ---");
        begin : unalign
            integer L;
            /* (a) dst lane 1..7，src 对齐，单行 */
            for (L = 1; L <= 7; L = L + 1) begin
                $display("  [UA-dst lane=%0d] src=0x3000 dst=0x%0h W=8 H=1 a=128", L, 32'h2000 + 2*L);
                alpha_unalign("UA ALPHA dst非对齐单行 W=8", 32'h3000, 32'h2000 + 2*L, 32'd32, 32'd32,
                              16'd8, 16'd1, 8'd128);
            end
            /* (b) src lane 1..7，dst 对齐，单行 */
            for (L = 1; L <= 7; L = L + 1) begin
                $display("  [UA-src lane=%0d] src=0x%0h dst=0x2000 W=9 H=1 a=160", L, 32'h3000 + 2*L);
                alpha_unalign("UA ALPHA src非对齐单行 W=9", 32'h3000 + 2*L, 32'h2000, 32'd32, 32'd32,
                              16'd9, 16'd1, 8'd160);
            end
            /* (c) 父任务点名的 lane=1/4/7 单行（不同 W：跨词/不跨词/1 像素） */
            alpha_unalign("U_L1 ALPHA dst lane1 W=13 a=96", 32'h3000, 32'h2002, 32'd32, 32'd32, 16'd13, 16'd1, 8'd96);
            alpha_unalign("U_L4 ALPHA dst lane4 W=9  a=192", 32'h3000, 32'h2008, 32'd32, 32'd32, 16'd9,  16'd1, 8'd192);
            alpha_unalign("U_L7 ALPHA dst lane7 W=1  a=224", 32'h3000, 32'h200E, 32'd32, 32'd32, 16'd1,  16'd1, 8'd224);
            /* (d) 多行 + 行长距非 16B 对齐（每行 lane 各不相同：行距 34B → lane 每行 +1） */
            $display("  [UA-multi] dst=0x2000+2*L stride=34 W=8 H=6 a=128（每行 lane 不同）");
            for (L = 0; L <= 7; L = L + 1)
                alpha_unalign("UA ALPHA 多行 stride34 每行lane不同", 32'h3000, 32'h2000 + 2*L, 32'd32, 32'd34,
                              16'd8, 16'd6, 8'd128);
            /* (e) 多行 + dst 非对齐 + 行长距 16B 对齐（行内跨词） */
            for (L = 1; L <= 7; L = L + 1)
                alpha_unalign("UA ALPHA 多行 stride64 dst非对齐", 32'h3000 + 2*L, 32'h2000 + 2*L, 32'd32, 32'd64,
                              16'd13, 16'd4, 8'd64);
            /* (f) W 端点组合（lane+W 正好压在词边界 / 越 1 像素） */
            for (L = 0; L <= 7; L = L + 1) begin
                alpha_unalign("UA ALPHA W 使 lane+W 压词边界", 32'h3000, 32'h2000 + 2*L, 32'd32, 32'd32,
                              (8 - L), 16'd3, 8'd200);
                alpha_unalign("UA ALPHA W 使 lane+W 越词边界", 32'h3000, 32'h2000 + 2*L, 32'd32, 32'd32,
                              (8 - L) + 1, 16'd3, 8'd56);
            end
        end

        /* ---------- 全 α 扫描（1x1，多组 fg/bg，逐像素比金标准） ---------- */
        $display("--- 全 α 扫描（1x1，6 组 fg/bg × 256 α；+sweep 才跑） ---");
        if ($test$plusargs("sweep")) begin : sweep
            integer c;
            integer smis;
            quiet = 1;
            for (c = 0; c < 6; c = c + 1) begin
                case (c)
                    0: begin g_fg = 16'hFFFF; g_bg = 16'hC618; end
                    1: begin g_fg = 16'hFD20; g_bg = 16'h0010; end
                    2: begin g_fg = 16'h07E0; g_bg = 16'hF800; end
                    3: begin g_fg = 16'h1234; g_bg = 16'hABCD; end
                    4: begin g_fg = 16'h0000; g_bg = 16'hFFFF; end
                    default: begin g_fg = 16'h8410; g_bg = 16'h4210; end
                endcase
                smis = 0;
                for (ai = 0; ai < 256; ai = ai + 1) begin
                    g_sa = 32'h3000; g_da = 32'h2000; g_ss = 32'd64; g_ds = 32'd64;
                    g_W  = 16'd1;    g_H  = 16'd1;
                    g_al = ai;
                    g_trace_this = 0;
                    alpha_case("sweep");
                    smis = smis;                        // check() 已记账
                end
                $display("  sweep fg=%04h bg=%04h: 256 个 α 全部逐像素比对完成", g_fg, g_bg);
            end
            quiet = 0;
        end

        if (errors == 0)
            $display("========== tb_alpha ALL PASS ==========");
        else
            $display("========== tb_alpha FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #60_000_000;
        $display("!!!!!!!! WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end
endmodule
