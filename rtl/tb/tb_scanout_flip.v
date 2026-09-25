/* =========================================================================
 * tb_scanout_flip.v — fb_scanout「三缓冲 FLIP + 帧边界脉冲」正确性验证（v2.7）
 * -------------------------------------------------------------------------
 * 被验证的承诺：
 *   ① fb_sel（2bit 请求）只可能在**帧边界**（hcnt==0 && vcnt==V_ACTIVE）被采样生效；
 *      跨域按 RTL 的**格雷码**走：bin2gray2 → pclk 两级同步 → 帧边界锁存
 *      → core 两级同步 → gray2bin2，最后才在**趟边界**提交成 fb_cur_sel。
 *   ② 每一场显示的像素**只来自一个缓冲**，且等于该场起点锁存到的请求 ⇒ 不会混帧。
 *   ③ 三块缓冲的 **6 个有序对**（0→1 0→2 1→0 1→2 2→0 2→1）各切一遍，每一对都不混帧。
 *   ④ frame_cnt 每个帧边界恰好 +1。
 *   ⑤ frame_pulse 每个帧边界恰好 1 个脉冲、恰好 1 个 core 拍宽（全部在 posedge clk 上量，
 *      所以宽度 = 1 拍这件事本身就证明它是 core 域信号：pclk 域宽度的脉冲会被量成 ~10 拍）。
 *
 * 测试手法：
 *   · 三个缓冲内容**可辨认**：像素 = {缓冲标签 7bit, 源行 4bit, 源列 5bit}，
 *     RGB565→888→565 往返逐位无损 ⇒ 从屏幕像素就能反查出"这块像素来自哪个缓冲"。
 *   · fb_sel 在**故意难受的时刻**变化：场中途、行中途、行末、帧边界前 1 个 core 拍
 *     （太晚，本场看不到）、帧边界刚过、以及一场里连改 4 次；并覆盖全部 6 个有序对。
 *   · 检查在三个层面同时做：
 *       (a) AXI 读地址层面：同一趟取数（row==0 起算）里基址必须恒定 —— 混帧在这里最先暴露；
 *       (b) 生效点层面：每趟基址必须 == 最近一次帧边界锁存到的请求。
 *           TB 自己按 RTL **逐位同构**地建模（格雷编码 → 2 级同步 → 帧边界锁存 →
 *           2 级同步 → 解码），所以期望值与 RTL 在同一采样时刻一致；另外还逐拍比对
 *           RTL 内部寄存器（fb_sel_lat / fb_lat_c1 / fb_cur_sel）与 TB 模型是否逐位相同。
 *       (c) 显示像素层面：每一场的所有 DE 像素必须同一个标签，而且必须等于该场起点
 *           锁存到的请求（逐像素都比一次）。
 *   · 还量了"帧边界 → fb_cur_sel 变化"的延迟（软件有界等待的依据）。
 *
 * A/B 对照：`-DFLIP_UNLATCHED` 把帧边界锁存与趟边界提交**全部旁路**
 *   （请求直通取数基址）。此时本 TB 必须 **FAILED**（混帧必然出现）——
 *   用来证明这套断言真的能抓到"帧中途换缓冲"。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_scanout_flip;
    localparam integer FB_W = 32, FB_H = 16;
    localparam [31:0] FB_BASE  = 32'h0030_1000;      /* 与软件侧 FB_BASE  同址 */
    localparam [31:0] FB_BASE1 = 32'h0050_1000;      /* 与软件侧 FB_BACK  同址 */
    localparam [31:0] FB_BASE2 = 32'h0070_1000;      /* 与软件侧 FB_BUF2  同址 */
    localparam integer FB_STRIDE = 64;               /* 32px * 2B */
    localparam [31:0]  FB_BYTES  = FB_H * FB_STRIDE; /* 1024 B/缓冲，三个窗口互不重叠 */

    /* 像素编码（16bit 全用上，往返无损）：{7bit 缓冲标签, 4bit 行, 5bit 列}
     * 三个标签互不相同，也不是 0/全 1 ⇒ 兜底路径也能识别出"标签非法"。 */
    localparam [6:0] TAG0 = 7'b1010101;              /* 缓冲 0 */
    localparam [6:0] TAG1 = 7'b0101010;              /* 缓冲 1 */
    localparam [6:0] TAG2 = 7'b1100110;              /* 缓冲 2 */

    /* 时序：H_TOTAL=80、V_TOTAL=42 ⇒ 一行 8us(800 core 拍)、一场 336us */
    localparam [11:0] H_ACTIVE = 12'd64, H_FP = 12'd4, H_SYNC = 12'd4, H_BP = 12'd8;
    localparam [11:0] V_ACTIVE = 12'd32, V_FP = 12'd4, V_SYNC = 12'd2, V_BP = 12'd4;

    reg clk = 1'b0, pclk = 1'b0, rst_n = 1'b0, prst_n = 1'b0;
    always #5   clk  = ~clk;      /* core_clk 100MHz */
    always #50  pclk = ~pclk;     /* pixel_clk 10MHz（一行 = 80 pclk = 800 core 拍） */

    /* ---------------- v2.7 跨域建模用的格雷编解码（与 RTL 逐位同构） ---------------- */
    function [1:0] bin2gray2;
        input [1:0] b;
        begin bin2gray2 = b ^ (b >> 1); end
    endfunction
    function [1:0] gray2bin2;
        input [1:0] g;
        begin gray2bin2 = {g[1], g[1] ^ g[0]}; end
    endfunction

    reg  [1:0] fb_sel = 2'd0;     /* CPU 的"请求"（0/1/2 选三块缓冲） */
    wire [1:0] fb_cur_sel;        /* 已经生效的显示缓冲 */
    wire [15:0] frame_cnt;        /* 场计数 */
    wire        frame_pulse;      /* 帧边界脉冲（core 域，1 拍） */
    wire [27:0] m_araddr;
    wire [7:0]  m_arlen;
    wire [2:0]  m_arsize;
    wire [1:0]  m_arburst;
    wire [3:0]  m_arid;
    wire        m_arvalid, m_arready, m_rvalid, m_rlast, m_rready, m_hold;
    wire [127:0] m_rdata;
    wire [1:0]  m_rresp;
    wire [3:0]  m_rid;
    wire        vde, vhs, vvs, frame_tick;
    wire [7:0]  vr, vg, vb;
    wire [11:0] dbg_line;
    wire [15:0] dbg_underrun, dbg_abort;

    /* ---------------- 判定/统计量（全部在模块级声明，供多个 always 引用） ---------------- */
    reg     chk_arm   = 1'b0;         /* 启动瞬态结束后才置 1 */
    reg  [1:0] sel_at_fb = 2'd0;      /* 最近一次帧边界采样到的请求（二进制） */
    reg  [1:0] exp_buf   = 2'd0;      /* 当前这一场应当显示的缓冲 */
    reg     seen0 = 1'b0, seen1 = 1'b0, seen2 = 1'b0;   /* 本场见过的像素标签 */
    wire [2:0] seen_mask = {seen2, seen1, seen0};
    reg  [1:0] buf_seen  = 2'd0;
    integer fb_ev = 0, n_fb_checked = 0;
    integer fc_seen = 0;
    reg  [15:0] fc_prev = 16'd0;
    integer n_fc_bad = 0;
    integer chg_n = 0;
    integer n_mixed_pass = 0, n_bad_base = 0, n_bad_addr = 0, n_row_bad = 0;
    integer n_mixed_field = 0, n_bad_field_buf = 0, n_blank_field = 0, n_bad_tag = 0;
    integer n_px_buf_bad = 0, n_model_bad = 0;
    integer n_col_bad = 0, n_rowjmp = 0, n_rep = 0, n_adv = 0, n_de = 0, n_line = 0;
    integer pass_cnt = 0;
    reg     pass_open = 1'b0;
    reg  [1:0] pass_buf  = 2'd0;
    integer exp_row   = 0;
    integer fetch_cnt = 0;
    integer eff_cnt = 0, eff_max_cyc = 0, eff_min_cyc = 999999, eff_sum_cyc = 0;
    reg  [1:0] cur_prev = 2'd0;
    integer last_fb_ns = 0;
    reg     prev_win = 1'b0;
    integer px_in_row = 0, last_row = -1;
    integer n_err = 0;

    /* 有序对覆盖：下标 = 3*from + to（0→1=1, 0→2=2, 1→0=3, 1→2=5, 2→0=6, 2→1=7）
     *   cov_ex  —— 请求级：fb_sel 真的发生过这个有序变化；
     *   cov_ver —— 场级：相邻两个已判定的场真的显示了 from → to（且两场检查都没报错）。 */
    reg     cov_ex  [0:8];
    reg     cov_ver [0:8];
    reg  [1:0] pf_buf = 2'd0;         /* 上一场判定出的缓冲 */
    reg     pf_valid = 1'b0;

    /* 场内改动次数 / "太晚的改动"（帧边界前不足 1 个 pclk） */
    integer chg_in_field = 0, max_chg_in_field = 0, n_multi_chg_field = 0;
    reg  [1:0] late_prev_g = 2'd0;
    reg     late_pend = 1'b0;
    integer n_late_ok = 0, n_late_bad = 0;

    /* 帧脉冲统计 */
    integer n_fp_total = 0, n_fp_wide = 0, fp_in_win = 0;
    integer n_fp_win_bad = 0, n_fp_win_checked = 0;
    integer n_fc_inc = 0, n_fp_inc_bad = 0;
    reg     fp_d = 1'b0;
    reg  [15:0] fc_d = 16'd0;
    reg     bnd_d = 1'b0, win_open = 1'b0;

    integer i, j;

    fb_scanout #(
        .FB_BASE(FB_BASE), .FB_BASE1(FB_BASE1), .FB_BASE2(FB_BASE2),
        .FB_STRIDE(FB_STRIDE[31:0]), .FB_W(FB_W[11:0]), .FB_H(FB_H[11:0]),
        .WIN_X(12'd0), .WIN_Y(12'd0),
        .H_ACTIVE(H_ACTIVE), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP),
        .V_ACTIVE(V_ACTIVE), .V_FP(V_FP), .V_SYNC(V_SYNC), .V_BP(V_BP),
        .MAX_BURST(8'd16),
        .SCALE_SH(1)                       /* 2 倍放大：64x32 输出铺满 active 区 */
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .fb_sel(fb_sel), .fb_cur_sel(fb_cur_sel), .frame_cnt(frame_cnt),
        .frame_pulse(frame_pulse),
        .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arid(m_arid), .m_axi_arvalid(m_arvalid),
        .m_axi_arready(m_arready), .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp),
        .m_axi_rid(m_rid), .m_axi_rlast(m_rlast), .m_axi_rvalid(m_rvalid),
        .m_axi_rready(m_rready), .m_axi_hold(m_hold),
        .pclk(pclk), .prst_n(prst_n),
        .vde(vde), .vhs(vhs), .vvs(vvs), .vr(vr), .vg(vg), .vb(vb),
        .frame_tick(frame_tick), .dbg_line(dbg_line),
        .dbg_underrun(dbg_underrun), .dbg_abort(dbg_abort),
        /* ★S5（v3.2）新增的扫描输出颜色 LUT 端口：本 TB 只测 FLIP，恒 0 钉住
         * （LUT 的位精确/换 bank 由 rtl/tb/tb_scanout_lut.v 覆盖） */
        .lut_wr(1'b0), .lut_ch(2'b00), .lut_idx(8'd0), .lut_data(8'd0),
        .lut_en(1'b0), .lut_bank_req(1'b0), .lut_bank_act()
    );

    /* ================= 行为 AXI 读从机：三个可辨认的帧缓冲 =================
     * 地址落在哪个窗口 ⇒ 取哪块缓冲的内容（三块窗口都是 1024B，互不重叠）。 */
    function [6:0] tag_of;
        input [1:0] idx;
        begin
            case (idx)
                2'd0:    tag_of = TAG0;
                2'd1:    tag_of = TAG1;
                default: tag_of = TAG2;
            endcase
        end
    endfunction

    function [127:0] beat_of;
        input [31:0] a;
        integer b, row, col0;
        reg [1:0]  idx;
        reg [4:0]  c5;                     /* ★ 必须显式收到 5bit：否则 32bit 的 (col0+b)
                                            *   会把拼接撑到 43bit，赋值时把标签/行号截掉 */
        reg [31:0] off;
        begin
            idx = 2'd0;
            off = 32'd0;
            if      ((a >= FB_BASE ) && (a < (FB_BASE  + FB_BYTES))) begin idx = 2'd0; off = a - FB_BASE;  end
            else if ((a >= FB_BASE1) && (a < (FB_BASE1 + FB_BYTES))) begin idx = 2'd1; off = a - FB_BASE1; end
            else if ((a >= FB_BASE2) && (a < (FB_BASE2 + FB_BYTES))) begin idx = 2'd2; off = a - FB_BASE2; end
            row  = off / FB_STRIDE;
            col0 = ((off % FB_STRIDE) >> 1) & ~7;      /* 8 像素对齐的拍起点 */
            beat_of = 128'd0;
            for (b = 0; b < 8; b = b + 1) begin
                c5 = col0 + b;                         /* 16bit 像素 = {7bit 标签, 4bit 行, 5bit 列} */
                beat_of[b*16 +: 16] = { tag_of(idx), row[3:0], c5 };
            end
        end
    endfunction

    reg [31:0] s_addr;
    reg [7:0]  s_len, s_cnt, s_dly;
    reg [1:0]  rstate;
    localparam RS_IDLE = 2'd0, RS_LAT = 2'd1, RS_SEND = 2'd2;
    reg rvalid_r;

    assign m_arready = (rstate == RS_IDLE);
    assign m_rdata   = beat_of(s_addr);
    assign m_rresp   = 2'b00;
    assign m_rid     = 4'h1;
    assign m_rlast   = (s_cnt == s_len);
    assign m_rvalid  = rvalid_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rstate <= RS_IDLE; rvalid_r <= 1'b0;
            s_addr <= 0; s_len <= 0; s_cnt <= 0; s_dly <= 0;
        end else begin
            case (rstate)
                RS_IDLE: begin
                    if (m_arvalid && m_arready) begin
                        s_addr <= {4'd0, m_araddr};
                        s_len  <= m_arlen;
                        s_cnt  <= 8'd0;
                        s_dly  <= 8'd3;              /* 模拟 DDR 读延迟 */
                        rstate <= RS_LAT;
                        fetch_cnt = fetch_cnt + 1;
                    end
                end
                RS_LAT: begin
                    if (s_dly == 8'd0) begin
                        rvalid_r <= 1'b1;
                        rstate   <= RS_SEND;
                    end else
                        s_dly <= s_dly - 8'd1;
                end
                RS_SEND: begin
                    if (rvalid_r && m_rready) begin
                        if (m_rlast) begin
                            rvalid_r <= 1'b0;
                            rstate   <= RS_IDLE;
                        end else begin
                            s_addr <= s_addr + 16;
                            s_cnt  <= s_cnt + 8'd1;
                        end
                    end
                end
                default: rstate <= RS_IDLE;
            endcase
        end
    end

    /* ================= fb_sel 变更时序：专挑难受的时刻 =================
     * 三个任务分工：
     *   do_chg —— 真正改 fb_sel（统计覆盖对 + 打印；lead>0 且目标就是本场最后一个 pclk
     *             时标记"帧边界前 1 个 core 拍的改动"，供边界后比对锁存值）；
     *   chg_to —— ★ 主任务：**先等到下一个帧边界**再等到本场内的 (vcnt,hcnt)，
     *             保证每场最多改一次 ⇒ 一次改动必然对应"下一场锁存生效"，
     *             6 个有序对就能一场一个地切干净；
     *   chg_at —— 同一场内的第二次/第三次改动（"一场里连改 4 次"专用）。
     *
     * ★ 等点用"每 pclk 边沿轮询 + #1"而不是裸 wait：hcnt/vcnt 是在 pclk 边沿用非阻塞
     *   赋值更新的，边沿活跃区里还是上一拍的旧值，裸 wait 会在"目标点刚好等于上一拍"时
     *   于同一时刻误命中（相邻两次目标相同就会出现，三缓冲序列里必然出现）。 */
    task do_chg;
        input [1:0]  v;
        input integer lead;
        input [11:0] tv;
        input [11:0] th;
        begin
            if (lead > 0) #(lead);
            if ((lead > 0) && (tv == (V_ACTIVE - 12'd1)) && (th == 12'd79)) begin
                late_prev_g = bin2gray2(fb_sel);      /* 改动**之前**的请求 */
                late_pend   = 1'b1;
            end
            if (v !== fb_sel) begin
                cov_ex[3*fb_sel + v] = 1'b1;          /* 请求级：这个有序对真的切过 */
                if (chk_arm) chg_in_field = chg_in_field + 1;
            end
            fb_sel = v;
            chg_n  = chg_n + 1;
            $display("  [chg %0d] t=%0t vcnt=%0d hcnt=%0d -> fb_sel=%0d",
                     chg_n, $time, dut.vcnt, dut.hcnt, v);
        end
    endtask

    task chg_to;
        input [11:0] tv;
        input [11:0] th;
        input [1:0]  v;
        input integer lead;
        begin
            @(posedge pclk);
            #1;
            while (!((dut.hcnt == 12'd0) && (dut.vcnt == V_ACTIVE))) begin
                @(posedge pclk);                      /* 先对齐到下一个帧边界 */
                #1;
            end
            while (!((dut.vcnt == tv) && (dut.hcnt == th))) begin
                @(posedge pclk);                      /* 再到本场内的目标点 */
                #1;
            end
            do_chg(v, lead, tv, th);
        end
    endtask

    task chg_at;
        input [11:0] tv;
        input [11:0] th;
        input [1:0]  v;
        input integer lead;
        begin
            @(posedge pclk);
            #1;
            while (!((dut.vcnt == tv) && (dut.hcnt == th))) begin
                @(posedge pclk);
                #1;
            end
            do_chg(v, lead, tv, th);
        end
    endtask

    /* ================= 与 RTL 同构的格雷码跨域建模 =================
     * core : fb_sel --bin2gray2--> m_sel_g
     * pclk : m_sel_g -2 级同步-> m_p1 --(帧边界 hcnt==0 && vcnt==V_ACTIVE)--> m_lat_g
     * core : m_lat_g -2 级同步-> m_c1 --gray2bin2--> m_lat_bin
     * 于是 (b) 用的期望值 m_lat_bin 与 RTL 的 fb_lat_bin 在**同一采样时刻**逐位相同。
     * m_cur 再按趟边界（st==S_IDLE && next_y==0）提交，对应 RTL 的 fb_cur_sel。 */
    wire [1:0] m_sel_g = bin2gray2(fb_sel);
    reg  [1:0] m_p0 = 2'd0, m_p1 = 2'd0, m_lat_g = 2'd0;
    reg  [1:0] m_c0 = 2'd0, m_c1 = 2'd0;
    reg  [1:0] m_cur = 2'd0;
    wire [1:0] m_lat_bin = gray2bin2(m_c1);

    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            m_p0 <= 2'd0; m_p1 <= 2'd0; m_lat_g <= 2'd0;
        end else begin
            m_p0 <= m_sel_g;
            m_p1 <= m_p0;
            if ((dut.hcnt == 12'd0) && (dut.vcnt == V_ACTIVE))
                m_lat_g <= m_p1;                 /* 与 RTL fb_sel_lat 同刻同值 */
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin m_c0 <= 2'd0; m_c1 <= 2'd0; end
        else        begin m_c0 <= m_lat_g; m_c1 <= m_c0; end
    end

    /* 趟边界提交（对应 RTL：pass_start = st==S_IDLE && next_y==0）。
     * ★ 这里直接读 dut.st / dut.next_y 是为了"同刻"——与 RTL 在同一个时钟沿上看同样的值。 */
`ifdef FLIP_UNLATCHED
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) m_cur <= 2'd0;
        else        m_cur <= fb_sel;             /* A/B：请求直通，无锁存 */
    end
`else
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) m_cur <= 2'd0;
        else if ((dut.st === 2'd0) && (dut.next_y === 12'd0)) m_cur <= m_lat_bin;
    end
`endif

    /* ---- 模型一致性：RTL 内部寄存器必须与 TB 模型逐位相同（编码/同步/锁存/提交全同构） ---- */
    always @(posedge clk) begin
        if (chk_arm) begin
            if (dut.fb_sel_lat !== m_lat_g) begin
                n_model_bad = n_model_bad + 1;
                if (n_model_bad <= 6)
                    $display("FAIL: RTL fb_sel_lat=%b 与 TB 模型 %b 不一致", dut.fb_sel_lat, m_lat_g);
            end
            if (dut.fb_lat_c1 !== m_c1) begin
                n_model_bad = n_model_bad + 1;
                if (n_model_bad <= 6)
                    $display("FAIL: RTL fb_lat_c1=%b 与 TB 模型 %b 不一致", dut.fb_lat_c1, m_c1);
            end
            if (dut.fb_cur_sel !== m_cur) begin
                n_model_bad = n_model_bad + 1;
                if (n_model_bad <= 6)
                    $display("FAIL: RTL fb_cur_sel=%0d 与 TB 模型 %0d 不一致", dut.fb_cur_sel, m_cur);
            end
        end
    end

    /* ================= 帧边界 / 场判定（pclk 域） ================= */
    wire [15:0] px_out = {vr[7:3], vg[7:2], vb[7:3]};      /* 888 -> 565 还原 */
    wire [6:0]  px_tag = px_out[15:9];
    wire [3:0]  px_row = px_out[8:5];
    wire [4:0]  px_col = px_out[4:0];
    wire        win_v  = dut.ctrl2[2];
    wire        de_v   = dut.ctrl2[3];

    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            fb_ev <= 0; sel_at_fb <= 2'd0; exp_buf <= 2'd0;
            n_fb_checked = 0; chg_in_field = 0; max_chg_in_field = 0; n_multi_chg_field = 0;
            pf_valid = 1'b0; pf_buf = 2'd0;
        end else if ((dut.hcnt == 12'd0) && (dut.vcnt == V_ACTIVE)) begin
            /* ---- 一场结束：判"这一场显示的像素是不是只来自一个缓冲，且是不是那个请求的缓冲" ---- */
            if (chk_arm) begin
                case (seen_mask)
                    3'b001: buf_seen = 2'd0;
                    3'b010: buf_seen = 2'd1;
                    3'b100: buf_seen = 2'd2;
                    3'b000: begin
                        buf_seen = 2'd0;
                        n_blank_field = n_blank_field + 1;
                        if (n_blank_field <= 6)
                            $display("FAIL: 第 %0d 场没有任何可辨认的像素", fb_ev);
                    end
                    default: begin                     /* 两个以上标签 ⇒ 显示层面混帧 */
                        buf_seen = 2'd0;
                        n_mixed_field = n_mixed_field + 1;
                        if (n_mixed_field <= 6)
                            $display("FAIL: 第 %0d 场显示里同时出现多个缓冲的像素（混帧！seen=%b）",
                                     fb_ev, seen_mask);
                    end
                endcase
                if ((seen_mask == 3'b001) || (seen_mask == 3'b010) || (seen_mask == 3'b100)) begin
                    if (buf_seen !== exp_buf) begin
                        n_bad_field_buf = n_bad_field_buf + 1;
                        if (n_bad_field_buf <= 6)
                            $display("FAIL: 第 %0d 场显示缓冲=%0d，但该场起点的请求=%0d",
                                     fb_ev, buf_seen, exp_buf);
                    end
                    /* ---- (f) 场级有序对覆盖：相邻两个已判定场真的显示 from -> to ---- */
                    if (pf_valid) cov_ver[3*pf_buf + buf_seen] = 1'b1;
                    pf_buf   = buf_seen;
                    pf_valid = 1'b1;
                end
                n_fb_checked = n_fb_checked + 1;

                /* ---- 场内改动次数统计（>1 次的场必须存在，且不得因此混帧） ---- */
                if (chg_in_field > max_chg_in_field) max_chg_in_field = chg_in_field;
                if (chg_in_field > 1) n_multi_chg_field = n_multi_chg_field + 1;
            end
            chg_in_field = 0;
            seen0 = 1'b0; seen1 = 1'b0; seen2 = 1'b0;

            /* ---- 帧边界：锁存请求（与 RTL 同构：m_p1 就是"两个 pclk 之前"的请求） ---- */
            fb_ev      <= fb_ev + 1;
            sel_at_fb  <= gray2bin2(m_p1);
            exp_buf    <= gray2bin2(m_p1);
            last_fb_ns <= $time;
        end
    end

    /* ---- "帧边界前不足 1 个 pclk 的改动"必须被忽略：边界后 1 个 pclk 看锁存值 ---- */
    always @(posedge pclk) begin
        if (prst_n && late_pend && (dut.hcnt == 12'd1) && (dut.vcnt == V_ACTIVE)) begin
            late_pend = 1'b0;
            if (dut.fb_sel_lat === late_prev_g) begin
                n_late_ok = n_late_ok + 1;
                $display("  [late] t=%0t 帧边界前 1 core 拍的改动被正确忽略（锁存保持 %b）",
                         $time, dut.fb_sel_lat);
            end else begin
                n_late_bad = n_late_bad + 1;
                $display("FAIL: 帧边界前不足 1 pclk 的改动竟然被锁存（锁到 %b，应保持 %b）",
                         dut.fb_sel_lat, late_prev_g);
            end
        end
    end

    /* ---- 场计数：每个帧边界恰好 +1（边界后 2 个 pclk 采样，躲开两级同步的 2~3 core 拍） ---- */
    always @(posedge pclk) begin
        if (prst_n && (dut.hcnt == 12'd2) && (dut.vcnt == V_ACTIVE)) begin
            if (fc_seen && (frame_cnt !== (fc_prev + 16'd1))) begin
                n_fc_bad = n_fc_bad + 1;
                if (n_fc_bad <= 6)
                    $display("FAIL: frame_cnt 不是每场 +1（上一场 %0d，本场 %0d）",
                             fc_prev, frame_cnt);
            end
            fc_prev = frame_cnt;
            fc_seen = 1;
        end
    end

    /* ================= 帧边界脉冲（全部在 posedge clk 上量 ⇒ 证明是 core 域信号） =================
     *   · 相邻两个帧边界之间必须恰好 1 个脉冲（少/多都算错）；
     *   · 不允许"上一拍也是高"（宽度 > 1 个 core 拍）；
     *   · 脉冲必须与 frame_cnt 自增同拍出现（同一个事件的两个寄存器），且每场只自增一次。 */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fp_d <= 1'b0; fc_d <= 16'd0; bnd_d <= 1'b0; win_open <= 1'b0;
            fp_in_win = 0; n_fp_total = 0; n_fp_wide = 0;
            n_fp_win_bad = 0; n_fp_win_checked = 0;
            n_fc_inc = 0; n_fp_inc_bad = 0;
        end else begin
            /* ---- 帧边界（core 域看到的那一拍）：结算上一个窗口 ---- */
            if ((dut.hcnt == 12'd0) && (dut.vcnt == V_ACTIVE)) begin
                if (!bnd_d) begin                      /* 只在边界开始的那一拍结算 */
                    if (win_open && chk_arm) begin
                        n_fp_win_checked = n_fp_win_checked + 1;
                        if (fp_in_win !== 1) begin
                            n_fp_win_bad = n_fp_win_bad + 1;
                            if (n_fp_win_bad <= 6)
                                $display("FAIL: 一个场里 frame_pulse 个数 = %0d（应为 1）", fp_in_win);
                        end
                    end
                    fp_in_win = 0;
                    win_open  = 1'b1;
                end
                bnd_d <= 1'b1;
            end else
                bnd_d <= 1'b0;

            /* ---- 脉冲计数 + 宽度（> 1 拍就是错） ---- */
            if (frame_pulse) begin
                n_fp_total = n_fp_total + 1;
                if (win_open) fp_in_win = fp_in_win + 1;
                if (fp_d) begin
                    n_fp_wide = n_fp_wide + 1;
                    if (n_fp_wide <= 6)
                        $display("FAIL: frame_pulse 宽度 > 1 个 core 拍（t=%0t）", $time);
                end
            end
            fp_d <= frame_pulse;

            /* ---- 与 frame_cnt 自增同拍 ---- */
            if (frame_cnt !== fc_d) begin
                if ((frame_cnt === (fc_d + 16'd1))) begin
                    n_fc_inc = n_fc_inc + 1;
                    if (chk_arm && !frame_pulse) begin
                        n_fp_inc_bad = n_fp_inc_bad + 1;
                        if (n_fp_inc_bad <= 6)
                            $display("FAIL: frame_cnt 自增那一拍没有 frame_pulse（t=%0t）", $time);
                    end
                end else begin
                    if (chk_arm) begin
                        n_fc_bad = n_fc_bad + 1;
                        if (n_fc_bad <= 6)
                            $display("FAIL: frame_cnt 跳变 %0d -> %0d", fc_d, frame_cnt);
                    end
                end
            end
            fc_d <= frame_cnt;
        end
    end

    /* ---- 翻转生效延迟：帧边界 → fb_cur_sel 变化（软件有界等待的依据） ---- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_prev <= 2'd0;
        end else begin
            cur_prev <= fb_cur_sel;
            if (chk_arm && (fb_cur_sel !== cur_prev)) begin
                eff_cnt     = eff_cnt + 1;
                eff_sum_cyc = eff_sum_cyc + (($time - last_fb_ns) / 10);   /* core 周期 = 10ns */
                if ((($time - last_fb_ns) / 10) > eff_max_cyc) eff_max_cyc = ($time - last_fb_ns) / 10;
                if ((($time - last_fb_ns) / 10) < eff_min_cyc) eff_min_cyc = ($time - last_fb_ns) / 10;
                $display("  [eff %0d] t=%0t fb_cur_sel=%0d，距帧边界 %0d core 拍",
                         eff_cnt, $time, fb_cur_sel, ($time - last_fb_ns) / 10);
            end
        end
    end

    /* ---- 显示像素：逐行结构 + 缓冲标签（每个像素都对照"本场应显示的缓冲"） ---- */
    always @(negedge pclk) begin
        if (!prst_n) begin
            prev_win = 1'b0; px_in_row = 0; last_row = -1;
        end else begin
            if (win_v) begin
                if (!prev_win) begin                     /* 新的输出行 */
                    n_line = n_line + 1;
                    px_in_row = 0;
                    if (chk_arm && (px_col != 5'd0)) begin
                        n_col_bad = n_col_bad + 1;
                        if (n_col_bad <= 6) $display("FAIL: 行首源列号应为 0，实际 %0d", px_col);
                    end
                    if (chk_arm && (last_row >= 0)) begin
                        if      (px_row == last_row[3:0])             n_rep = n_rep + 1;
                        else if (px_row == ((last_row[3:0] + 4'd1)))  n_adv = n_adv + 1;
                        else if (!((last_row == (FB_H-1)) && (px_row == 4'd0))) begin
                            n_rowjmp = n_rowjmp + 1;
                            if (n_rowjmp <= 6)
                                $display("FAIL: 显示源行号跳变 %0d -> %0d", last_row, px_row);
                        end
                    end
                    last_row = px_row;
                end else
                    px_in_row = px_in_row + 1;

                if (chk_arm) begin
                    n_de = n_de + 1;
                    if      (px_tag == TAG0) seen0 = 1'b1;
                    else if (px_tag == TAG1) seen1 = 1'b1;
                    else if (px_tag == TAG2) seen2 = 1'b1;
                    else begin
                        n_bad_tag = n_bad_tag + 1;
                        if (n_bad_tag <= 6)
                            $display("FAIL: 像素标签非法 %b（像素 %x）", px_tag, px_out);
                    end
                    /* ---- (c) 逐像素：本场所有 DE 像素必须都属于"本场应显示的缓冲" ---- */
                    if ((px_tag !== TAG0) && (px_tag !== TAG1) && (px_tag !== TAG2)) ;
                    else if (px_tag !== tag_of(exp_buf)) begin
                        n_px_buf_bad = n_px_buf_bad + 1;
                        if (n_px_buf_bad <= 6)
                            $display("FAIL: 像素标签 %b 不属于本场应显示的缓冲 %0d（t=%0t）",
                                     px_tag, exp_buf, $time);
                    end
                end
            end
            prev_win = win_v;
        end
    end

    /* ================= 取数侧（AXI 读地址）断言 ================= */
    reg [31:0] ar_addr;
    reg [31:0] ar_off;
    reg  [1:0] ar_buf;
    reg        ar_bad;
    integer    ar_row;

    always @(posedge clk) begin
        if (m_arvalid && m_arready) begin
            ar_addr = {4'd0, m_araddr};
            ar_bad  = 1'b0;
            if      ((ar_addr >= FB_BASE ) && (ar_addr < (FB_BASE  + FB_BYTES))) begin ar_buf = 2'd0; ar_off = ar_addr - FB_BASE;  end
            else if ((ar_addr >= FB_BASE1) && (ar_addr < (FB_BASE1 + FB_BYTES))) begin ar_buf = 2'd1; ar_off = ar_addr - FB_BASE1; end
            else if ((ar_addr >= FB_BASE2) && (ar_addr < (FB_BASE2 + FB_BYTES))) begin ar_buf = 2'd2; ar_off = ar_addr - FB_BASE2; end
            else begin
                ar_buf = 2'd0; ar_off = 32'd0; ar_bad = 1'b1;
                n_bad_addr = n_bad_addr + 1;
                if (n_bad_addr <= 6)
                    $display("FAIL: 取数地址 %x 不在三个帧缓冲窗口内", ar_addr);
            end
            ar_row = ar_off / FB_STRIDE;

            if (!ar_bad && (ar_row == 0)) begin          /* ---- 新的一趟取数 ---- */
                pass_cnt  = pass_cnt + 1;
                pass_buf  = ar_buf;
                pass_open = 1'b1;
                exp_row   = 0;
                if (chk_arm) begin
                    /* (b) 趟基址必须 == 最近一次帧边界锁存到的请求（TB 模型与 RTL 同构） */
                    if (ar_buf !== m_lat_bin) begin
                        n_bad_base = n_bad_base + 1;
                        if (n_bad_base <= 6)
                            $display("FAIL: 第 %0d 趟基址=%0d，但最近帧边界锁存到的请求=%0d",
                                     pass_cnt, ar_buf, m_lat_bin);
                    end
                    /* 两个参考量（core 域同步值 / pclk 域锁存值）必须一致 */
                    if (m_lat_bin !== sel_at_fb) begin
                        n_model_bad = n_model_bad + 1;
                        if (n_model_bad <= 6)
                            $display("FAIL: TB 参考模型不自洽（core 域 %0d != pclk 域 %0d）",
                                     m_lat_bin, sel_at_fb);
                    end
                end
            end else if (pass_open && (ar_buf !== pass_buf)) begin
                n_mixed_pass = n_mixed_pass + 1;         /* ★ 混帧的直接证据 */
                if (n_mixed_pass <= 6)
                    $display("FAIL: 同一趟取数里出现两个缓冲（行 %0d：%0d -> %0d）",
                             ar_row, pass_buf, ar_buf);
            end
            if (pass_open && (ar_row != exp_row)) begin
                n_row_bad = n_row_bad + 1;
                if (n_row_bad <= 6)
                    $display("FAIL: 趟内行号跳变（期望 %0d，实际 %0d，基址 %0d）",
                             exp_row, ar_row, ar_buf);
            end
            if (pass_open) exp_row = ar_row + 1;
        end
    end

    /* ================= 激励 + 结束判定 ================= */
    initial begin
        for (i = 0; i <= 8; i = i + 1) begin
            cov_ex[i]  = 1'b0;
            cov_ver[i] = 1'b0;
        end
        #200 rst_n = 1'b1; prst_n = 1'b1;

        /* 先跑 3 场让行缓冲 / CDC 进入稳态，再开始计数与判定 */
        wait (fb_ev >= 3);
        chk_arm = 1'b1;

`ifdef FLIP_UNLATCHED
        $display("---- 编译选项：-DFLIP_UNLATCHED（锁存被旁路，本 TB 预期 FAILED）----");
`else
        $display("---- 编译选项：默认（帧边界锁存 + 趟边界提交生效）----");
`endif
        $display("---- chk_arm @ t=%0t（fb_ev=%0d）----", $time, fb_ev);

        /* ---- 6 个有序对各切一遍：**每场只改一次**（改动落在可视区内，下一场边界锁存生效） ----
         * 注意本 TB 里的"帧边界"= vcnt==V_ACTIVE(32) 那一拍（垂直消隐起点），
         * 不是 vcnt 41→0；vcnt≥32 的改动属于"边界之后"，只影响下一场。 */
        chg_to(12'd6,  12'd20, 2'd1, 0);     /* 场中途 + 行中途：0 -> 1 ⇒ 下一场显示 BUF1 */
        chg_to(12'd6,  12'd20, 2'd2, 0);     /* 1 -> 2 */
        chg_to(12'd20, 12'd10, 2'd0, 0);     /* 场偏后 + 行中途：2 -> 0 */
        chg_to(12'd6,  12'd20, 2'd2, 0);     /* 0 -> 2（跨过 1，两位同时变 ⇒ 靠格雷码兜住） */
        chg_to(12'd6,  12'd30, 2'd1, 0);     /* 2 -> 1 */
        chg_to(12'd6,  12'd30, 2'd0, 0);     /* 1 -> 0 */

        /* ---- 一场里连改 4 次（用 chg_at：都落在同一场内依次靠后的点；
         *      最后一个 1 才是本场边界锁存到的值） ---- */
        chg_at(12'd4,  12'd10, 2'd1, 0);
        chg_at(12'd8,  12'd10, 2'd2, 0);
        chg_at(12'd12, 12'd10, 2'd0, 0);
        chg_at(12'd16, 12'd10, 2'd1, 0);

        /* ---- ★ 帧边界前 1 个 core 拍（太晚）：本场必须看不到它，仍显示 BUF1 ---- */
        chg_to(12'd31, 12'd79, 2'd2, 90);

        /* ---- 继续其它难受时刻：行末 / 帧边界刚过（同样每场一次） ---- */
        chg_to(12'd6,  12'd20, 2'd0, 0);     /* 2 -> 0 */
        chg_to(12'd10, 12'd77, 2'd1, 0);     /* 行末前 2 拍：0 -> 1 */
        chg_to(12'd32, 12'd5,  2'd0, 0);     /* 帧边界刚过 5 个 pclk：1 -> 0 */

        /* 安静跑 4 场，让最后一次翻转完整生效并被逐场检查 */
        repeat (4) begin
            @(posedge pclk);
            wait ((dut.hcnt == 12'd0) && (dut.vcnt == V_ACTIVE));
        end
        #2000;                               /* 让最后一个脉冲/自增也落进统计 */

        $display("--------------------------------------------------");
        $display("fb_sel 变更次数            = %0d", chg_n);
        $display("帧边界数 / 判定过的场数    = %0d / %0d", fb_ev, n_fb_checked);
        $display("取数趟数 / 取数笔数(AR)    = %0d / %0d", pass_cnt, fetch_cnt);
        $display("(a) 一趟里混两个缓冲的次数 = %0d  (必须 0)", n_mixed_pass);
        $display("(b) 趟基址 != 帧边界请求   = %0d  (必须 0)", n_bad_base);
        $display("(c) 一场显示混两个缓冲     = %0d  (必须 0)", n_mixed_field);
        $display("(c2) 一场显示的不是请求缓冲= %0d  (必须 0)", n_bad_field_buf);
        $display("(c3) 像素不属于本场缓冲    = %0d  (必须 0)", n_px_buf_bad);
        $display("(c4) 空场（无可辨认像素）  = %0d", n_blank_field);
        $display("(d) frame_cnt 不是每场 +1  = %0d  (必须 0)", n_fc_bad);
        $display("(e) 一个场里脉冲数 != 1    = %0d  (必须 0)   判定窗数 = %0d", n_fp_win_bad, n_fp_win_checked);
        $display("(e2) 脉冲宽度 > 1 core 拍  = %0d  (必须 0)", n_fp_wide);
        $display("(e3) 脉冲总数 / frame_cnt 自增次数 = %0d / %0d", n_fp_total, n_fc_inc);
        $display("(e4) 自增那一拍无脉冲次数  = %0d  (必须 0)", n_fp_inc_bad);
        $display("RTL/TB 跨域模型不一致次数  = %0d  (必须 0)", n_model_bad);
        $display("非法取数地址 / 非法标签    = %0d / %0d", n_bad_addr, n_bad_tag);
        $display("趟内行号跳变 / 显示行跳变  = %0d / %0d", n_row_bad, n_rowjmp);
        $display("显示行重复/前进            = %0d / %0d (2 倍放大 ⇒ 两者应接近)", n_rep, n_adv);
        $display("行首列号错 / 输出行数 / DE = %0d / %0d / %0d", n_col_bad, n_line, n_de);
        $display("翻转生效次数 / 延迟(core拍)= %0d / min %0d, max %0d, avg %0d",
                 eff_cnt, (eff_min_cyc == 999999 ? 0 : eff_min_cyc), eff_max_cyc,
                 (eff_cnt ? (eff_sum_cyc / eff_cnt) : 0));
        $display("dbg_underrun / dbg_abort   = %0d / %0d", dbg_underrun, dbg_abort);
        $display("(f1) 有序对覆盖（1=已覆盖/已验证）");
        $display("     有序对 :  0->1  0->2  1->0  1->2  2->0  2->1");
        $display("     请求级 :   %0d     %0d     %0d     %0d     %0d     %0d",
                 cov_ex[1], cov_ex[2], cov_ex[3], cov_ex[5], cov_ex[6], cov_ex[7]);
        $display("     场级   :   %0d     %0d     %0d     %0d     %0d     %0d",
                 cov_ver[1], cov_ver[2], cov_ver[3], cov_ver[5], cov_ver[6], cov_ver[7]);
        $display("(f2) 一场内最多改动次数    = %0d（改动 >1 次的场数 = %0d）",
                 max_chg_in_field, n_multi_chg_field);
        $display("(f3) 帧边界前 <1 pclk 的改动= 正确忽略 %0d 次 / 误锁存 %0d 次", n_late_ok, n_late_bad);
        $display("--------------------------------------------------");

        if (n_mixed_pass != 0)    begin $display("FAIL: 取数层面出现混帧");           n_err = n_err + 1; end
        if (n_bad_base != 0)      begin $display("FAIL: 有趟的基址不是帧边界锁存值"); n_err = n_err + 1; end
        if (n_mixed_field != 0)   begin $display("FAIL: 显示层面出现混帧");           n_err = n_err + 1; end
        if (n_bad_field_buf != 0) begin $display("FAIL: 显示的不是请求的那个缓冲");   n_err = n_err + 1; end
        if (n_px_buf_bad != 0)    begin $display("FAIL: 有像素不属于本场缓冲");       n_err = n_err + 1; end
        if (n_fc_bad != 0)        begin $display("FAIL: frame_cnt 不是每场恰好 +1"); n_err = n_err + 1; end
        if (n_fp_win_bad != 0)    begin $display("FAIL: 一个场里的 frame_pulse 不是恰好 1 个"); n_err = n_err + 1; end
        if (n_fp_wide != 0)       begin $display("FAIL: frame_pulse 宽度超过 1 个 core 拍");   n_err = n_err + 1; end
        if (n_fp_inc_bad != 0)    begin $display("FAIL: frame_cnt 自增那一拍没有脉冲");         n_err = n_err + 1; end
        if (n_fp_total != n_fc_inc) begin $display("FAIL: 脉冲总数与场自增次数不符");           n_err = n_err + 1; end
        if (n_model_bad != 0)     begin $display("FAIL: RTL 与 TB 跨域模型不一致");   n_err = n_err + 1; end
        if (n_bad_addr != 0)      begin $display("FAIL: 出现越界取数地址");           n_err = n_err + 1; end
        if (n_bad_tag != 0)       begin $display("FAIL: 显示像素标签非法");           n_err = n_err + 1; end
        if (n_row_bad != 0)       begin $display("FAIL: 趟内行号跳变");               n_err = n_err + 1; end
        if (n_rowjmp != 0)        begin $display("FAIL: 显示源行号跳变");             n_err = n_err + 1; end
        if (n_col_bad != 0)       begin $display("FAIL: 行首列号不为 0");             n_err = n_err + 1; end
        if (n_de == 0)            begin $display("FAIL: 根本没检查到 DE 像素");       n_err = n_err + 1; end
        if (pass_cnt < 8)         begin $display("FAIL: 取数趟数太少（%0d）", pass_cnt); n_err = n_err + 1; end
        if (n_fb_checked < 8)     begin $display("FAIL: 判定过的场数太少（%0d）", n_fb_checked); n_err = n_err + 1; end
        if (eff_cnt < 4)          begin $display("FAIL: 翻转生效次数太少（%0d）", eff_cnt); n_err = n_err + 1; end
        if ((n_rep < 8) || (n_adv < 8)) begin
            $display("FAIL: 纵向放大异常 (rep=%0d adv=%0d)", n_rep, n_adv); n_err = n_err + 1;
        end
        /* ---- (f) 6 个有序对：请求级必须都覆盖、场级必须都验证过 ---- */
        for (j = 0; j <= 8; j = j + 1) begin
            if ((j / 3) != (j % 3)) begin            /* 跳过 0->0 / 1->1 / 2->2 这种不存在的变化 */
                if (cov_ex[j] != 1'b1) begin
                    $display("FAIL: 请求级有序对 %0d->%0d 从未切过", j/3, j%3); n_err = n_err + 1;
                end
                if (cov_ver[j] != 1'b1) begin
                    $display("FAIL: 场级有序对 %0d->%0d 未被验证", j/3, j%3); n_err = n_err + 1;
                end
            end
        end
        if (n_multi_chg_field < 1) begin $display("FAIL: 没有'一场内改动 >1 次'的场"); n_err = n_err + 1; end
        if (max_chg_in_field < 2)  begin $display("FAIL: 一场内最多改动次数 < 2");     n_err = n_err + 1; end
        if (n_late_ok < 1)         begin $display("FAIL: 没有验证'帧边界前 1 拍改动被忽略'"); n_err = n_err + 1; end
        if (n_late_bad != 0)       begin $display("FAIL: 太晚的改动被锁存了");         n_err = n_err + 1; end

        if (n_err == 0)
            $display("========== tb_scanout_flip ALL PASS ==========");
        else
            $display("========== tb_scanout_flip FAILED (%0d 项) ==========", n_err);
        $finish;
    end
endmodule
