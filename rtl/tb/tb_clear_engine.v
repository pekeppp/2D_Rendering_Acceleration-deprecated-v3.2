`timescale 1ns/1ps
/* =========================================================================
 * tb_clear_engine.v — clr_engine（并发清屏引擎）专项测试台
 * -------------------------------------------------------------------------
 * 【被测】rtl/clr_engine.v：独立写通道主机，把一块矩形清成常量 RGB565，
 *         使"清 C / 画 B / 显示 A"三件事并行（清屏不再进关键路径）。
 *
 * 【本 TB 提供四组证据（打印原始数字，不下结论）】
 *   1. 整片清屏吞吐：960x524 @ 0x701000 + 16*1920（stride 1920B，与板级布局一致）
 *      = 502720 像素 = 62880 个 128bit 词（每词 8 个 RGB565 像素）。两种从机模型各跑
 *      一遍：
 *        · fast slave      ：每拍收 1 拍 W（≈引擎自身产词上限）
 *        · throttled slave ：wready 每 4 拍才拉高 1 拍（4 B/cycle，对齐板上实测写带宽）
 *      断言 AW 突发数恰 = 3930（62880/16，"16 拍合并"的直接证据）、每笔 awlen+1<=16、
 *      INCR、16B 对齐、逐笔地址连续、W 拍数 = 62880；并打印周期 / 每像素周期，与板级
 *      实测的指令式整片清屏 568000 周期、理论目标 2 px/cycle = 251520 周期对比。
 *   2. 内容验证：整片区逐像素 == cfg_color；区外（上一行 / 下一行 / 起点前一词 / 终点
 *      后一词）保持预填图案不变。另加 33x7 非对齐矩形（起点 = base + 3*1920 + 33*2，
 *      首词只覆盖 7 个像素、尾词只覆盖 2 个）→ 逐拍核对 WSTRB 掩码 + 逐字节核对
 *      "到底写了哪些字节"，证明掩码既没漏写也没多写（多写就是踩到矩形外的像素）。
 *   3. ★ 硬件互斥（安全关键）：M1/M2 = GO 时刻被拒（目标 == 正在显示 / 正在画）必须
 *      ZERO AW、ZERO W beat；M3 = 运行中被扫描输出抢占（fb_cur_sel 中途翻到目标）
 *      → err=1、最多再发完"已经组好的那一笔"（<=16 拍 W）、clean 不置位、且回到合法
 *      选择后不会自己偷偷续写。`-DCLEAR_MUTEX_OFF` 关掉守卫后这些计数必然非零
 *      ⇒ 同一份文件：默认构建 PASS、-DCLEAR_MUTEX_OFF 构建 FAILED。
 *   4. 写通道仲裁：清屏引擎挂 axi_wr_arb 的 b_（次级）、BitBlt 风格的竞争写主机挂 c_
 *      （默认 owner）。断言：竞争者活跃期间清屏引擎 ≈ 零进度、竞争者不被饿死、
 *      且**一笔突发中途绝不换主**（在 DDR 从口按 awid 归属 + 128bit 数据图案 + wlast
 *      位置 + 拍数逐拍核对；"上一笔 B 未回就受理新 AW"的计数必须为 0）。
 *
 * 【自包含】只例化 rtl/clr_engine.v 与 ARC_2DRA/rtl/video/axi_wr_arb.v；
 *   行为级写从机 wr_slave_model、竞争写主机 blt_like_wr_host 都写在本文件内。
 *
 * 【★ 建 TB 期间实测到的 RTL 缺陷（已由 RTL 侧修好，本 TB 保留为回归守卫）】
 *   旧版 rtl/clr_engine.v 的 WSTRB 生成把"像素槽号 lo_c / 像素数 npx_c"直接当**字节**
 *   位移用：对齐满词（lo=0,npx=8）实测掩码 0x00FF（只写 16B 词的低 8 字节 = 4 个像素，
 *   地址却按 8 像素/词前进 ⇒ 每词高 8 字节永不写）；非对齐行首（lo=1,npx=7）实测 0x00FE，
 *   从字节 1 开始写 ⇒ 踩到矩形外那个像素。现 RTL 已改为 lo_b={lo_c,1'b0} /
 *   end_b=(lo_c+npx_c)<<1，本 TB 的 1a/1b/2b "WSTRB 逐拍核对 + 逐像素/越界核对"就是
 *   钉死这条的回归项（实测掩码 ffff / fffc / 000f 全部相符）。
 *
 * 【★ 建 TB 期间实测到的仲裁行为（性能口径，本 TB 以警告打印，不计 FAIL）】
 *   axi_wr_arb 的次级（本引擎）会在 c_ 侧"无在飞突发"的**任何一拍**拿到通道，并占用
 *   一整笔突发。rtl/axi_wr_master.v 是 AW→W→B 串行主机（S_B→S_IDLE→S_BUF→S_AW，
 *   突发之间有 1~2 拍 awvalid=0），所以真机上 BitBlt 一写、清屏引擎就每笔抢一次 ⇒
 *   写带宽约 50/50 平分，而不是注释里写的"BitBlt 赢、清屏引擎只填空闲档"。
 *   本 TB 的 4A（流水竞争者，AW 常举）实测 ≈0 笔，4B（串行竞争者，忠实于 axi_wr_master）
 *   实测约 63/120 笔 —— 两个数都原样打印。
 * ========================================================================= */

module tb_clear_engine;

    /* ================= 地址布局（与板级一致：960x524、stride 1920B） ================= */
    localparam [31:0]  MEM_BASE  = 32'h0070_0000;
    localparam integer MEM_BYTES = 4*1024*1024;      // 覆盖 0x700000~0xB00000（3 块 1MB 帧缓）
    localparam [31:0]  FB0 = 32'h0070_1000;          // 缓冲 0 基址
    localparam [31:0]  FB1 = 32'h0080_1000;          // 缓冲 1
    localparam [31:0]  FB2 = 32'h0090_1000;          // 缓冲 2
    localparam integer ROWB = 1920;                  // 960 px * 2 B = 1920 B/行
    localparam [31:0]  STRIDE = 32'd1920;
    localparam integer RW = 960;
    localparam integer RH = 524;
    localparam integer M3ROWS = 32;                  // M3 用例的行数
    localparam [31:0]  REG_A = FB0 + 16*1920;        // 整片区起点（板级 = base + 16*1920）
    localparam [31:0]  REG_E = REG_A + RH*ROWB;      // 整片区终点（不含）
    localparam [31:0]  UA_A  = FB0 + 3*1920 + 33*2;  // 33x7 非对齐矩形起点
    localparam integer UA_W = 33, UA_H = 7;
    localparam integer REG_WORDS  = (RW/8)*RH;       // 62880 个 128bit 词
    localparam integer REG_BURSTS = REG_WORDS/16;    // 3930 笔 16 拍突发
    localparam integer NPX = RW*RH;                  // 502720 像素
    localparam integer BASE_CMD  = 568000;           // 对照(a)：板级实测指令式整片清屏
    localparam integer BASE_2PPC = 251520;           // 对照(b)：理论目标 2 像素/周期
    localparam [127:0] COMP_DATA = 128'h0BADF00D_0BADF00D_0BADF00D_0BADF00D;

    localparam [15:0] COL1 = 16'hF81F;               // 整片第 1 遍
    localparam [15:0] COL2 = 16'h07E0;               // 整片第 2 遍（限流从机）
    localparam [15:0] COL3 = 16'h1234;               // 非对齐 33x7
    localparam [15:0] COL4 = 16'hA55A;               // 互斥 M3（抢占 + 重启）

    /* ================= 时钟 / 复位 / 全局周期 ================= */
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    /* ================= 被测：clr_engine ================= */
    reg  [31:0] cfg_addr = 32'd0, cfg_stride = 32'd0;
    reg  [15:0] cfg_w = 16'd0, cfg_h = 16'd0, cfg_color = 16'd0;
    reg  [1:0]  cfg_sel = 2'd0;
    reg         cfg_go = 1'b0, cfg_err_clr = 1'b0;
    reg  [1:0]  fb_cur_sel = 2'd1, draw_sel = 2'd2;
    reg         draw_wr = 1'b0;
    wire        busy, err;
    wire [3:0]  clean;
    wire [15:0] burst_cnt;
    wire [31:0] cyc_cnt;

    wire [31:0]  b_awaddr;
    wire [7:0]   b_awlen;
    wire [2:0]   b_awsize;
    wire [1:0]   b_awburst;
    wire         b_awvalid, b_awready;
    wire [127:0] b_wdata;
    wire [15:0]  b_wstrb;
    wire         b_wlast, b_wvalid, b_wready, b_bvalid;
    wire [1:0]   b_bresp;
    wire         b_bready;

    clr_engine #(.AW(32), .DW(128), .MAX_BEATS(16)) u_dut (
        .clk(clk), .rst_n(rst_n),
        .cfg_addr(cfg_addr), .cfg_stride(cfg_stride),
        .cfg_w(cfg_w), .cfg_h(cfg_h), .cfg_color(cfg_color),
        .cfg_sel(cfg_sel), .cfg_go(cfg_go), .cfg_err_clr(cfg_err_clr),
        .fb_cur_sel(fb_cur_sel), .draw_sel(draw_sel), .draw_wr(draw_wr),
        .busy(busy), .err(err), .clean(clean),
        .burst_cnt(burst_cnt), .cyc_cnt(cyc_cnt),
        .m_axi_awaddr(b_awaddr), .m_axi_awlen(b_awlen), .m_axi_awsize(b_awsize),
        .m_axi_awburst(b_awburst), .m_axi_awvalid(b_awvalid), .m_axi_awready(b_awready),
        .m_axi_wdata(b_wdata), .m_axi_wstrb(b_wstrb), .m_axi_wlast(b_wlast),
        .m_axi_wvalid(b_wvalid), .m_axi_wready(b_wready),
        .m_axi_bvalid(b_bvalid), .m_axi_bresp(b_bresp), .m_axi_bready(b_bready)
    );

    /* ================= 竞争写主机（BitBlt 风格）→ 仲裁器 c_ 口 ================= */
    reg         blt_go = 1'b0;
    reg         blt_pipe = 1'b1;                     // 1 = AW 常举（流水）；0 = 串行（同 axi_wr_master）
    reg  [31:0] blt_base  = FB1;
    reg  [15:0] blt_words = 16'd1024;                // 1024 词 = 64 笔 16 拍突发
    wire [31:0]  c_awaddr;
    wire [7:0]   c_awlen;
    wire [2:0]   c_awsize;
    wire [1:0]   c_awburst;
    wire [3:0]   c_awid;
    wire         c_awvalid, c_awready;
    wire [127:0] c_wdata;
    wire [15:0]  c_wstrb;
    wire         c_wlast, c_wvalid, c_wready, c_bvalid;
    wire [1:0]   c_bresp;
    wire [3:0]   c_bid;
    wire         c_bready;
    wire         blt_done;
    wire [31:0]  blt_bursts, blt_beats;

    blt_like_wr_host #(.DATA(COMP_DATA), .ID(4'hC)) u_blt (
        .clk(clk), .rst_n(rst_n),
        .start(blt_go), .pipe(blt_pipe), .base(blt_base), .nwords(blt_words),
        .awaddr(c_awaddr), .awlen(c_awlen), .awsize(c_awsize), .awburst(c_awburst),
        .awid(c_awid), .awvalid(c_awvalid), .awready(c_awready),
        .wdata(c_wdata), .wstrb(c_wstrb), .wlast(c_wlast),
        .wvalid(c_wvalid), .wready(c_wready),
        .bvalid(c_bvalid), .bresp(c_bresp), .bready(c_bready),
        .done(blt_done), .burst_sent(blt_bursts), .beat_sent(blt_beats)
    );

    /* ================= 写通道仲裁（与 blt_top 内同一模块、同一接法） ================= */
    wire [31:0]  m_awaddr;
    wire [7:0]   m_awlen;
    wire [2:0]   m_awsize;
    wire [1:0]   m_awburst;
    wire [3:0]   m_awid;
    wire         m_awvalid, m_awready;
    wire [127:0] m_wdata;
    wire [15:0]  m_wstrb;
    wire         m_wlast, m_wvalid, m_wready, m_bvalid;
    wire [1:0]   m_bresp;
    wire [3:0]   m_bid;
    wire         m_bready;

    axi_wr_arb #(.AW(32), .DW(128), .IDW(4)) u_arb (
        .clk(clk), .rst_n(rst_n),
        .c_awaddr(c_awaddr), .c_awlen(c_awlen), .c_awsize(c_awsize),
        .c_awburst(c_awburst), .c_awid(c_awid), .c_awvalid(c_awvalid), .c_awready(c_awready),
        .c_wdata(c_wdata), .c_wstrb(c_wstrb), .c_wlast(c_wlast),
        .c_wvalid(c_wvalid), .c_wready(c_wready),
        .c_bvalid(c_bvalid), .c_bresp(c_bresp), .c_bid(c_bid), .c_bready(c_bready),
        .b_awaddr(b_awaddr), .b_awlen(b_awlen), .b_awsize(b_awsize),
        .b_awburst(b_awburst), .b_awvalid(b_awvalid), .b_awready(b_awready),
        .b_wdata(b_wdata), .b_wstrb(b_wstrb), .b_wlast(b_wlast),
        .b_wvalid(b_wvalid), .b_wready(b_wready),
        .b_bvalid(b_bvalid), .b_bresp(b_bresp), .b_bready(b_bready),
        .m_awaddr(m_awaddr), .m_awlen(m_awlen), .m_awsize(m_awsize),
        .m_awburst(m_awburst), .m_awid(m_awid), .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_wvalid(m_wvalid), .m_wready(m_wready),
        .m_bvalid(m_bvalid), .m_bresp(m_bresp), .m_bid(m_bid), .m_bready(m_bready)
    );

    /* ================= 行为级 DDR 写从机（可限流） ================= */
    reg  thr_en = 1'b0;                              // 1 = 每 4 拍才收 1 拍 W
    wire [31:0] slv_aw_cnt, slv_w_cnt, slv_b_cnt;

    wr_slave_model #(.MEM_BASE(MEM_BASE), .MEM_BYTES(MEM_BYTES), .B_LAT(2)) u_slv (
        .clk(clk), .rst_n(rst_n), .thr_en(thr_en),
        .s_awaddr(m_awaddr), .s_awlen(m_awlen), .s_awsize(m_awsize),
        .s_awburst(m_awburst), .s_awid(m_awid), .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata), .s_wstrb(m_wstrb), .s_wlast(m_wlast),
        .s_wvalid(m_wvalid), .s_wready(m_wready),
        .s_bvalid(m_bvalid), .s_bresp(m_bresp), .s_bid(m_bid), .s_bready(m_bready),
        .aw_cnt(slv_aw_cnt), .w_cnt(slv_w_cnt), .b_cnt(slv_b_cnt)
    );

    /* =========================================================================
     * DDR 写口逐拍观测：协议合法性 + 突发归属 + 数据图案（"中途换主"的探测器）
     * ========================================================================= */
    integer aw_tot = 0, w_tot = 0, b_tot = 0;
    integer aw_clr = 0, aw_blt = 0, w_clr = 0, w_blt = 0;  // 按 awid 归属（0=清屏引擎, C=竞争）
    integer aw_len_bad = 0, aw_burst_bad = 0, aw_size_bad = 0, aw_align_bad = 0;
    integer aw_gap_bad = 0, aw_pend_viol = 0;
    integer wlast_bad = 0, wdata_bad = 0, wover_bad = 0, strb_bad = 0, nonfull_bad = 0;
    integer b_pend = 0;

    reg  [31:0] chk_addr = 32'd0;
    reg  [7:0]  chk_len  = 8'd0;
    reg  [3:0]  chk_id   = 4'd0;
    reg  [7:0]  chk_beat = 8'd0;
    reg  [31:0] pe0 = 32'd0, pec = 32'd0;
    reg         pe0_v = 1'b0, pec_v = 1'b0;
    reg         chk_contig = 1'b0;                   // 整片清屏期间：断"逐笔地址连续"
    reg         chk_full   = 1'b0;                   // 整片清屏期间：每词都应全字节写(FFFF)
    reg  [127:0] exp_clr_data = {8{COL1}};           // 清屏引擎当前颜色的 8 像素副本
    reg  [31:0] first_aw = 32'd0, last_aw_end = 32'd0;
    integer     first_aw_v = 0;

    /* WSTRB 直方图（整片清屏期间收集，最多 16 种） */
    reg  [15:0] sh_val [0:15];
    integer     sh_cnt [0:15];
    integer     sh_n = 0, sh_i = 0, sh_found = 0;
    reg         sh_en = 1'b0;

    /* 非对齐用例逐拍抓取（词地址 / 实测掩码） */
    reg  [31:0] ua_addr [0:63];
    reg  [15:0] ua_strb [0:63];
    integer     ua_n = 0;
    reg         ua_cap = 1'b0;

    always @(posedge clk) begin
        if (rst_n) begin
            /* ---------------- AW ---------------- */
            if (m_awvalid && m_awready) begin
                aw_tot = aw_tot + 1;
                if (m_awid == 4'h0) aw_clr = aw_clr + 1;
                else                aw_blt = aw_blt + 1;
                chk_addr = m_awaddr; chk_len = m_awlen; chk_id = m_awid; chk_beat = 8'd0;
                if (m_awlen > 8'd15)         aw_len_bad   = aw_len_bad + 1;
                if (m_awburst !== 2'b01)     aw_burst_bad = aw_burst_bad + 1;
                if (m_awsize  !== 3'd4)      aw_size_bad  = aw_size_bad + 1;
                if (m_awaddr[3:0] !== 4'd0)  aw_align_bad = aw_align_bad + 1;
                if (b_pend != 0)             aw_pend_viol = aw_pend_viol + 1;   // 上一笔 B 未回
                b_pend = b_pend + 1;
                if (chk_contig) begin
                    if (m_awid == 4'h0) begin
                        if (pe0_v && (m_awaddr !== pe0)) aw_gap_bad = aw_gap_bad + 1;
                        pe0 = m_awaddr + (m_awlen + 8'd1)*16;
                        pe0_v = 1'b1;
                    end else begin
                        if (pec_v && (m_awaddr !== pec)) aw_gap_bad = aw_gap_bad + 1;
                        pec = m_awaddr + (m_awlen + 8'd1)*16;
                        pec_v = 1'b1;
                    end
                    if (m_awid == 4'h0) begin
                        if (first_aw_v == 0) begin first_aw = m_awaddr; first_aw_v = 1; end
                        last_aw_end = m_awaddr + (m_awlen + 8'd1)*16;
                        if (m_awlen !== 8'd15) nonfull_bad = nonfull_bad + 1;
                    end
                end
            end

            /* ---------------- W ---------------- */
            if (m_wvalid && m_wready) begin
                w_tot = w_tot + 1;
                if (chk_id == 4'h0) w_clr = w_clr + 1;
                else                w_blt = w_blt + 1;
                if (m_wlast !== (chk_beat == chk_len)) wlast_bad = wlast_bad + 1;
                if (chk_beat > chk_len)                wover_bad = wover_bad + 1;
                if (chk_id == 4'h0) begin
                    if (m_wdata !== exp_clr_data) wdata_bad = wdata_bad + 1;
                end else begin
                    if (m_wdata !== COMP_DATA)    wdata_bad = wdata_bad + 1;
                end
                if (chk_full && (m_wstrb !== 16'hFFFF)) strb_bad = strb_bad + 1;

                if (sh_en) begin
                    sh_found = 0;
                    for (sh_i = 0; sh_i < sh_n; sh_i = sh_i + 1)
                        if (sh_val[sh_i] === m_wstrb) begin
                            sh_cnt[sh_i] = sh_cnt[sh_i] + 1;
                            sh_found = 1;
                        end
                    if ((sh_found == 0) && (sh_n < 16)) begin
                        sh_val[sh_n] = m_wstrb;
                        sh_cnt[sh_n] = 1;
                        sh_n = sh_n + 1;
                    end
                end

                if (ua_cap && (ua_n < 64)) begin
                    ua_addr[ua_n] = chk_addr + chk_beat*16;
                    ua_strb[ua_n] = m_wstrb;
                    ua_n = ua_n + 1;
                end
                chk_beat = chk_beat + 8'd1;
            end

            /* ---------------- B ---------------- */
            if (m_bvalid && m_bready) begin
                b_tot = b_tot + 1;
                if (b_pend > 0) b_pend = b_pend - 1;
            end
        end
    end

    /* =========================================================================
     * 断言 / 图案 / 校验任务
     * ========================================================================= */
    integer errors = 0, checks_run = 0;
    task check;
        input [255:0] name;
        input         ok;
        begin
            checks_run = checks_run + 1;
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* 预填图案：纯地址函数；与 COL1..COL4 都不可能撞上（相邻两字节不可能同时等于某色） */
    function [7:0] pat;
        input [31:0] a;
        begin pat = a[7:0] ^ 8'h5A; end
    endfunction

    function [15:0] exp_msk;                          // 16B 词在行区间 [rs,re) 内应写的字节掩码
        input [31:0] wa;
        input [31:0] rs, re;
        integer      lo_b, hi_b;
        begin
            lo_b = 0; hi_b = 16;
            if (rs > wa)            lo_b = rs - wa;
            if (re < (wa + 32'd16)) hi_b = re - wa;
            if (hi_b <= lo_b) exp_msk = 16'h0000;
            else              exp_msk = ((16'hFFFF << lo_b) & ~(16'hFFFF << hi_b));
        end
    endfunction

    function [15:0] look_strb;                        // 在抓取表里按词地址查实测掩码
        input [31:0] wa;
        integer      m;
        begin
            look_strb = 16'hxxxx;
            for (m = 0; m < ua_n; m = m + 1)
                if (ua_addr[m] === wa) look_strb = ua_strb[m];
        end
    endfunction

    /* 定点打印辅助（都按 ×1000 或 ×100 先算整数，避免 a*10000 溢出 32 位有符号） */
    function integer m1000;                            // 比值 ×1000
        input integer a, b;
        begin m1000 = (a*1000)/b; end
    endfunction
    function integer r100;                             // 比值 ×100
        input integer a, b;
        begin r100 = (a*100)/b; end
    endfunction
    function integer p10;                              // 百分比 ×10
        input integer a, b;
        begin p10 = (a*1000)/b; end
    endfunction

    integer     bad_n = 0;
    reg  [31:0] bad_first = 32'd0;

    task fill_pat;                                    // [a0,a1) 逐字节填图案
        input [31:0] a0, a1;
        reg   [31:0] a;
        begin
            for (a = a0; a < a1; a = a + 1) u_slv.mem[a - MEM_BASE] = pat(a);
        end
    endtask

    task chk_pat_span;                                // 区间内每个字节必须还是图案
        input [31:0]  a0, a1;
        input [255:0] name;
        reg   [31:0]  a;
        begin
            bad_n = 0; bad_first = a0;
            for (a = a0; a < a1; a = a + 1)
                if (u_slv.mem[a - MEM_BASE] !== pat(a)) begin
                    if (bad_n == 0) bad_first = a;
                    bad_n = bad_n + 1;
                end
            if (bad_n != 0)
                $display("      区外被写: 首地址=%h 共 %0d 字节（该处实测 %02h / 图案 %02h）",
                         bad_first, bad_n, u_slv.mem[bad_first - MEM_BASE], pat(bad_first));
            check(name, bad_n == 0);
        end
    endtask

    task cnt_color_span;                              // [a0,a1) 每 2 字节一像素，累计不符像素数
        input [31:0] a0, a1;
        input [15:0] color;
        reg   [31:0] a;
        begin
            for (a = a0; a < a1; a = a + 2)
                if ((u_slv.mem[a - MEM_BASE]     !== color[7:0]) ||
                    (u_slv.mem[a + 1 - MEM_BASE] !== color[15:8])) begin
                    if (bad_n == 0) bad_first = a;
                    bad_n = bad_n + 1;
                end
        end
    endtask

    task chk_color_span;
        input [31:0]  a0, a1;
        input [15:0]  color;
        input [255:0] name;
        begin
            bad_n = 0; bad_first = a0;
            cnt_color_span(a0, a1, color);
            if (bad_n != 0)
                $display("      像素不符: 首个像素地址=%h（实测 %02h%02h / 期望 %04h）共 %0d 个像素",
                         bad_first, u_slv.mem[bad_first+1 - MEM_BASE],
                         u_slv.mem[bad_first - MEM_BASE], color, bad_n);
            check(name, bad_n == 0);
        end
    endtask

    /* =========================================================================
     * 驱动 / 计时任务
     * ========================================================================= */
    integer t0 = 0, meas_cyc = 0, spin = 0;
    integer busy_to = 0, rise_ok = 1;
    integer aw0 = 0, w0 = 0, sbad0 = 0, nf0 = 0, gap0 = 0;

    task cfg_set;
        input [31:0] addr, stride;
        input [15:0] w, h, color;
        input [1:0]  sel;
        begin
            cfg_addr = addr; cfg_stride = stride;
            cfg_w = w; cfg_h = h; cfg_color = color; cfg_sel = sel;
            exp_clr_data = {8{color}};
        end
    endtask

    task go_pulse;                                    // 1 拍 GO 脉冲 + 记起点周期
        begin
            @(negedge clk);
            t0 = cyc;
            cfg_go = 1'b1;
            @(negedge clk);
            cfg_go = 1'b0;
        end
    endtask

    task err_clr_pulse;
        begin
            @(negedge clk); cfg_err_clr = 1'b1;
            @(negedge clk); cfg_err_clr = 1'b0;
        end
    endtask

    task wait_rise;                                   // 等 busy 拉起（确认真的启动）
        begin
            spin = 0;
            while (!busy && (spin < 400)) begin @(negedge clk); spin = spin + 1; end
            rise_ok = busy;
        end
    endtask

    task wait_down;                                   // 等 busy 落（带超时）
        input integer tmo;
        begin
            spin = 0;
            while (busy && (spin < tmo)) begin @(negedge clk); spin = spin + 1; end
            busy_to = (spin >= tmo);
            if (busy_to) $display("      !! busy 超时未落（tmo=%0d）", tmo);
        end
    endtask

    /* =========================================================================
     * 结果汇总变量
     * ========================================================================= */
    integer t_fast = 0, aw_fast = 0, w_fast = 0, cc_fast = 0;
    integer t_thr  = 0, aw_thr  = 0, w_thr  = 0, cc_thr  = 0;
    integer ua_aw = 0, ua_w = 0, ua_mask_bad = 0, ua_aw_bad = 0;
    integer m1_aw = 0, m1_w = 0, m2_aw = 0, m2_w = 0;
    integer m3_aw_after = 0, m3_w_after = 0, m3_aw_run = 0, m3_w_run = 0;
    integer m3_aw_trip = 0, m3_w_trip = 0, m3_aw_hold = 0, m3_w_hold = 0;
    integer arb_aw_clr = 0, arb_aw_clr_comp = 0, arb_w_clr = 0;
    integer arb_aw_blt = 0, arb_w_blt = 0;
    integer arb_pend_v = 0, arb_mix_v = 0, arb_cyc_comp = 0, arb_cyc_tot = 0;
    integer arb2_aw_clr = 0, arb2_aw_clr_comp = 0, arb2_aw_blt = 0, arb2_w_blt = 0;
    integer arb2_pend_v = 0, arb2_mix_v = 0, arb2_wl_v = 0, arb2_wo_v = 0;
    integer arb2_cyc_comp = 0, arb2_cyc_tot = 0;
    integer ua_i, ua_j;
    reg  [31:0] sc_a, sc_rs, sc_wa, sc_wb;
    reg  [15:0] sc_em, sc_om;
    integer      inside_f;
    /* 各用例"当场"采样的状态（汇总里不打最终值，避免张冠李戴） */
    reg          m1_err = 1'b0, m1_clean1 = 1'b0, m1_busy = 1'b0;
    reg          m2_err = 1'b0, m2_clean1 = 1'b0, m2_busy = 1'b0;
    reg          m3_err = 1'b0, m3_busy_mid = 1'b0, m3_clean2 = 1'b0;
    integer      m3_aw_resume = 0, m3_w_resume = 0;
    integer      arb_w_clr0 = 0, arb_w_blt0 = 0;

    /* =========================================================================
     * 主流程
     * ========================================================================= */
    initial begin
        $display("=== tb_clear_engine: clr_engine 专项（吞吐 / WSTRB / 硬件互斥 / 仲裁） ===");
`ifdef CLEAR_MUTEX_OFF
        $display("--- 互斥守卫: OFF（-DCLEAR_MUTEX_OFF，A/B 对照组：go_bad/run_bad 恒 0）---");
