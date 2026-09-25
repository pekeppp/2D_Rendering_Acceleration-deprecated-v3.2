/* =========================================================================
 * tb_px_path.v — pixel_path + stream_reader 单元级「位精确 + 背压」测试台
 * -------------------------------------------------------------------------
 * 为什么要有它（与既有 TB 的分工）：
 *   · tb_alpha / tb_blt_unalign / tb_dl_* 走完整 blt_top（AXI + 引擎 + 列表），
 *     覆盖真实路径但**无法把 wd FIFO 逼满**（探针实测所有算子 wd_full=0 拍）；
 *   · 本台直接把两个真 `sync_fifo` 当源、用 TB 自己做写侧 FIFO/从机，于是可以
 *     **任意**指定背压形态（深满 + 慢排空 / 每 N 拍只收 1 词），把"背压路径"逐拍
 *     压到饱和，并且逐字节验证渲染结果与写词流。
 *
 * 每个用例检查（全部是硬判据）：
 *   1. 目的区**逐字节**等于 CPU 模型（COPY/FILL/KEY/ALPHA；ALPHA 用 tb_alpha 同款
 *      金标准公式）；KEY 键色像素必须留孔（字节仍是哨兵值）；
 *   2. 每个 16B 词的 16bit 掩码逐位等于模型（多写/少写/写错位置都抓）；
 *   3. 写出词数 == 模型里"掩码非空"的词数（KEY 整词键色 ⇒ 不提交）；
 *   4. 读取器弹词数 == floor((skip+width)/8)（与引擎 RS_LOOP 的 dr_* 同口径，
 *      多弹/少弹都会让下一行的词错位）；
 *   5. 被 wd full 静默丢掉的词数 == 0（TB 用与 sync_fifo 相同的 do_wr 语义计数）。
 *
 * 扫描维度：op(4) × dst lane(8) × width(8 档) × fg/bg skip(0..7) × 背压形态(多档)。
 * A/B：`-DPIXEL_PIXELS2_OFF` 时同一份 TB 跑单像素路径，读数必须同样全过。
 * 编译（仓库根）：
 *   iverilog -g2001 -s tb_px_path -o sim_tb_px_path.vvp \
 *     rtl/sync_fifo.v rtl/stream_reader.v rtl/pixel_path.v rtl/tb/tb_px_path.v
 * ========================================================================= */
