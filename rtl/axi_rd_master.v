/* =========================================================================
 * axi_rd_master.v — AXI4 主机读通道（INCR 突发，**多笔在飞 / 突发流水**）
 * -------------------------------------------------------------------------
 * 与原版的区别：原版"单笔 outstanding"（IDLE→AR→RCV→DONE 一笔一笔来），
 * 每笔突发都要重新吃一次 AR 握手 + DDR 读延迟；本版允许最多 OUTSTAND 笔
 * 同时在空中，于是：
 *   - 上层可以**背靠背连续发突发**（rd_ready 为信用，valid/ready 握手），
 *     "取第 r+1 行"的 AR 在"第 r 行数据还在回来"时就已经发出去了；
 *   - DDR 的读延迟只暴露一次（流水填满后数据连续回流），
 *     而不是每笔突发都暴露一次。
 *
 * 两个小队列（均为 OUTSTAND 深）：
 *   AR 队列：已接收、等待发到 AXI AR 通道的请求 {addr,len,sel}
 *   R  队列：已发出 AR、等待数据回来的突发 {len,sel}（顺序即回程顺序）
 * 信用 = OUTSTAND - (AR队列 + R队列)；R 数据按 R 队列队头的 tag 分到 fg/bg/desc。
 * 说明：AXI4 同 ID 的 R 回程必须保序，本模块只用一个 ID，故按序分路即正确。
 *
 * ★v2.11（S2 显示列表）：tag 由 1bit(rd_bg) 扩成 2bit(rd_sel)：00=fg 01=bg 10=desc。
 *   - 新增**第二请求口** dl_*（DFU 的描述符/几何表读），与引擎请求口共用信用池；
 *   - 仲裁：**引擎 > desc**，但 desc 等待超过 AGE_MAX 拍就提权一笔（防饿死）。
 *     "fg > bg" 由引擎自己保证（blt_engine_fsm 里 fg_left 优先），所以这里
 *     只需要"引擎口 vs desc 口"两级 —— 效果等价于设计文档 §7.2 的 fg>bg>desc。
 *   - ★ 判据只用 `dl_req` 与 age，**不用 rd_req**：引擎侧的 rd_req 本身是
 *     `issue_en && rd_ready`（ready 门控的 valid），若让 desc 的胜负再依赖
 *     rd_req，就会形成 rd_ready→rd_req→dl_win→rd_ready 的组合环。
 *     现在 rd_ready = credit && !dl_win，环被结构性地切断。
 *   - `-DDL_OFF` 时 dl_req 恒 0 ⇒ dl_win 恒 0 ⇒ rd_ready/分路与改动前逐位相同。
 * ========================================================================= */