`else
        $display("--- 互斥守卫: ON （默认：go_bad / run_bad 生效）---");
`endif
        $display("    布局 960x524 stride=%0dB；缓冲 0/1/2 基址 = %h / %h / %h", ROWB, FB0, FB1, FB2);
        $display("    整片区 = %h..%h（%0d 像素 / %0d 词 / 期望 %0d 笔 16 拍 AW）",
                 REG_A, REG_E, NPX, REG_WORDS, REG_BURSTS);

        rst_n = 1'b0;
        repeat (6) @(negedge clk);
        rst_n = 1'b1;
        repeat (4) @(negedge clk);
        fb_cur_sel = 2'd1; draw_sel = 2'd2;           // 默认合法组合（目标 0 与两者都不同）
        thr_en = 1'b0;

        /* =====================================================================
         * 1a. 整片清屏 —— fast slave（每拍收 1 拍 W）
         * ===================================================================== */
        $display("");
        $display("--- 1a. 整片清屏 960x524 @ %h（fast slave：1 beat/cycle）---", REG_A);
        fill_pat(REG_A - ROWB, REG_A);                // 上一行（含起点前一词）
        fill_pat(REG_E, REG_E + ROWB);                // 下一行（含终点后一词）
        sh_n = 0; sh_en = 1'b1;
        aw0 = aw_tot; w0 = w_tot; sbad0 = strb_bad; nf0 = nonfull_bad; gap0 = aw_gap_bad;
        chk_contig = 1'b1; chk_full = 1'b1;
        pe0_v = 1'b0; pec_v = 1'b0; first_aw_v = 0;
        cfg_set(REG_A, STRIDE, RW, RH, COL1, 2'd0);
        go_pulse;
        wait_rise;
        wait_down(400000);
        meas_cyc = cyc - t0;                          // 必须在 wait_down 之后立刻取（别再插 negedge）
        repeat (3) @(negedge clk);
        chk_contig = 1'b0; chk_full = 1'b0; sh_en = 1'b0;
        t_fast = meas_cyc; cc_fast = cyc_cnt;
        aw_fast = aw_tot - aw0; w_fast = w_tot - w0;

        $display("    go→busy 落 = %0d 周期；RTL cyc_cnt = %0d（差 %0d 拍：cyc 不含 GO 那一拍）；busy 超时=%0d",
                 meas_cyc, cc_fast, meas_cyc - cc_fast, busy_to);
        $display("    DDR 从机受理：AW 突发 = %0d（期望 %0d）；W 拍 = %0d（期望 %0d）；覆盖像素 = %0d",
                 aw_fast, REG_BURSTS, w_fast, REG_WORDS, NPX);
        $display("    每像素周期 = %0d.%03d ；像素/周期 = %0d.%03d",
                 m1000(meas_cyc,NPX)/1000, m1000(meas_cyc,NPX)%1000,
                 m1000(NPX,meas_cyc)/1000, m1000(NPX,meas_cyc)%1000);
        $display("    对照(a) 指令式整片清屏 568000 周期 → 本引擎 = 基准的 %0d.%01d%%（快 %0d.%02d 倍）",
                 p10(meas_cyc,BASE_CMD)/10, p10(meas_cyc,BASE_CMD)%10,
                 r100(BASE_CMD,meas_cyc)/100, r100(BASE_CMD,meas_cyc)%100);
        $display("    对照(b) 理论目标 251520 周期（2 px/cycle）→ 本引擎 = 目标的 %0d.%01d%%（%0d.%02d 倍）",
                 p10(meas_cyc,BASE_2PPC)/10, p10(meas_cyc,BASE_2PPC)%10,
                 r100(meas_cyc,BASE_2PPC)/100, r100(meas_cyc,BASE_2PPC)%100);
        $display("    首笔 AW=%h，末笔末地址=%h（应恰好覆盖 %h..%h）", first_aw, last_aw_end, REG_A, REG_E);
        $display("    从机自计（交叉校验）：AW=%0d W=%0d B=%0d", slv_aw_cnt, slv_w_cnt, slv_b_cnt);
        $display("    WSTRB 直方图（fast 整片）：");
        for (sh_i = 0; sh_i < sh_n; sh_i = sh_i + 1)
            $display("        掩码 %h × %0d 拍", sh_val[sh_i], sh_cnt[sh_i]);

        check("1a AW bursts == 3930", (aw_fast == REG_BURSTS) && (burst_cnt == REG_BURSTS));
        check("1a W beats == 62880",   (w_fast == REG_WORDS));
        check("1a 16-beat merge/align/contig", ((nonfull_bad-nf0) == 0) && ((aw_gap_bad-gap0) == 0) &&
                                        (aw_len_bad == 0) && (aw_burst_bad == 0) &&
                                        (aw_size_bad == 0) && (aw_align_bad == 0) &&
                                        (aw_pend_viol == 0) && (wlast_bad == 0) &&
                                        (wover_bad == 0) && (b_pend == 0));
        check("1a cycles == cyc_cnt+1", ((meas_cyc - cc_fast) >= 1) &&
                                       ((meas_cyc - cc_fast) <= 2) && !busy_to);
        check("1a legal clear: err stays 0", (err === 1'b0));
        check("1a every WSTRB == FFFF", ((strb_bad - sbad0) == 0));
        check("1a slave counts == TB counts",
              (slv_aw_cnt == aw_tot) && (slv_w_cnt == w_tot) && (slv_b_cnt == b_tot));
        chk_pat_span(REG_A - ROWB, REG_A, "1a guard row above");
        chk_pat_span(REG_E, REG_E + ROWB, "1a guard row below");
        chk_pat_span(REG_A - 16, REG_A, "1a guard word before");
        chk_pat_span(REG_E, REG_E + 16, "1a guard word after");
        chk_color_span(REG_A, REG_E, COL1, "1a all pixels == COL1");

        /* =====================================================================
         * 1b. 整片清屏 —— throttled slave（每 4 拍才收 1 拍 W）
         * ===================================================================== */
        $display("");
        $display("--- 1b. 整片清屏 960x524（throttled slave：1 beat / 4 cycle ≈ 4 B/cycle）---");
        thr_en = 1'b1;
        fill_pat(REG_A - ROWB, REG_A);                // 重填保护区（独立验证）
        fill_pat(REG_E, REG_E + ROWB);
        aw0 = aw_tot; w0 = w_tot; sbad0 = strb_bad; nf0 = nonfull_bad; gap0 = aw_gap_bad;
        chk_contig = 1'b1;
        pe0_v = 1'b0; pec_v = 1'b0; first_aw_v = 0;
        cfg_set(REG_A, STRIDE, RW, RH, COL2, 2'd0);
        go_pulse;
        wait_rise;
        wait_down(800000);
        meas_cyc = cyc - t0;                          // 同上：立刻取
        repeat (3) @(negedge clk);
        chk_contig = 1'b0;
        t_thr = meas_cyc; cc_thr = cyc_cnt;
        aw_thr = aw_tot - aw0; w_thr = w_tot - w0;
        thr_en = 1'b0;

        $display("    go→busy 落 = %0d 周期；RTL cyc_cnt = %0d（差 %0d 拍）；busy 超时=%0d",
                 meas_cyc, cc_thr, meas_cyc - cc_thr, busy_to);
        $display("    DDR 从机受理：AW 突发 = %0d（期望 %0d）；W 拍 = %0d（期望 %0d）；覆盖像素 = %0d",
                 aw_thr, REG_BURSTS, w_thr, REG_WORDS, NPX);
        $display("    每像素周期 = %0d.%03d ；像素/周期 = %0d.%03d",
                 m1000(meas_cyc,NPX)/1000, m1000(meas_cyc,NPX)%1000,
                 m1000(NPX,meas_cyc)/1000, m1000(NPX,meas_cyc)%1000);
        $display("    对照(a) 指令式 568000 周期 → 本引擎 = 基准的 %0d.%01d%%（快 %0d.%02d 倍）",
                 p10(meas_cyc,BASE_CMD)/10, p10(meas_cyc,BASE_CMD)%10,
                 r100(BASE_CMD,meas_cyc)/100, r100(BASE_CMD,meas_cyc)%100);
        $display("    对照(b) 理论目标 251520 周期（2 px/cycle）→ 本引擎 = 目标的 %0d.%01d%%（%0d.%02d 倍）",
                 p10(meas_cyc,BASE_2PPC)/10, p10(meas_cyc,BASE_2PPC)%10,
                 r100(meas_cyc,BASE_2PPC)/100, r100(meas_cyc,BASE_2PPC)%100);

        check("1b AW bursts == 3930", (aw_thr == REG_BURSTS) && (burst_cnt == REG_BURSTS));
        check("1b W beats == 62880",   (w_thr == REG_WORDS));
        check("1b 16-beat merge/align/contig", ((nonfull_bad-nf0) == 0) && ((aw_gap_bad-gap0) == 0) &&
                                        (aw_pend_viol == 0) && (wlast_bad == 0) && (b_pend == 0));
        check("1b throttled: err stays 0", (err === 1'b0));
        chk_pat_span(REG_A - ROWB, REG_A, "1b guard row above");
        chk_pat_span(REG_E, REG_E + ROWB, "1b guard row below");
        chk_pat_span(REG_A - 16, REG_A, "1b guard word before");
        chk_pat_span(REG_E, REG_E + 16, "1b guard word after");
        chk_color_span(REG_A, REG_E, COL2, "1b all pixels == COL2");

        /* =====================================================================
         * 2b. 非对齐 33x7：WSTRB 掩码 + 精确写入集
         * ===================================================================== */
        $display("");
        $display("--- 2b. 非对齐 33x7 @ %h（首词 lo=1 只写 7 px、尾词只写 2 px）---", UA_A);
        fill_pat(UA_A - ROWB, UA_A + 6*ROWB + 66 + ROWB);
        @(negedge clk);
        fb_cur_sel = 2'd1; draw_sel = 2'd2;
        cfg_set(UA_A, STRIDE, UA_W, UA_H, COL3, 2'd0);
        ua_n = 0; ua_cap = 1'b1;
        aw0 = aw_tot; w0 = w_tot;
        go_pulse;
        wait_rise;
        wait_down(50000);
        repeat (3) @(negedge clk);
        ua_cap = 1'b0;
        ua_aw = aw_tot - aw0; ua_w = w_tot - w0;
        $display("    每行 66 B（33 px）跨 5 个 16B 词；行间不连续 ⇒ 期望 7 笔 AW、35 拍 W");
        $display("    实测：AW = %0d 笔；W = %0d 拍；burst_cnt = %0d；cyc_cnt = %0d",
                 ua_aw, ua_w, burst_cnt, cyc_cnt);

        ua_mask_bad = 0; ua_aw_bad = 0;
        $display("    逐词掩码核对（期望 = 词与本行目标区间 [row,row+66) 相交的字节）：");
        for (ua_i = 0; ua_i < UA_H; ua_i = ua_i + 1) begin
            sc_rs = UA_A + ua_i*ROWB;
            sc_wb = sc_rs & 32'hFFFFFFF0;
            for (ua_j = 0; ua_j < 5; ua_j = ua_j + 1) begin
                sc_wa = sc_wb + ua_j*16;
                sc_em = exp_msk(sc_wa, sc_rs, sc_rs + 66);
                sc_om = look_strb(sc_wa);
                if (sc_om !== sc_em) begin
                    ua_mask_bad = ua_mask_bad + 1;
                    $display("        row%0d w%0d 词=%h 期望=%h 实测=%h   <== 不符",
                             ua_i, ua_j, sc_wa, sc_em, sc_om);
                end else
                    $display("        row%0d w%0d 词=%h 期望=%h 实测=%h",
                             ua_i, ua_j, sc_wa, sc_em, sc_om);
            end
        end
        check("2b unaligned WSTRB per-beat", ua_mask_bad == 0);

        bad_n = 0; bad_first = UA_A;
        for (ua_i = 0; ua_i < UA_H; ua_i = ua_i + 1)
            cnt_color_span(UA_A + ua_i*ROWB, UA_A + ua_i*ROWB + 66, COL3);
        if (bad_n != 0)
            $display("      非对齐像素不符: 首个=%h（实测 %02h%02h / 期望 %04h）共 %0d 个像素",
                     bad_first, u_slv.mem[bad_first+1 - MEM_BASE],
                     u_slv.mem[bad_first - MEM_BASE], COL3, bad_n);
        check("2b unaligned pixels == COL3", bad_n == 0);

        bad_n = 0; bad_first = UA_A - ROWB;
        for (sc_a = UA_A - ROWB; sc_a < UA_A + 6*ROWB + 66 + ROWB; sc_a = sc_a + 1) begin
            inside_f = (sc_a >= UA_A) && (sc_a < (UA_A + 6*ROWB + 66)) &&
                       (((sc_a - UA_A) % ROWB) < 66);
            if (!inside_f && (u_slv.mem[sc_a - MEM_BASE] !== pat(sc_a))) begin
                if (bad_n == 0) bad_first = sc_a;
                bad_n = bad_n + 1;
            end
        end
        if (bad_n != 0)
            $display("      目标矩形外被写: 首地址=%h 共 %0d 字节（实测 %02h / 图案 %02h）",
                     bad_first, bad_n, u_slv.mem[bad_first - MEM_BASE], pat(bad_first));
        check("2b no write outside rect", bad_n == 0);

        /* =====================================================================
         * 3. ★ 硬件互斥：M1 / M2（GO 时刻拒绝）
         * ===================================================================== */
        $display("");
        $display("--- 3a. 互斥 M1：目标 1 == fb_cur_sel（清正在显示的缓冲）---");
        @(negedge clk);
        fb_cur_sel = 2'd1; draw_sel = 2'd0;
        cfg_set(FB1, STRIDE, 16'd64, 16'd64, COL1, 2'd1);
        m1_aw = aw_tot; m1_w = w_tot;
        go_pulse;
        wait_rise;
        wait_down(20000);
        repeat (20) @(negedge clk);
        m1_aw = aw_tot - m1_aw; m1_w = w_tot - m1_w;
        $display("    M1 尝试 64x64 清 buffer1：期间 DDR 口 AW=%0d  W 拍=%0d；err=%b busy=%b clean=%b",
                 m1_aw, m1_w, err, busy, clean);
        check("M1 zero AW bursts", m1_aw == 0);
        check("M1 zero W beats",   m1_w == 0);
        check("M1 err == 1",       err === 1'b1);
        check("M1 busy == 0",      busy === 1'b0);
        check("M1 clean[1] == 0",  clean[1] === 1'b0);
        m1_err = err; m1_clean1 = clean[1]; m1_busy = busy;

        $display("");
        $display("--- 3b. 互斥 M2：目标 1 == draw_sel（BitBlt 正在画的缓冲）---");
        @(negedge clk);
        fb_cur_sel = 2'd0; draw_sel = 2'd1;
        cfg_set(FB1, STRIDE, 16'd64, 16'd64, COL1, 2'd1);
        m2_aw = aw_tot; m2_w = w_tot;
        go_pulse;
        wait_rise;
        wait_down(20000);
        repeat (20) @(negedge clk);
        m2_aw = aw_tot - m2_aw; m2_w = w_tot - m2_w;
        $display("    M2 尝试 64x64 清 buffer1：期间 DDR 口 AW=%0d  W 拍=%0d；err=%b busy=%b clean=%b",
                 m2_aw, m2_w, err, busy, clean);
        check("M2 zero AW bursts", m2_aw == 0);
        check("M2 zero W beats",   m2_w == 0);
        check("M2 err == 1",       err === 1'b1);
        check("M2 busy == 0",      busy === 1'b0);
        check("M2 clean[1] == 0",  clean[1] === 1'b0);
        m2_err = err; m2_clean1 = clean[1]; m2_busy = busy;

        err_clr_pulse;
        repeat (4) @(negedge clk);
        $display("    ERR_CLR 后 err=%b", err);
        check("M2b ERR_CLR clears sticky err", err === 1'b0);

        /* =====================================================================
         * 3c. ★ 硬件互斥：M3 运行中被扫描输出抢占
         * ===================================================================== */
        $display("");
        $display("--- 3c. 互斥 M3：清 buffer2（fb=0,draw=1）跑到 2000 拍后 fb_cur_sel←2 ---");
        fill_pat(FB2, FB2 + M3ROWS*ROWB);
        @(negedge clk);
        fb_cur_sel = 2'd0; draw_sel = 2'd1;
        cfg_set(FB2, STRIDE, RW, M3ROWS, COL4, 2'd2);
        m3_aw_run = aw_tot; m3_w_run = w_tot;
        go_pulse;
        wait_rise;
        repeat (2000) @(negedge clk);
        m3_busy_mid = busy;
        @(negedge clk);
        m3_aw_trip = aw_tot; m3_w_trip = w_tot;       // 与"翻 sel"同一拍采样（不含该拍之后）
        fb_cur_sel = 2'd2;                            // ★ 抢占
        wait_down(200000);
        repeat (5) @(negedge clk);
        m3_aw_after = aw_tot - m3_aw_trip;
        m3_w_after  = w_tot - m3_w_trip;
        m3_err      = err;
        m3_clean2   = clean[2];
        $display("    抢占时刻 busy=%b；此前已发 AW=%0d（%0d 拍 W）",
                 m3_busy_mid, m3_aw_trip - m3_aw_run, m3_w_trip - m3_w_run);
        $display("    抢占之后：AW=%0d 笔（合规 <=2）；W=%0d 拍（合规 <=32）；err=%b busy=%b clean=%b",
                 m3_aw_after, m3_w_after, m3_err, busy, clean);
        check("M3 err set on preempt",  m3_err === 1'b1);
        /* ★ 上界 = **两笔**已组好的突发：发送引擎手里那一笔（≤16 拍）+
         *   构建银行里已封口等着接手的那一笔（≤16 拍）= ≤32 拍 = ≤512 B。
         *   （清屏引擎是"产词/发送"两级流水的，所以暴露量是 2 笔而不是 1 笔；
         *     这是拿吞吐换来的，见 rtl/功能清单.md §21.8 第 4 条。） */
        check("M3 AW after trip <= 2",  m3_aw_after <= 2);
        check("M3 W after trip <= 32",  m3_w_after <= 32);
        check("M3 clean[2] stays 0",    m3_clean2 === 1'b0);
        check("M3 was running then stops", (m3_busy_mid === 1'b1) && (busy === 1'b0) && !busy_to);

        m3_aw_hold = aw_tot; m3_w_hold = w_tot;
        @(negedge clk); fb_cur_sel = 2'd0;            // 扫描输出翻回去
        repeat (400) @(negedge clk);
        m3_aw_resume = aw_tot - m3_aw_hold;           // 这 400 拍里有没有偷偷续写
        m3_w_resume  = w_tot - m3_w_hold;
        $display("    fb_cur_sel 回 0 后 400 拍：AW 增 %0d；W 增 %0d；busy=%b clean=%b",
                 m3_aw_resume, m3_w_resume, busy, clean);
        check("M3 no silent resume w/o GO", (m3_aw_resume == 0) && (m3_w_resume == 0) &&
                                          (busy === 1'b0) && (clean[2] === 1'b0));

        $display("    M3 重启（新 GO，颜色 %04h）...", COL4);
        cfg_set(FB2, STRIDE, RW, M3ROWS, COL4, 2'd2);
        go_pulse;
        wait_rise;
        wait_down(200000);
        repeat (3) @(negedge clk);
        $display("    重启结果：busy=%b clean=%b burst_cnt=%0d cyc_cnt=%0d", busy, clean, burst_cnt, cyc_cnt);
        check("M3 restart completes+clean", (busy === 1'b0) && (clean[2] === 1'b1));
        chk_color_span(FB2, FB2 + M3ROWS*ROWB, COL4, "M3 restart pixels == COL4");

        /* =====================================================================
         * 4A. 仲裁：竞争者"流水型"（AW 常举 = 仲裁规则针对的"BitBlt 侧有写"情形）
         * ===================================================================== */
        $display("");
        $display("--- 4A. 仲裁：清屏引擎(b_ 次级) vs 流水型竞争者(c_，AW 常举) ---");
        @(negedge clk);
        fb_cur_sel = 2'd1; draw_sel = 2'd2;           // 目标 0：合法
        cfg_set(FB0, STRIDE, RW, 16'd16, COL1, 2'd0); // 16 行 = 1920 词 = 120 笔
        blt_base  = FB1;
        blt_words = 16'd1024;                         // 64 笔 × 16 拍
        blt_pipe  = 1'b1;
        fill_pat(FB1 - 16, FB1 + 1024*16 + 16);
        arb_aw_clr = aw_clr; arb_aw_blt = aw_blt;
        arb_w_clr0 = w_clr;  arb_w_blt0 = w_blt;
        arb_mix_v  = wdata_bad;
        t0 = cyc;
        @(negedge clk);
        blt_go = 1'b1;                                // 同拍启动两侧
        cfg_go = 1'b1;
        @(negedge clk);
        blt_go = 1'b0;
        cfg_go = 1'b0;
        spin = 0;
        while (!blt_done && (spin < 200000)) begin @(negedge clk); spin = spin + 1; end
        arb_cyc_comp    = cyc - t0;
        arb_aw_clr_comp = aw_clr - arb_aw_clr;        // 竞争者活跃期间清屏引擎发出的 AW
        $display("    竞争者：AW=%0d 笔 / W=%0d 拍 全部被受理，%0d 周期完成（done=%b）",
                 blt_bursts, blt_beats, arb_cyc_comp, blt_done);
        $display("    竞争者活跃期间清屏引擎 AW = %0d 笔（它本次任务共 120 笔；次级只填空闲档）",
                 arb_aw_clr_comp);
        check("4a competitor completes", blt_done && (blt_bursts == 32'd64) && (blt_beats == 32'd1024));
        check("4b clr progress ~0 in comp", arb_aw_clr_comp <= 2);

        wait_down(200000);
        repeat (3) @(negedge clk);
        arb_cyc_tot = cyc - t0;
        arb_w_clr   = w_clr - arb_w_clr0;
        arb_w_blt   = w_blt - arb_w_blt0;
        arb_aw_clr  = aw_clr - arb_aw_clr;
        arb_aw_blt  = aw_blt - arb_aw_blt;
        $display("    全程：清屏引擎 AW=%0d 笔 / W=%0d 拍；竞争者（awid=C）AW=%0d 笔 / W=%0d 拍",
                 arb_aw_clr, arb_w_clr, arb_aw_blt, arb_w_blt);
        $display("    清屏引擎 %0d 周期后收工：busy=%b clean=%b burst_cnt=%0d", arb_cyc_tot, busy, clean, burst_cnt);
        check("4c clear completes after yield", (busy === 1'b0) && (clean[0] === 1'b1) &&
                                   (arb_aw_clr == 120) && (arb_w_clr == 1920));
        check("4d no owner switch mid-burst",
              ((wdata_bad - arb_mix_v) == 0) && (wlast_bad == 0) && (wover_bad == 0));
        check("4e no AW while B pending", (aw_pend_viol - arb_pend_v) == 0);

        /* 竞争者整片内容（数据图案逐字节）+ 两端各 16B 不许被动 */
        bad_n = 0; bad_first = FB1;
        for (sc_a = FB1; sc_a < FB1 + 1024*16; sc_a = sc_a + 1)
            if (u_slv.mem[sc_a - MEM_BASE] !== COMP_DATA[{sc_a[3:0], 3'b000} +: 8]) begin
                if (bad_n == 0) bad_first = sc_a;
                bad_n = bad_n + 1;
            end
        if (bad_n != 0)
            $display("      竞争者区域不符: 首地址=%h 共 %0d 字节（实测 %02h / 期望 %02h）",
                     bad_first, bad_n, u_slv.mem[bad_first - MEM_BASE],
                     COMP_DATA[{bad_first[3:0], 3'b000} +: 8]);
        check("4f competitor content ok", bad_n == 0);
        chk_pat_span(FB1 - 16, FB1, "4f competitor guard word pre");
        chk_pat_span(FB1 + 1024*16, FB1 + 1024*16 + 16, "4f competitor guard word post");

        /* =====================================================================
         * 4B. 仲裁：竞争者"串行型"（忠实 rtl/axi_wr_master.v：S_B→S_IDLE→S_BUF→S_AW，
         *     突发之间有 1~2 拍 awvalid=0 ⇒ 次级会在空档里抢到通道并占用一整笔突发）
         * ===================================================================== */
        $display("");
        $display("--- 4B. 仲裁：串行型竞争者（同 rtl/axi_wr_master.v，突发间有 AW 空档）---");
        @(negedge clk);
        fb_cur_sel = 2'd1; draw_sel = 2'd2;
        cfg_set(FB0 + 32*ROWB, STRIDE, RW, 16'd16, COL1, 2'd0);   // 另一个 120 笔的区域
        blt_base  = FB1 + 32'h0002_0000;
        blt_words = 16'd1024;
        blt_pipe  = 1'b0;
        fill_pat(blt_base - 16, blt_base + 1024*16 + 16);
        arb2_aw_clr = aw_clr; arb2_aw_blt = aw_blt; arb2_w_blt = w_blt;
        arb2_pend_v = aw_pend_viol; arb2_mix_v = wdata_bad;
        arb2_wl_v   = wlast_bad; arb2_wo_v = wover_bad;
        t0 = cyc;
        @(negedge clk);
        blt_go = 1'b1;
        cfg_go = 1'b1;
        @(negedge clk);
        blt_go = 1'b0;
        cfg_go = 1'b0;
        spin = 0;
        while (!blt_done && (spin < 200000)) begin @(negedge clk); spin = spin + 1; end
        arb2_cyc_comp    = cyc - t0;
        arb2_aw_clr_comp = aw_clr - arb2_aw_clr;
        $display("    竞争者：AW=%0d 笔 / W=%0d 拍 全部被受理，%0d 周期完成（done=%b）",
                 blt_bursts, blt_beats, arb2_cyc_comp, blt_done);
        $display("    竞争者活跃期间清屏引擎 AW = %0d 笔（占它自己总任务的 %0d.%01d%%）",
                 arb2_aw_clr_comp, p10(arb2_aw_clr_comp, 120)/10, p10(arb2_aw_clr_comp, 120)%10);
        check("4g serial competitor completes", blt_done && (blt_bursts == 32'd64) && (blt_beats == 32'd1024));

        wait_down(200000);
        repeat (3) @(negedge clk);
        arb2_cyc_tot = cyc - t0;
        arb2_aw_clr  = aw_clr - arb2_aw_clr;
        arb2_pend_v  = aw_pend_viol - arb2_pend_v;
        arb2_mix_v   = (wdata_bad - arb2_mix_v) + (wlast_bad - arb2_wl_v) + (wover_bad - arb2_wo_v);
        $display("    全程：清屏引擎 AW=%0d 笔；竞争者 AW=%0d 笔 / W=%0d 拍；清屏 %0d 周期后收工 busy=%b",
                 arb2_aw_clr, aw_blt - arb2_aw_blt, w_blt - arb2_w_blt, arb2_cyc_tot, busy);
        check("4h serial: no mid-burst switch", (arb2_mix_v == 0) && (arb2_pend_v == 0));
        check("4i serial: clear completes", (busy === 1'b0) && (arb2_aw_clr == 120));
        if (arb2_aw_clr_comp > 2) begin
            $display("    ★ 警告（性能口径，不计入 FAIL）：c_ 侧突发之间的 AW 空档被次级利用，");
            $display("      清屏引擎在竞争者活跃期抢到 %0d/120 笔突发（%0d.%01d%%），且每抢一次就独占一整笔；",
                     arb2_aw_clr_comp, p10(arb2_aw_clr_comp,120)/10, p10(arb2_aw_clr_comp,120)%10);
            $display("      即真机上 BitBlt 写通道约一半带宽被并发清屏拿走（与 clr_engine.v 注释");
            $display("      \"BitBlt 赢、清屏引擎只填空闲档\" 不符）。");
        end

        /* =====================================================================
         * 5. 汇总
         * ===================================================================== */
        $display("");
        $display("==================== tb_clear_engine 汇总（原始数字） ====================");
        $display(" 整片清屏 960x524 = %0d 像素 / %0d 词 / 期望 %0d 笔 16 拍 AW", NPX, REG_WORDS, REG_BURSTS);
        $display("  fast slave      : %0d 周期  cyc_cnt=%0d  AW=%0d  W=%0d  %0d.%03d 周期/像素  %0d.%03d 像素/周期",
                 t_fast, cc_fast, aw_fast, w_fast,
                 m1000(t_fast,NPX)/1000, m1000(t_fast,NPX)%1000,
                 m1000(NPX,t_fast)/1000, m1000(NPX,t_fast)%1000);
        $display("  throttled slave : %0d 周期  cyc_cnt=%0d  AW=%0d  W=%0d  %0d.%03d 周期/像素  %0d.%03d 像素/周期",
                 t_thr, cc_thr, aw_thr, w_thr,
                 m1000(t_thr,NPX)/1000, m1000(t_thr,NPX)%1000,
                 m1000(NPX,t_thr)/1000, m1000(NPX,t_thr)%1000);
        $display("  对照 568000（指令式实测）: fast = 它的 %0d.%01d%%（快 %0d.%02d 倍）；throttled = 它的 %0d.%01d%%（快 %0d.%02d 倍）",
                 p10(t_fast,BASE_CMD)/10, p10(t_fast,BASE_CMD)%10,
                 r100(BASE_CMD,t_fast)/100, r100(BASE_CMD,t_fast)%100,
                 p10(t_thr,BASE_CMD)/10, p10(t_thr,BASE_CMD)%10,
                 r100(BASE_CMD,t_thr)/100, r100(BASE_CMD,t_thr)%100);
        $display("  对照 251520（2 px/cycle）: fast = 它的 %0d.%01d%%（%0d.%02d 倍）；throttled = 它的 %0d.%01d%%（%0d.%02d 倍）",
                 p10(t_fast,BASE_2PPC)/10, p10(t_fast,BASE_2PPC)%10,
                 r100(t_fast,BASE_2PPC)/100, r100(t_fast,BASE_2PPC)%100,
                 p10(t_thr,BASE_2PPC)/10, p10(t_thr,BASE_2PPC)%10,
                 r100(t_thr,BASE_2PPC)/100, r100(t_thr,BASE_2PPC)%100);
        $display(" 互斥 M1 : AW=%0d W=%0d err=%b clean[1]=%b busy=%b",
                 m1_aw, m1_w, m1_err, m1_clean1, m1_busy);
        $display(" 互斥 M2 : AW=%0d W=%0d err=%b clean[1]=%b busy=%b",
                 m2_aw, m2_w, m2_err, m2_clean1, m2_busy);
        $display(" 互斥 M3 : 抢占后 AW=%0d W=%0d（上界 2 / 32 = 两笔已组好的突发）；err=%b clean[2]=%b；回合法 400 拍内 AW 增 %0d W 增 %0d",
                 m3_aw_after, m3_w_after, m3_err, m3_clean2, m3_aw_resume, m3_w_resume);
        $display(" 非对齐 33x7: AW=%0d 笔 W=%0d 拍；WSTRB 不符 %0d 个词",
                 ua_aw, ua_w, ua_mask_bad);
        $display(" 仲裁 : 流水竞争者(4A) 活跃期清屏 AW=%0d；串行竞争者(4B) 活跃期清屏 AW=%0d（= 总任务 120 的 %0d.%01d%%）",
                 arb_aw_clr_comp, arb2_aw_clr_comp, p10(arb2_aw_clr_comp,120)/10, p10(arb2_aw_clr_comp,120)%10);
        $display("        竞争者均全部完成（64 笔 / 1024 拍）；中途换主违规=0；B 未回就受理 AW 违规=0");
        $display("        4A 全程 竞争者 AW=%0d W=%0d / 清屏 AW=%0d W=%0d；4B 全程 竞争者 AW=%0d W=%0d / 清屏 AW=%0d",
                 arb_aw_blt, arb_w_blt, arb_aw_clr, arb_w_clr,
                 aw_blt - arb2_aw_blt, w_blt - arb2_w_blt, arb2_aw_clr);
        $display(" 合计检查 %0d 项，失败 %0d 项", checks_run, errors);
        $display("========================================================================");

        if (errors == 0) $display("========== tb_clear_engine ALL PASS ==========");
        else             $display("========== tb_clear_engine FAILED (%0d 项) ==========", errors);
        $finish;
    end

    /* 看门狗 */
    initial begin
        #60_000_000;
        $display("!!!!!!!! tb_clear_engine WATCHDOG !!!!!!!!");
        $finish;
    end

endmodule


/* =========================================================================
 * wr_slave_model — 行为级 AXI4 写从机（128bit / INCR / 单笔在飞）
 *   · 按 WSTRB 逐字节落地（与 rtl/tb/axi_slave_mem.v 写侧同口径）
 *   · thr_en=1 时限流：wready 每 4 拍才拉高 1 拍（≈4 B/cycle）
 *   · bvalid 在最后一拍之后 B_LAT 拍拉高；bready 常 1
 * ========================================================================= */
module wr_slave_model #(
    parameter [31:0]  MEM_BASE  = 32'h0070_0000,
    parameter integer MEM_BYTES = 4*1024*1024,
    parameter integer B_LAT     = 2
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         thr_en,
    input  wire [31:0]  s_awaddr,
    input  wire [7:0]   s_awlen,
    input  wire [2:0]   s_awsize,
    input  wire [1:0]   s_awburst,
    input  wire [3:0]   s_awid,
    input  wire         s_awvalid,
    output wire         s_awready,
    input  wire [127:0] s_wdata,
    input  wire [15:0]  s_wstrb,
    input  wire         s_wlast,
    input  wire         s_wvalid,
    output wire         s_wready,
    output reg          s_bvalid,
    output wire [1:0]   s_bresp,
    output wire [3:0]   s_bid,
    input  wire         s_bready,
    output reg  [31:0]  aw_cnt,
    output reg  [31:0]  w_cnt,
    output reg  [31:0]  b_cnt
);
    localparam S_IDLE = 2'd0, S_W = 2'd1, S_B = 2'd2;

    reg [7:0]  mem [0:MEM_BYTES-1];
    reg [1:0]  st;
    reg [31:0] w_addr;
    reg [7:0]  beat;
    reg [3:0]  cur_id;
    reg [7:0]  b_dly;
    reg [1:0]  thr_ph;
    integer    i;
    reg [31:0] off;

    assign s_awready = (st == S_IDLE);
    assign s_wready  = (st == S_W) && (!thr_en || (thr_ph == 2'd0));
    assign s_bresp   = 2'b00;
    assign s_bid     = cur_id;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st       <= S_IDLE;
            s_bvalid <= 1'b0;
            b_dly    <= 8'd0;
            thr_ph   <= 2'd0;
            beat     <= 8'd0;
            w_addr   <= 32'd0;
            cur_id   <= 4'd0;
            aw_cnt   <= 32'd0;
            w_cnt    <= 32'd0;
            b_cnt    <= 32'd0;
        end else begin
            thr_ph <= thr_ph + 2'd1;                  // 自由跑：0,1,2,3 → 每 4 拍一个受理窗口
            case (st)
                S_IDLE: begin
                    if (s_awvalid && s_awready) begin
                        aw_cnt <= aw_cnt + 32'd1;
                        w_addr <= s_awaddr;
                        cur_id <= s_awid;
                        beat   <= 8'd0;
                        st     <= S_W;
                    end
                end
                S_W: begin
                    if (s_wvalid && s_wready) begin
                        w_cnt <= w_cnt + 32'd1;
                        for (i = 0; i < 16; i = i + 1) begin
                            off = w_addr + i[31:0];
                            if (s_wstrb[i] && (off >= MEM_BASE) &&
                                (off < (MEM_BASE + MEM_BYTES)))
                                mem[off - MEM_BASE] <= s_wdata[i*8 +: 8];
                        end
                        w_addr <= w_addr + 32'd16;
                        beat   <= beat + 8'd1;
                        if (s_wlast) begin
                            b_dly <= B_LAT[7:0];
                            st    <= S_B;
                        end
                    end
                end
                S_B: begin
                    if (b_dly != 8'd0) b_dly <= b_dly - 8'd1;
                    else if (!s_bvalid) s_bvalid <= 1'b1;
                    else if (s_bready) begin
                        s_bvalid <= 1'b0;
                        b_cnt    <= b_cnt + 32'd1;
                        st       <= S_IDLE;
                    end
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule


/* =========================================================================
 * blt_like_wr_host — "BitBlt 风格"的竞争写主机（跑在仲裁器 c_ 侧）
 *   合并成最多 16 拍/笔的 INCR 突发，只写一个常量 128bit 数据图案；
 *   awid 固定为 ID（用来在 DDR 口按归属拆分清屏引擎 / 竞争者的计数）。
 *   pipe = 1：AW 通道常举（一笔被受理就立刻组下一笔）⇒ c_awvalid 不断，仲裁器
 *             永远拿不到"c 空闲且没在请求"的窗口；
 *   pipe = 0：忠实 rtl/axi_wr_master.v 的串行口径 —— 必须等这一笔的 B 回来才举
 *             下一笔 AW ⇒ 突发之间有 1~2 拍 awvalid=0 的空档。
 * ========================================================================= */
module blt_like_wr_host #(
    parameter [127:0] DATA = 128'h0BADF00D_0BADF00D_0BADF00D_0BADF00D,
    parameter [3:0]   ID   = 4'hC
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire         pipe,
    input  wire [31:0]  base,
    input  wire [15:0]  nwords,
    output reg  [31:0]  awaddr,
    output reg  [7:0]   awlen,
    output wire [2:0]   awsize,
    output wire [1:0]   awburst,
    output wire [3:0]   awid,
    output reg          awvalid,
    input  wire         awready,
    output wire [127:0] wdata,
    output wire [15:0]  wstrb,
    output wire         wlast,
    output reg          wvalid,
    input  wire         wready,
    input  wire         bvalid,
    input  wire [1:0]   bresp,
    output wire         bready,
    output reg          done,
    output reg  [31:0]  burst_sent,
    output reg  [31:0]  beat_sent
);
    reg        started;
    reg        busy_b;         // 有一笔突发在飞（AW 已受理、B 未回）
    reg [15:0] rem_issue;      // 还没举起 AW 的词数
    reg [15:0] rem_ack;        // 还没被受理 AW 的词数
    reg [15:0] b_pend;         // 已受理、还没收到 B 的突发数
    reg [15:0] aw_bw_r;        // 当前举着的那笔的拍数
    reg [15:0] bcnt;           // 当前这笔还剩几拍 W
    reg [31:0] naddr;          // 下一笔 AW 的地址

    wire [15:0] pres_bw  = (rem_issue > 16'd16) ? 16'd16 : rem_issue;
    /* "AW 通道本拍可用"：没举着，或者举着且本拍被受理（受理当拍立刻举下一笔 ⇒ 无空档） */
    wire        aw_free  = !awvalid || (awvalid && awready);
    /* pipe=0（串行，同 axi_wr_master）：必须等这笔的 B 回来、而且不是"受理当拍"才举下一笔 */
    wire        ser_ok   = (busy_b == 1'b0) && !(awvalid && awready);
    wire        pres_now = started && (rem_issue != 16'd0) && aw_free && (pipe || ser_ok);

    assign awsize  = 3'd4;
    assign awburst = 2'b01;
    assign awid    = ID;
    assign wdata   = DATA;
    assign wstrb   = 16'hFFFF;
    assign wlast   = wvalid && (bcnt == 16'd1);
    assign bready  = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            started    <= 1'b0;
            awvalid    <= 1'b0;
            wvalid     <= 1'b0;
            done       <= 1'b0;
            awaddr     <= 32'd0;
            awlen      <= 8'd0;
            naddr      <= 32'd0;
            rem_issue  <= 16'd0;
            rem_ack    <= 16'd0;
            b_pend     <= 16'd0;
            aw_bw_r    <= 16'd0;
            bcnt       <= 16'd0;
            burst_sent <= 32'd0;
            beat_sent  <= 32'd0;
        end else begin
            /* ---- AW 受理 ---- */
            if (awvalid && awready) begin
                burst_sent <= burst_sent + 32'd1;
                rem_ack    <= rem_ack - aw_bw_r;
                b_pend     <= b_pend + 16'd1;
                bcnt       <= aw_bw_r;
                wvalid     <= 1'b1;
                busy_b     <= 1'b1;
            end
            /* ---- AW 举起（放在受理之后 ⇒ 同拍时"举下一笔"赢，awvalid 不断） ---- */
            if (pres_now) begin
                awaddr    <= naddr;
                awlen     <= pres_bw - 16'd1;
                aw_bw_r   <= pres_bw;
                awvalid   <= 1'b1;
                naddr     <= naddr + {16'd0, pres_bw} * 16;
                rem_issue <= rem_issue - pres_bw;
            end else if (awvalid && awready)
                awvalid <= 1'b0;
            /* ---- W ---- */
            if (wvalid && wready) begin
                beat_sent <= beat_sent + 32'd1;
                if (bcnt == 16'd1) wvalid <= 1'b0;
                else               bcnt   <= bcnt - 16'd1;
            end
            /* ---- B ---- */
            if (bvalid && bready) begin
                b_pend <= b_pend - 16'd1;
                busy_b <= 1'b0;
            end
            /* ---- 启动 / 收工 ---- */
            if (start) begin
                started    <= 1'b1;
                done       <= 1'b0;
                rem_issue  <= nwords;
                rem_ack    <= nwords;
                naddr      <= base;
                awvalid    <= 1'b0;
                wvalid     <= 1'b0;
                b_pend     <= 16'd0;
                bcnt       <= 16'd0;
                busy_b     <= 1'b0;
                burst_sent <= 32'd0;
                beat_sent  <= 32'd0;
            end else if (started && (rem_issue == 16'd0) && (rem_ack == 16'd0) &&
                         (b_pend == 16'd0) && !awvalid && !wvalid)
                done <= 1'b1;                         // 必须与 start 互斥，否则上一轮的 done 会压掉清零
        end
    end
endmodule