`timescale 1ns/1ps
module tb_px_path;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst_n = 1'b0;

    /* ================= DUT ================= */
    reg         start = 1'b0;
    wire        busy, row_done;
    reg  [1:0]  op    = 2'd0;
    reg  [15:0] width = 16'd8;
    reg  [31:0] d_base = 32'h0000_0100;
    reg  [2:0]  d_lane0 = 3'd0, fg_skip = 3'd0, bg_skip = 3'd0;
    reg  [7:0]  alpha = 8'd128;
    reg  [15:0] color = 16'h07E0, key = 16'h7BEF;
    reg         wd_full = 1'b0;
    /* ★S5（v3.2）属性侧口：本台只测"位精确 + 背压"两条老路径 ⇒ 恒钉成
     * "无属性"（blend=0 + 默认属性字）。属性/混合本身的位精确由 tb_attr_blend 覆盖
     * （那台走完整 blt_top，能真正下发 0x8C 属性字并逐像素比对）。 */
    reg         blend = 1'b0;
    reg  [31:0] attr  = 32'h0000_3FC0;
    wire        fg_rd, bg_rd, wd_wr;
    wire [175:0] wd_word;

    /* 源：真 sync_fifo（含同步读 2 拍延迟，读取器的取词/弹词时序必须与真环境一致） */
    reg          fg_wr = 1'b0, bg_wr = 1'b0;
    reg  [127:0] fg_din = 128'd0, bg_din = 128'd0;
    wire [127:0] fg_dout, bg_dout;
    wire         fg_empty, bg_empty, fg_full, bg_full;

    sync_fifo #(.DW(128), .DEPTH(256)) u_fg_fifo (
        .clk(clk), .rst_n(rst_n), .wr_en(fg_wr), .din(fg_din),
        .rd_en(fg_rd), .rd_ack(), .dout(fg_dout),
        .full(fg_full), .empty(fg_empty), .count()
    );
    sync_fifo #(.DW(128), .DEPTH(256)) u_bg_fifo (
        .clk(clk), .rst_n(rst_n), .wr_en(bg_wr), .din(bg_din),
        .rd_en(bg_rd), .rd_ack(), .dout(bg_dout),
        .full(bg_full), .empty(bg_empty), .count()
    );

    pixel_path u_pp (
        .clk(clk), .rst_n(rst_n), .start(start), .busy(busy), .row_done(row_done),
        .op(op), .width(width), .d_base(d_base), .d_lane0(d_lane0),
        .fg_skip(fg_skip), .bg_skip(bg_skip), .alpha(alpha), .color(color), .key(key),
        .blend(blend), .attr(attr),                       // ★S5 属性侧口（本台恒钉"无属性"）
        .fg_empty(fg_empty), .fg_dout(fg_dout), .fg_rd(fg_rd),
        .bg_empty(bg_empty), .bg_dout(bg_dout), .bg_rd(bg_rd),
        .wd_full(wd_full), .wd_wr(wd_wr), .wd_word(wd_word)
    );

    /* ================= 写侧从机（TB 模型：与 sync_fifo 同语义） ================= */
    localparam MEMB = 16384;                 // 目的区字节数（16KB）
    reg [7:0]  dst_mem [0:MEMB-1];
    reg [15:0] obs_mask [0:1023];            // 每个 16B 词的观测掩码
    integer    wd_occ  = 0;                  // 写侧 FIFO 占用（TB 记账）
    integer    wd_lim  = 8;                  // mode1：occ >= lim ⇒ full
    integer    wd_div  = 4;                  // mode1：每 div 拍排空 1 词
    integer    wd_mode = 0;                  // 0=不收满；1=深满+慢排空；2=每 div 拍只收 1 词
    integer    wd_dcnt = 0, slow_cnt = 0;
    integer    wr_words = 0, drop_words = 0;
    integer    fg_pops = 0, bg_pops = 0;
    integer    row_cyc = 0;

    always @* begin
        if (wd_mode == 0)      wd_full = 1'b0;
        else if (wd_mode == 1) wd_full = (wd_occ >= wd_lim);
        else                   wd_full = (slow_cnt != 0);
    end

    task render_word;
        input [175:0] w;
        reg [31:0] a;
        reg [127:0] d;
        reg [15:0]  m;
        integer b, widx;
        begin
            m = w[175:160]; a = w[159:128]; d = w[127:0];
            widx = (a - d_base) >> 4;
            if (widx < 1024) obs_mask[widx] = obs_mask[widx] | m;
            for (b = 0; b < 16; b = b + 1)
                if (m[b] && ((a - d_base) + b) < MEMB)
                    dst_mem[(a - d_base) + b] = d[b*8 +: 8];
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wd_occ <= 0; wd_dcnt <= 0; slow_cnt <= 0;
        end else begin
            /* 写：full 时**静默丢弃**（与 sync_fifo.do_wr 同语义 ⇒ 丢词必被抓到） */
            if (wd_wr) begin
                if (!wd_full) begin
                    render_word(wd_word);
                    wr_words = wr_words + 1;
                    wd_occ   = wd_occ + 1;
                    if (wd_mode == 2) slow_cnt <= wd_div - 1;
                end else
                    drop_words = drop_words + 1;
            end
            if (wd_mode == 1) begin
                wd_dcnt <= wd_dcnt + 1;
                if (wd_dcnt >= wd_div) begin
                    wd_dcnt <= 0;
                    if (wd_occ > 0) wd_occ = wd_occ - 1;
                end
            end else if (wd_mode == 2) begin
                if (slow_cnt > 0) slow_cnt <= slow_cnt - 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (fg_rd) fg_pops = fg_pops + 1;
            if (bg_rd) bg_pops = bg_pops + 1;
            row_cyc = row_cyc + 1;
        end
    end

    /* ================= 源数据生成 ================= */
    localparam NWMAX = 48;
    reg [127:0] fgw [0:NWMAX-1], bgw [0:NWMAX-1];
    integer f_seed, b_seed, pat_g, src_n;

    function [15:0] lcg;
        input [15:0] v;
        begin lcg = (v * 16'd25173) + 16'd13849; end
    endfunction

    /* pat 0 = 伪随机；1 = 键色重（每词 lane2..5 = key ⇒ 有整词键色）；2 = 极值 */
    task gen_words;
        input integer pat;
        input integer nw;
        integer k2, j2, ix;
        reg [15:0] s2, v2;
        begin
            s2 = 16'h1234 + pat[15:0];
            for (k2 = 0; k2 < nw; k2 = k2 + 1) begin
                fgw[k2] = 128'd0; bgw[k2] = 128'd0;
                for (j2 = 0; j2 < 8; j2 = j2 + 1) begin
                    ix = k2*8 + j2;
                    s2 = lcg(s2); v2 = s2;
                    case (pat)
                        1: v2 = (((ix % 8) >= 2) && ((ix % 8) <= 5)) ? 16'h7BEF
                                                                   : (16'hF800 + ix[4:0]);
                        2: v2 = (ix % 4 == 0) ? 16'h0000 : (ix % 4 == 1) ? 16'hFFFF :
                                (ix % 4 == 2) ? 16'h07E0 : 16'hF81F;
                        default: ;
                    endcase
                    fgw[k2][j2*16 +: 16] = v2;
                    s2 = lcg(s2); v2 = s2;
                    case (pat)
                        1: v2 = (ix % 3 == 0) ? 16'h7BEF : (16'h0010 + ix[3:0]);
                        2: v2 = (ix % 4 == 0) ? 16'hFFFF : (ix % 4 == 1) ? 16'h0000 :
                                (ix % 4 == 2) ? 16'hF81F : 16'h07E0;
                        default: ;
                    endcase
                    bgw[k2][j2*16 +: 16] = v2;
                end
            end
        end
    endtask

    /* ================= 金标准（与 tb_alpha 同款） ================= */
    function [7:0] e_r; input [4:0] v; begin e_r = {v, v[4:2]}; end endfunction
    function [7:0] e_g; input [5:0] v; begin e_g = {v, v[5:4]}; end endfunction
    function [7:0] e_b; input [4:0] v; begin e_b = {v, v[4:2]}; end endfunction
    function [15:0] model_blend;
        input [15:0] fg; input [15:0] bg; input [7:0] al;
        reg [15:0] mr, mg, mb;
        begin
            mr = e_r(fg[15:11]) * al + e_r(bg[15:11]) * (8'hFF - al) + 16'd127;
            mg = e_g(fg[10:5])  * al + e_g(bg[10:5])  * (8'hFF - al) + 16'd127;
            mb = e_b(fg[4:0])   * al + e_b(bg[4:0])   * (8'hFF - al) + 16'd127;
            model_blend = {mr[15:11], mg[15:10], mb[15:11]};
        end
    endfunction

    /* ================= 期望模型 ================= */
    reg [15:0] exp_mask [0:1023];
    reg [7:0]  exp_byte [0:MEMB-1];
    function [7:0] sentinel; input integer b; begin sentinel = 8'h5A ^ b[7:0]; end endfunction

    integer cases = 0, fails = 0;
    integer k, j, t, wix, lane, bix;
    integer wd_idle = 0;
    integer bp_mode = 0, bp_lim = 8, bp_div = 4;
    reg [15:0] w2tab [0:3];
    reg [15:0] fp, bp, need_fg, need_bg, exp_v;
    reg        exp_wr;
    integer    nth_fg, nth_bg, nw_cnt, nfull_fg, nfull_bg, exp_words, got_words, mism;

    task fail;
        input [255:0] msg;
        begin
            fails = fails + 1;
            if (fails <= 40)
                $display("FAIL: %0s | op=%0d lane=%0d W=%0d fskip=%0d bskip=%0d pat=%0d key=%04h al=%0d mode=%0d lim=%0d div=%0d",
                    msg, op, d_lane0, width, fg_skip, bg_skip, pat_g, key, alpha, wd_mode, wd_lim, wd_div);
        end
    endtask

    /* ================= 单用例 ================= */
    task run_case;
        input [1:0]  o;
        input [2:0]  dl, fs, bs;
        input [15:0] W;
        input [7:0]  al;
        input [15:0] col, ky;
        input integer pat;
        input integer mode, lim, div;
        reg done_seen;
        begin
            cases = cases + 1;
            op = o; d_lane0 = dl; fg_skip = fs; bg_skip = bs; width = W;
            alpha = al; color = col; key = ky; pat_g = pat;
            wd_mode = mode; wd_lim = lim; wd_div = div;

            /* 源词数（+2 冗余，与真实"下一行数据已在 FIFO 里"一致） */
            nth_fg = ((fs + W) + 7) >> 3;
            nth_bg = ((bs + W) + 7) >> 3;
            nfull_fg = (fs + W) >> 3;
            nfull_bg = (bs + W) >> 3;
            need_fg = (o != 2'd1);
            need_bg = (o == 2'd2);
            src_n = (nth_fg > nth_bg) ? nth_fg : nth_bg;
            if (src_n < 1) src_n = 1;
            if (src_n + 2 > NWMAX) begin fail("src_n 超界"); disable run_case; end

            /* ---- 复位 + 预置目的区/观测 ----
             * ★激励一律在时钟沿后 #1 建立（低电平中间），绝不在沿上做阻塞赋值 ——
             *   否则 TB 的赋值可能被 DUT 在同一沿抢先/滞后采到（实测踩过：源 FIFO
             *   写入整体错开一个词，症状是"目的区第 1 个像素错、掩码却对"）。 */
            rst_n = 1'b0; start = 1'b0; fg_wr = 1'b0; bg_wr = 1'b0;
            wd_occ = 0; wd_dcnt = 0; slow_cnt = 0;
            wr_words = 0; drop_words = 0; fg_pops = 0; bg_pops = 0; row_cyc = 0;
            wd_idle = 0;
            for (wix = 0; wix < nth_fg + 2; wix = wix + 1) obs_mask[wix] = 16'd0;
            for (bix = 0; bix < (nth_fg + 2)*16; bix = bix + 1) dst_mem[bix] = sentinel(bix);
            repeat (4) @(posedge clk);
            #1 rst_n = 1'b1;
            @(posedge clk);

            /* ---- 源词生成 + 推入真 FIFO ---- */
            gen_words(pat, src_n + 2);
            if ($test$plusargs("src") && (cases <= 4))
                $display("  SRC case=%0d pat=%0d fgw0=%h fgw1=%h bgw0=%h nth_fg=%0d",
                         cases, pat, fgw[0], fgw[1], bgw[0], nth_fg);
            for (k = 0; k < nth_fg + 2; k = k + 1) begin
                @(posedge clk); #1;
                fg_din = fgw[k]; fg_wr = 1'b1;
            end
            @(posedge clk); #1 fg_wr = 1'b0;
            for (k = 0; k < nth_bg + 2; k = k + 1) begin
                @(posedge clk); #1;
                bg_din = bgw[k]; bg_wr = 1'b1;
            end
            @(posedge clk); #1 bg_wr = 1'b0;
            repeat (3) @(posedge clk);

            /* ---- 起行 ---- */
            if ($test$plusargs("src") && (cases <= 4)) begin
                $display("  FIFO: out_v=%b dout=%h mcnt=%0d rd_pend=%b empty=%b wptr=%0d rptr=%0d",
                    u_fg_fifo.out_v, u_fg_fifo.dout_r, u_fg_fifo.mcnt, u_fg_fifo.rd_pend,
                    fg_empty, u_fg_fifo.wptr, u_fg_fifo.rptr);
                $display("  ARR:  fgw0=%h fgw1=%h fgw2=%h", fgw[0], fgw[1], fgw[2]);
            end
            @(posedge clk); #1 start = 1'b1;
            @(posedge clk); #1 start = 1'b0;
            done_seen = 1'b0; t = 0;
            while ((t < 4000) && !done_seen) begin
                @(posedge clk);
                if (row_done) done_seen = 1'b1;
                t = t + 1;
            end
            if (!done_seen) begin fail("行超时未完成"); disable run_case; end
            /* 等 staging 里的尾词推完：连续 40 拍没有 wd_wr 即认为推空（最多 600 拍） */
            t = 0;
            while ((t < 600) && (wd_idle < 40)) begin
                @(posedge clk);
                t = t + 1;
                if (wd_wr) wd_idle = 0; else wd_idle = wd_idle + 1;
            end
            if (wd_idle < 40) begin fail("背压下写词迟迟推不完"); disable run_case; end

            /* ---- 模型 ---- */
            for (wix = 0; wix < nth_fg + 2; wix = wix + 1) exp_mask[wix] = 16'd0;
            for (bix = 0; bix < (nth_fg + 2)*16; bix = bix + 1) exp_byte[bix] = 8'h00;
            for (j = 0; j < width; j = j + 1) begin
                lane = (d_lane0 + j) & 7;
                wix  = (({29'd0, d_lane0} + j) >> 3);
                fp = fgw[(fs + j) >> 3][((fs + j) & 7)*16 +: 16];
                bp = bgw[(bs + j) >> 3][((bs + j) & 7)*16 +: 16];
                case (op)
                    2'd0: begin exp_v = fp; exp_wr = 1'b1; end
                    2'd1: begin exp_v = color; exp_wr = 1'b1; end
                    2'd2: begin exp_v = model_blend(fp, bp, alpha); exp_wr = 1'b1; end
                    default: begin exp_v = fp; exp_wr = (fp != key); end
                endcase
                if (exp_wr) begin
                    exp_mask[wix] = exp_mask[wix] | (16'h0003 << (lane*2));
                    exp_byte[wix*16 + lane*2]     = exp_v[7:0];
                    exp_byte[wix*16 + lane*2 + 1] = exp_v[15:8];
                end
            end

            /* ---- 逐项比对 ---- */
            mism = 0;
            for (wix = 0; wix < nth_fg + 2; wix = wix + 1)
                if (obs_mask[wix] !== exp_mask[wix]) begin
                    mism = mism + 1;
                    if (mism <= 2)
                        $display("      [mask] word=%0d got=%04h exp=%04h", wix, obs_mask[wix], exp_mask[wix]);
                end
            exp_words = 0;
            for (wix = 0; wix < nth_fg + 2; wix = wix + 1)
                if (exp_mask[wix] != 16'd0) exp_words = exp_words + 1;
            got_words = wr_words;
            if (got_words !== exp_words) begin
                mism = mism + 1;
                $display("      [words] got=%0d exp=%0d", got_words, exp_words);
            end
            if (drop_words !== 0) begin
                mism = mism + 1;
                $display("      [drop] 被 full 丢掉的词 = %0d", drop_words);
            end
            if (need_fg && (fg_pops !== nfull_fg)) begin
                mism = mism + 1;
                $display("      [fgpop] got=%0d exp=%0d", fg_pops, nfull_fg);
            end
            if (!need_fg && (fg_pops !== 0)) begin mism = mism + 1; $display("      [fgpop] 不该弹：%0d", fg_pops); end
            if (need_bg && (bg_pops !== nfull_bg)) begin
                mism = mism + 1;
                $display("      [bgpop] got=%0d exp=%0d", bg_pops, nfull_bg);
            end
            if (!need_bg && (bg_pops !== 0)) begin mism = mism + 1; $display("      [bgpop] 不该弹：%0d", bg_pops); end
            for (bix = 0; bix < (nth_fg + 2)*16; bix = bix + 1) begin
                if ((exp_mask[bix >> 4] >> (bix & 15)) & 1'b1) begin
                    if (dst_mem[bix] !== exp_byte[bix]) begin
                        mism = mism + 1;
                        if (mism <= 3)
                            $display("      [byte] off=%0d got=%02h exp=%02h", bix, dst_mem[bix], exp_byte[bix]);
                    end
                end else if (dst_mem[bix] !== sentinel(bix)) begin
                    mism = mism + 1;
                    if (mism <= 3)
                        $display("      [hole] off=%0d 本应留孔，实际=%02h", bix, dst_mem[bix]);
                end
            end
            if (mism != 0) fail("像素/掩码/词数/弹词不一致");
        end
    endtask

`ifndef PIXEL_PIXELS2_OFF
    /* 双 lane 模式的逐拍诊断（+dump） */
    initial begin
        if ($test$plusargs("dump")) begin
            $display("DUMP op=%0d lane=%0d W=%0d fskip=%0d bskip=%0d", op, d_lane0, width, fg_skip, bg_skip);
        end
    end
    always @(posedge clk) begin
        if ($test$plusargs("dump") && (u_pp.st == 1'b1))
            $display("  t=%0t i=%0d lane=%0d two=%b keep=%b%0b push=%b h_v=%b jw=%0d | fgr v=%b%b lane=%0d wc=%0d cur=%b",
                $time, u_pp.i, u_pp.lane, u_pp.two, u_pp.keep, u_pp.keep2,
                u_pp.need_push, u_pp.h_v, u_pp.jw,
                u_pp.u_fgr.v0, u_pp.u_fgr.v1, u_pp.u_fgr.lane, u_pp.u_fgr.wc, u_pp.u_fgr.cur);
    end
`endif
    /* 消费像素诊断（+pix）：两种模式通用（fg_px/fg_px2 在公共段声明） */
    always @(posedge clk) begin
        if ($test$plusargs("pix") && u_pp.can_pp)
            $display("  PIX t=%0t op=%0d i=%0d lane=%0d fg=%h/%h bg=%h/%h keep=%b",
                $time, op, u_pp.i, u_pp.lane, u_pp.fg_px, u_pp.fg_px2,
                u_pp.bg_px, u_pp.bg_px2, u_pp.keep);
    end
    /* 源 FIFO 逐拍诊断（+src） */
    always @(posedge clk) begin
        if ($test$plusargs("src")) begin
            if (cases <= 1) $display("  STIM t=%0t k=%0d fg_din=%h fg_wr=%b fgw[0]=%h", $time, k, fg_din, fg_wr, fgw[0]);
            if (u_fg_fifo.do_wr)   $display("  WR  t=%0t wptr=%0d din=%h", $time, u_fg_fifo.wptr, u_fg_fifo.din);
            if (u_fg_fifo.rd_ack)  $display("  POP t=%0t rptr=%0d dout=%h", $time, u_fg_fifo.rptr, u_fg_fifo.dout_r);
            if (u_fg_fifo.take)    $display("  TAK t=%0t rptr=%0d rdata=%h", $time, u_fg_fifo.rptr, u_fg_fifo.rdata_r);
            if (u_fg_fifo.fetch)   $display("  FET t=%0t rptr=%0d", $time, u_fg_fifo.rptr);
        end
    end

    /* ================= 主扫描 ================= */
    integer iw, il, is_, ib, ip, im;
    reg [15:0] wtab [0:7];
    initial begin
        wtab[0]=16'd1; wtab[1]=16'd2; wtab[2]=16'd3; wtab[3]=16'd7;
        wtab[4]=16'd8; wtab[5]=16'd9; wtab[6]=16'd17; wtab[7]=16'd33;
        w2tab[0]=16'd1; w2tab[1]=16'd3; w2tab[2]=16'd8; w2tab[3]=16'd17;
        #20 rst_n = 1'b0;
        repeat (4) @(posedge clk);

        /* +quick：只跑 3 个用例（调试用） */
        if ($test$plusargs("quick")) begin
            run_case(2'd3, 3'd0, 3'd0, 3'd0, 16'd1, 8'd128, 16'h07E0, 16'h7BEF, 0, 0, 8, 4);
            run_case(2'd3, 3'd0, 3'd0, 3'd0, 16'd8, 8'd128, 16'h07E0, 16'h7BEF, 0, 0, 8, 4);
            run_case(2'd2, 3'd3, 3'd2, 3'd3, 16'd9, 8'd128, 16'h0000, 16'h7BEF, 0, 0, 8, 4);
            $display("==== tb_px_path: cases=%0d fails=%0d ====", cases, fails);
            if (fails == 0) $display("========== tb_px_path ALL PASS ==========");
            else            $display("========== tb_px_path FAILED: %0d ==========", fails);
            $finish;
        end

        /* --- S1：无背压，全 op × 全 lane × 全 skip × 8 档 width（ALPHA 逐像素随机值） --- */
        $display("==== S1 无背压扫描（op × dst lane × W × fg/bg skip）====");
        for (iw = 0; iw < 8; iw = iw + 1)
          for (il = 0; il < 8; il = il + 1)
            for (is_ = 0; is_ < 8; is_ = is_ + 1)
              for (ib = 0; ib < 8; ib = ib + 1)
                for (ip = 0; ip < 2; ip = ip + 1)
                  run_case(2'd3, il[2:0], is_[2:0], ib[2:0], wtab[iw], 8'd128,
                           16'h07E0, 16'h7BEF, ip, 0, 8, 4);   // KEY（含整词键色 pat=1）

        for (iw = 0; iw < 8; iw = iw + 1)
          for (il = 0; il < 8; il = il + 1)
            for (is_ = 0; is_ < 8; is_ = is_ + 1)
              for (ib = 0; ib < 8; ib = ib + 1)
                run_case(2'd2, il[2:0], is_[2:0], ib[2:0], wtab[iw], 8'd128,
                         16'h0000, 16'h7BEF, 0, 0, 8, 4);       // ALPHA
        for (iw = 0; iw < 8; iw = iw + 1)
          for (il = 0; il < 8; il = il + 1)
            for (is_ = 0; is_ < 8; is_ = is_ + 1)
              for (ib = 0; ib < 8; ib = ib + 1)
                run_case(2'd0, il[2:0], is_[2:0], ib[2:0], wtab[iw], 8'd128,
                         16'h0000, 16'h7BEF, 0, 0, 8, 4);       // COPY
        for (iw = 0; iw < 8; iw = iw + 1)
          for (il = 0; il < 8; il = il + 1)
            for (is_ = 0; is_ < 8; is_ = is_ + 1)
              for (ib = 0; ib < 8; ib = ib + 1)
                run_case(2'd1, il[2:0], is_[2:0], ib[2:0], wtab[iw], 8'd255,
                         16'hF81F, 16'h7BEF, 2, 0, 8, 4);       // FILL

        /* --- S2：背压（深满 + 慢排空 / 每 N 拍只收 1 词，模拟慢速写从机）--- */
        $display("==== S2 背压扫描（wd full 形态 × op × 对齐）====");
        for (im = 0; im < 4; im = im + 1) begin
            case (im)
                0: begin bp_mode = 1; bp_lim = 1; bp_div = 1; end   // 深 1 词、每拍排空
                1: begin bp_mode = 1; bp_lim = 4; bp_div = 7; end   // 深 4 词、7 拍排 1
                2: begin bp_mode = 2; bp_lim = 8; bp_div = 3; end   // 每 3 拍才收 1 词
                default: begin bp_mode = 2; bp_lim = 8; bp_div = 8; end
            endcase
            for (iw = 0; iw < 4; iw = iw + 1)                  // W ∈ {1,3,8,17}
              for (il = 0; il < 8; il = il + 1)
                for (is_ = 0; is_ < 8; is_ = is_ + 1)
                  for (ip = 0; ip < 4; ip = ip + 1) begin
                    case (ip)
                        0: run_case(2'd1, il[2:0], is_[2:0], il[2:0], w2tab[iw], 8'd255,
                                    16'hF800, 16'h7BEF, 2, bp_mode, bp_lim, bp_div);
                        1: run_case(2'd0, il[2:0], is_[2:0], il[2:0], w2tab[iw], 8'd128,
                                    16'h0000, 16'h7BEF, 0, bp_mode, bp_lim, bp_div);
                        2: run_case(2'd3, il[2:0], is_[2:0], il[2:0], w2tab[iw], 8'd128,
                                    16'h0000, 16'h7BEF, 1, bp_mode, bp_lim, bp_div);
                        default: run_case(2'd2, il[2:0], is_[2:0], il[2:0], w2tab[iw], 8'd96,
                                    16'h0000, 16'h7BEF, 0, bp_mode, bp_lim, bp_div);
                    endcase
                  end
        end

        /* --- S3：ALPHA 的 α 扫描（金标准公式边界） --- */
        $display("==== S3 ALPHA α 扫描 ====");
        for (im = 0; im < 9; im = im + 1) begin
            case (im)
                0: alpha = 8'd0;   1: alpha = 8'd255; 2: alpha = 8'd32;
                3: alpha = 8'd64;  4: alpha = 8'd96;  5: alpha = 8'd160;
                6: alpha = 8'd192; 7: alpha = 8'd224;
                default: alpha = 8'd128;
            endcase
            for (iw = 0; iw < 4; iw = iw + 1)
              for (il = 0; il < 8; il = il + 1)
                for (is_ = 0; is_ < 8; is_ = is_ + 1)
                  run_case(2'd2, il[2:0], is_[2:0], il[2:0], wtab[iw], alpha,
                           16'h0000, 16'h7BEF, 1, 0, 8, 4);
        end

        $display("==== tb_px_path: cases=%0d fails=%0d ====", cases, fails);
        if (fails == 0) $display("========== tb_px_path ALL PASS ==========");
        else            $display("========== tb_px_path FAILED: %0d ==========", fails);
        $finish;
    end

    initial begin
        #900_000_000;
        $display("!!!!!!!! tb_px_path WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end
endmodule