module axi_rd_master #(
    parameter AXI_DATA_W = 128,
    parameter MAX_BEATS  = 16,
    parameter OUTSTAND   = 4,         // 同时在飞的突发数（≥1）
    parameter AGE_MAX    = 64         // desc 流最长等待拍数（到了就提权一笔）
)(
    input  wire                    clk,
    input  wire                    rst_n,

    /* ---- 请求侧（valid/ready，可背靠背） ---- */
    input  wire                    rd_req,
    input  wire [31:0]             rd_addr,
    input  wire [7:0]              rd_len,     // 拍数 1..MAX_BEATS
    input  wire [1:0]              rd_sel,     // 00=fg/src 01=bg 10=desc（引擎只用 00/01）
    output wire                    rd_ready,   // 有信用**且本拍真的受理**：可以接收请求
    output wire                    rd_busy,    // 仍有在飞（AR 或 R）
    output wire                    rd_done,    // 一拍脉冲：某笔突发收完
    output wire [1:0]              rd_tag_out, // 完成笔的 tag

    /* ---- ★v2.11 第二请求口：显示列表取指器的描述符/几何表读 ---- */
    input  wire                    dl_req,
    input  wire [31:0]             dl_addr,
    input  wire [7:0]              dl_len,
    output wire                    dl_ready,   // 有信用且本拍真的受理

    /* ---- 数据侧（按 tag 分路） ---- */
    input  wire                    fg_rready,
    input  wire                    bg_rready,
    input  wire                    desc_rready,
    output wire                    fg_rvalid,
    output wire                    bg_rvalid,
    output wire                    desc_rvalid,
    output wire [AXI_DATA_W-1:0]   rdata,
    output wire [1:0]              rd_rresp,   // 本拍 R 的响应（配合 *_rvalid 用）

    /* ---- AXI4 读口 ---- */
    output wire [31:0]             m_axi_araddr,
    output wire [7:0]              m_axi_arlen,
    output wire [2:0]              m_axi_arsize,
    output wire [1:0]              m_axi_arburst,
    output wire                    m_axi_arvalid,
    input  wire                    m_axi_arready,
    input  wire [AXI_DATA_W-1:0]   m_axi_rdata,
    input  wire [1:0]              m_axi_rresp,
    input  wire                    m_axi_rlast,
    input  wire                    m_axi_rvalid,
    output wire                    m_axi_rready
);
    localparam AW = $clog2(OUTSTAND);
    localparam AGEW = 7;                       // AGE_MAX ≤ 127

    /* ---------------- AR 队列 ---------------- */
    reg [31:0]    arq_addr [0:OUTSTAND-1];
    reg [7:0]     arq_len  [0:OUTSTAND-1];
    reg [1:0]     arq_sel  [0:OUTSTAND-1];
    reg [AW:0]    arq_cnt, arq_wp, arq_rp;

    /* ---------------- R 队列（在飞突发描述符） ---------------- */
    reg [7:0]     rq_len   [0:OUTSTAND-1];
    reg [1:0]     rq_sel   [0:OUTSTAND-1];
    reg [AW:0]    rq_cnt, rq_wp, rq_rp;

    reg [7:0]     bcnt;          // 当前回程突发的拍计数
    reg           done_r, tag_r;
    reg [AGEW-1:0] age;          // desc 已等待拍数（防饿死）
    reg           eng_gnt_d;     // 上一拍引擎口被受理（desc 让路的判据，见下）

    wire [AW-1:0] arp = arq_rp[AW-1:0];
    wire [AW-1:0] rrp = rq_rp[AW-1:0];
    wire [AW-1:0] awp = arq_wp[AW-1:0];
    wire [AW-1:0] rwp = rq_wp[AW-1:0];

    /* ---------------- ★v2.11 仲裁：引擎 > desc，desc 超时提权 ----------------
     * "引擎是不是在连发"用**上一拍**的受理情况（eng_gnt_d，触发器）判断，
     * 不用本拍的 rd_req：引擎的 rd_req = issue_en && rd_ready，若让它参与
     * desc 的胜负就会形成 rd_ready→rd_req→dl_win→rd_ready 的组合环。
     * 语义：引擎上一拍刚拿到通道（正在流水）⇒ desc 让路，最多让 AGE_MAX 拍；
     *       引擎上一拍没发 ⇒ desc 本拍即可拿到（空闲时零额外延迟）。 */
    wire          credit  = ((arq_cnt + rq_cnt) < OUTSTAND[AW:0]);
    wire          dl_win  = dl_req && credit &&
                            (!eng_gnt_d || (age >= AGE_MAX[AGEW-1:0]));
    wire          eng_win = rd_req && credit && !dl_win;

    assign rd_ready = credit && !dl_win;        // 引擎侧：本拍确实会被受理
    /* ★v3.1 修复：DFU 侧的受理标志必须与"真的入队"逐拍等价。
     * 原写法 `credit && !eng_win` 在"引擎上一拍刚赢、本拍不再请求"(eng_gnt_d=1,
     * rd_req=0) 时给出 dl_ready=1，而 arq_push = eng_win|dl_win = 0 —— 请求被
     * **静默吞掉**：DFU 进 S_GEOMW 等一个永远不会回来的 R 拍，直到 wd 看门狗
     * （tb_dl_basic 实测 t=46306 受理、无 sel=10 入队，t=50402 报 WATCHDOG，
     * DL_ERR=0x00030010、FAULT_ADDR=0x7030）。这类"丢一笔 desc/几何表读"正是
     * 板上 DL 看门狗重试的根因。改成与入队同源（dl_win）后：受理⟺入队，
     * 代价只是"引擎上一拍赢过 + 本拍空闲"时最多再等 AGE_MAX=64 拍（有界，
     * DL 看门狗 4096 拍，远够）；组合深度反而比原式更浅（少一级 eng_win 反相）。 */
    assign dl_ready = dl_win;

    wire          arq_push = eng_win || dl_win;
    wire [31:0]   push_addr = dl_win ? dl_addr : rd_addr;
    wire [7:0]    push_len  = dl_win ? dl_len  : rd_len;
    wire [1:0]    push_sel  = dl_win ? 2'b10   : rd_sel;

    wire          arq_pop  = m_axi_arvalid && m_axi_arready;
    wire          rq_push  = arq_pop;
    wire          beat_hs  = m_axi_rvalid && m_axi_rready;
    wire          rq_pop   = beat_hs && (m_axi_rlast || (bcnt == rq_len[rrp] - 8'd1));

    assign rd_busy  = (arq_cnt != 0) || (rq_cnt != 0);

    assign m_axi_arvalid = (arq_cnt != 0);
    assign m_axi_araddr  = arq_addr[arp];
    assign m_axi_arlen   = arq_len[arp] - 8'd1;
    assign m_axi_arsize  = $clog2(AXI_DATA_W/8);
    assign m_axi_arburst = 2'b01;                       // INCR

    assign m_axi_rready  = (rq_cnt != 0) &&
                           ((rq_sel[rrp] == 2'b00) ? fg_rready :
                            (rq_sel[rrp] == 2'b01) ? bg_rready : desc_rready);
    assign fg_rvalid     = m_axi_rvalid && m_axi_rready && (rq_sel[rrp] == 2'b00);
    assign bg_rvalid     = m_axi_rvalid && m_axi_rready && (rq_sel[rrp] == 2'b01);
    assign desc_rvalid   = m_axi_rvalid && m_axi_rready && (rq_sel[rrp] == 2'b10);
    assign rdata         = m_axi_rdata;
    assign rd_rresp      = m_axi_rresp;

    assign rd_done       = done_r;
    assign rd_tag_out    = tag_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arq_cnt <= {(AW+1){1'b0}};
            arq_wp  <= {(AW+1){1'b0}};
            arq_rp  <= {(AW+1){1'b0}};
            rq_cnt  <= {(AW+1){1'b0}};
            rq_wp   <= {(AW+1){1'b0}};
            rq_rp   <= {(AW+1){1'b0}};
            bcnt    <= 8'd0;
            done_r  <= 1'b0;
            tag_r   <= 2'd0;
            age     <= {AGEW{1'b0}};
            eng_gnt_d <= 1'b0;
        end else begin
            /* ---- AR 队列 ---- */
            if (arq_push) begin
                arq_addr[awp] <= push_addr;
                arq_len [awp] <= push_len;
                arq_sel [awp] <= push_sel;
                arq_wp        <= arq_wp + 1'b1;
            end
            if (arq_pop)
                arq_rp <= arq_rp + 1'b1;
            arq_cnt <= arq_cnt + (arq_push ? 1'b1 : 1'b0) - (arq_pop ? 1'b1 : 1'b0);

            /* ---- R 队列（AR 一发出即登记，回程按序消费） ---- */
            if (rq_push) begin
                rq_len[rwp] <= arq_len[arp];
                rq_sel[rwp] <= arq_sel[arp];
                rq_wp       <= rq_wp + 1'b1;
            end
            if (rq_pop)
                rq_rp <= rq_rp + 1'b1;
            rq_cnt <= rq_cnt + (rq_push ? 1'b1 : 1'b0) - (rq_pop ? 1'b1 : 1'b0);

            /* ---- desc 等待年限（提权用；等太久就压到 AGE_MAX 不再涨） ---- */
            if (dl_win)          age <= {AGEW{1'b0}};
            else if (dl_req)     age <= (age == AGE_MAX[AGEW-1:0]) ? age : age + 1'b1;
            else                 age <= {AGEW{1'b0}};

            eng_gnt_d <= eng_win;

            /* ---- 拍计数与完成脉冲 ---- */
            if (rq_pop)
                bcnt <= 8'd0;
            else if (beat_hs)
                bcnt <= bcnt + 8'd1;

            done_r <= rq_pop;
            if (rq_pop)
                tag_r <= rq_sel[rrp];
        end
    end
endmodule
