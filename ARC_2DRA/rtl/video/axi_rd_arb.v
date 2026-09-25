/* =========================================================================
 * axi_rd_arb.v — 2 选 1 AXI4 读通道仲裁（CPU 优先让路，扫描输出按需取用）
 * -------------------------------------------------------------------------
 * 背景：本工程 DDR 控制器只有一个 AXI 从口，原先 CPU 独占。加入 HDMI 扫描
 *       输出后需要两个读主机共享；写通道（AW/W/B）仍由 CPU 直连，不经过本模块。
 * 规则：
 *   - 同一时刻只允许一个主机拥有读通道（owner）
 *   - 仅当当前 owner 没有未完成突发（cnt==0）且本拍没有新的 AR 握手时才切换，
 *     保证 R 数据回程归属明确、绝不错路
 *   - 扫描输出有请求时获得通道；其请求队列空时立刻归还 CPU（CPU 不会被饿死）
 * ========================================================================= */
`timescale 1ns/1ps
module axi_rd_arb #(
    parameter AW     = 28,
    parameter DW     = 128,
    parameter IDW    = 4,
    /* 兼容保留：不再使用（有界优先已成为默认行为，见 c_arready 一节的说明） */
    parameter S_PRIO = 0,
    /* c 侧（CPU/L1）连续等待上限：超过它就把通道强制放给 c 侧一笔，
     * 保证近实时消费方（扫描输出）拿得到通道的同时 CPU 也不被饿死。 */
    parameter [7:0] WAIT_MAX = 8'd32,
    /* ★ cnt_s 泄漏兜底等待上限（拍）：s 侧自称安静（!s_arvalid && !s_hold）却没有把
     * cnt_s 归零时，等这么多拍就强制归还通道。详见 owner==1 分支的说明。
     * 取 256 拍 ≈ 2.5us：正常突发收完只要几十~几百拍，s_quiet 为真时本就不该有在飞突发。 */
    parameter [15:0] LEAK_TO = 16'd256
)(
    input  wire            clk,
    input  wire            rst_n,

    /* ---- CPU（SoC 外存口）读通道 ---- */
    input  wire [AW-1:0]   c_araddr,
    input  wire [7:0]      c_arlen,
    input  wire [2:0]      c_arsize,
    input  wire [1:0]      c_arburst,
    input  wire [IDW-1:0]  c_arid,
    input  wire            c_arvalid,
    output wire            c_arready,
    output wire [DW-1:0]   c_rdata,
    output wire [1:0]      c_rresp,
    output wire [IDW-1:0]  c_rid,
    output wire            c_rlast,
    output wire            c_rvalid,
    input  wire            c_rready,

    /* ---- 扫描输出读通道 ---- */
    input  wire [AW-1:0]   s_araddr,
    input  wire [7:0]      s_arlen,
    input  wire [2:0]      s_arsize,
    input  wire [1:0]      s_arburst,
    input  wire            s_arvalid,
    output wire            s_arready,
    /* ★ 归属钉住：s 侧"一行取数尚未搬完"时拉高。释放条件里必须带上它 ——
     *   否则一旦 `cnt_s` 与从机的 rlast 口径出现偏差（例如控制器把突发合并/拆分，
     *   或某个 beat 被错路），仲裁器会误判 s 侧已完成、把通道交还 c 侧，
     *   于是 s 侧剩余的 R 拍被送给 c 侧 → s 侧永远等不到 → 取数 FSM 卡死（实测现场：
     *   st=S_FETCH beat=9/16 own=0 cnt_s=0，画面全黑且不再恢复）。 */
    input  wire            s_hold,
    output wire [DW-1:0]   s_rdata,
    output wire [1:0]      s_rresp,
    output wire            s_rlast,
    output wire            s_rvalid,
    input  wire            s_rready,

    /* ---- DDR 控制器 AXI 从口（读） ---- */
    output wire [AW-1:0]   m_araddr,
    output wire [7:0]      m_arlen,
    output wire [2:0]      m_arsize,
    output wire [1:0]      m_arburst,
    output wire [IDW-1:0]  m_arid,
    output wire            m_arvalid,
    input  wire            m_arready,
    input  wire [DW-1:0]   m_rdata,
    input  wire [1:0]      m_rresp,
    input  wire [IDW-1:0]  m_rid,
    input  wire            m_rlast,
    input  wire            m_rvalid,
    output wire            m_rready
);
    reg        owner;            // 0 = CPU，1 = 扫描输出
    reg [7:0]  cnt_c;            // CPU 未完成突发数
    reg [7:0]  cnt_s;            // 扫描未完成突发数
    reg [7:0]  wait_c;           // c 侧连续等待拍数（有界公平用）
    reg [15:0] leak_c;           // s 侧"自称安静但 cnt_s 不归零"的持续拍数（泄漏兜底）

    /* s 侧自称搬运完毕：没有新 AR 在等，也没有在飞突发 ⇒ 不会有属于它的 R 拍再来 */
    wire s_quiet = !s_arvalid && !s_hold;

    wire c_ar_hs = c_arvalid && c_arready;
    wire s_ar_hs = s_arvalid && s_arready;
    wire c_r_hs  = c_rvalid  && c_rready;
    wire s_r_hs  = s_rvalid  && s_rready;
    wire c_r_end = c_r_hs && c_rlast;
    wire s_r_end = s_r_hs && s_rlast;

    /* ================= 有界优先（本次采用）=================
     * 目标：**实时消费方（s 侧 = 扫描输出）拿得到通道**，同时**c 侧（CPU/L1）不被饿死**。
     *
     * 规则：s 侧一挂起 AR，就门控 c 侧新 AR（`c_arready=0`）→ cnt_c 只减不增
     * → `cnt_c==0` 的让位窗口必然出现；但 **c 侧等够 WAIT_MAX 拍就强制放它过一笔**。
     *   · 没有门控（`!c_arvalid` 或裸 `!c_ar_hs`）：c 侧一旦连续请求，让位窗口就
     *     再也回不来 —— 实测连续请求的 CPU 会把扫描输出**完全饿死（0 行取数）**，
     *     板级表现就是待机 demo 的"大面积三角形黑色闪烁"。
     *   · 只有门控没有上限（上一版 S_PRIO=1）：CPU 侧的等待无界，且 s 侧 arvalid
     *     中途落下时通道被抢走就再拿不回来（实测 48000 周期只取到 11 行）。
     *   两侧都有界，才是可上板的行为。
     *
     * 上限取值：WAIT_MAX=32 拍（core 时钟 100MHz ≈ 0.32us）。配合"扫描输出一行
     * 取数 ≈250~400 拍"（v2.5 的快取数），CPU 侧最坏等待 ≈ WAIT_MAX + 一笔突发，
     * 不会影响启动/搬运；扫描输出则稳定拿到整行所需的服务。 */
    wire c_starved = (wait_c >= WAIT_MAX);
    /* ★ 门控必须作用在"送给 DDR 的 valid"上，光拉低主机侧 ready 是**没用的**：
     *   从机看的是 `m_arvalid && m_arready`。只拉 c_arready 时 m_arvalid 仍是 c_arvalid，
     *   DDR 照样受理这笔 AR —— 计数的 c_ar_hs 却是 0 ⇒ "已受理未计入" ⇒ 该笔的 R 数据
     *   回来时归属错乱、cnt_c 泄漏（实测 tb_arb_deadlock: cnt 漂到 254、不安全让位=2、
     *   扫描主机收到 CPU 的数据）。这与写侧 skid 那个坑同源。 */
    wire c_ar_ok = !(s_arvalid && !c_starved);      // 允许 c 侧请求上通道
    assign c_arready = ((owner == 1'b0) && c_ar_ok) ? m_arready : 1'b0;
    assign s_arready = (owner == 1'b1) ? m_arready : 1'b0;

    assign m_araddr  = owner ? s_araddr  : c_araddr;
    assign m_arlen   = owner ? s_arlen   : c_arlen;
    assign m_arsize  = owner ? s_arsize  : c_arsize;
    assign m_arburst = owner ? s_arburst : c_arburst;
    assign m_arid    = owner ? 4'h1      : c_arid;
    assign m_arvalid = owner ? s_arvalid : (c_arvalid && c_ar_ok);   // ← 门控在 valid 上

    assign c_rvalid  = m_rvalid && (owner == 1'b0);
    assign s_rvalid  = m_rvalid && (owner == 1'b1);
    assign m_rready  = owner ? s_rready : c_rready;

    assign c_rdata   = m_rdata;
    assign c_rresp   = m_rresp;
    assign c_rid     = m_rid;
    assign c_rlast   = m_rlast;
    assign s_rdata   = m_rdata;
    assign s_rresp   = m_rresp;
    assign s_rlast   = m_rlast;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            owner  <= 1'b0;
            cnt_c  <= 8'd0;
            cnt_s  <= 8'd0;
            wait_c <= 8'd0;
            leak_c <= 16'd0;
        end else begin
            cnt_c <= cnt_c + (c_ar_hs ? 8'd1 : 8'd0) - (c_r_end ? 8'd1 : 8'd0);
            cnt_s <= cnt_s + (s_ar_hs ? 8'd1 : 8'd0) - (s_r_end ? 8'd1 : 8'd0);

            /* c 侧"连续等待"计时：**不看 owner** —— 只要它挂着 AR 却没被受理就算在等。
             * （早期写成"owner==1 就清零"，结果扫描输出每行重新抢回通道时把 CPU 的
             *   等待计时冲掉，公平上限永不触发 → CPU 被彻底饿死：实测完成突发 0 笔。） */
            if (c_ar_hs || !c_arvalid)
                wait_c <= 8'd0;
            else if (wait_c != 8'hFF)
                wait_c <= wait_c + 8'd1;

            if (owner == 1'b0) begin
                /* 让位给 s 侧（扫描输出）：
                 *   · `cnt_c==0`：c 侧没有在飞突发（R 数据归属才明确，绝不错路）；
                 *   · `!c_ar_hs`：本拍 c 侧没有真的握手（门控后 s_arvalid 时必然成立，
                 *     但 c_starved 放行那一拍照样要挡住，否则那笔突发会被判给 s 侧）；
                 *   · `s_arvalid`：s 侧确实在等通道。 */
                if (cnt_c == 8'd0 && !c_ar_hs && s_arvalid)
                    owner <= 1'b1;
            end else begin
                /* 归还 CPU：
                 *   · `s_quiet = !s_arvalid && !s_hold`：**s 侧自己确认"搬完了、也没有新 AR"**。
                 *     s_hold 的语义是"有一笔突发真在飞"（fb_scanout 里 = ar_idx != burst_done），
                 *     所以它为假就代表不会有属于 s 侧的 R 拍再来 ⇒ 换手绝不会错路。
                 *   · `cnt_s==0`：计数口径（AR 握手 − rlast）也归零。
                 *
                 * ★★ 但 `cnt_s` **不能具备永久否决权**（这是上板实测出来的硬 bug）：
                 *   扫描输出的取数看门狗超时放弃本行时，清的是**它自己的**账本
                 *   （ar_idx/burst_done 清零 → s_hold 落下），而仲裁器这边那笔突发的 AR
                 *   早已计过数、对应的 rlast 却永远不会来了 ⇒ `cnt_s` 永久泄漏 ≠ 0 ⇒
                 *   归还条件被永远否决 ⇒ owner 永远停在 1（扫描输出）⇒
                 *   **CPU 再也拿不到 DDR 读通道**。本工程整个程序都在 DDR 里，
                 *   于是整机静止、串口再无输出（扫描输出还在正常扫描 ⇒ 画面停在最后一帧）。
                 *   板级实证：自检阶段读到 `SCAN=00070108`（高 16 位 = 已放弃 7 行），
                 *   紧接着 CPU 就死了。
                 *   ⇒ 兜底：s 侧自称安静但 cnt_s 迟迟不归零，等够 LEAK_TO 拍就强制归还。
                 *   LEAK_TO 取 256 拍（2.5us）：正常一笔突发收完只需几十~几百拍，
                 *   而 s_quiet 为真时本来就不该有在飞突发，所以 256 拍足够区分"泄漏"与"正常"。 */
                if (s_quiet && (cnt_s != 8'd0)) begin
                    if (leak_c != 16'hFFFF)
                        leak_c <= leak_c + 16'd1;
                end else
                    leak_c <= 16'd0;

                if (s_quiet && ((cnt_s == 8'd0) || (leak_c >= LEAK_TO)))
                    owner <= 1'b0;
            end
        end
    end
endmodule
