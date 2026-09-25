/* =========================================================================
 * stream_reader.v — 16bit 像素流读取器（FWFT FIFO 直通，**支持流式供给**）
 * -------------------------------------------------------------------------
 * 语义（行级重叠版）：
 *   - en 为**电平**（本行正在处理），不再是 1 拍启动脉冲：
 *       en=1 且 FIFO 非空且尚未载入本行第一个词 → 载入并置 lane=skip
 *       行内后续词载入时 lane=0（每 8 像素弹一个词）
 *   - ready=1：本拍可提供一个像素（px 有效）；缺词时 ready=0（上层自然停顿）
 *   - rd_en 为**组合**输出：loaded && take && lane==7 当拍即为 1，
 *     使"弹词"在本拍末生效，下一拍 dout 已是新词，刚好被载入 → 每词 1 拍气泡。
 *     （若把 rd_en 寄存一拍，弹词与载词会同拍发生，载到的还是刚弹走的旧词：
 *      症状是每行第 2 个 16B 词重复第 1 个词，即"每行超过 8 像素就花屏"。）
 *   - clr：行间复位（丢弃滞留词/状态），并把 first_w 置回 1（下一行重新用 skip）
 *
 * 为什么要 first_w：原版靠"引擎把 FIFO drain 到空"来防止行间误载；
 * 行级重叠后 FIFO 里永远有下一行的数据，若仍用 lane=0 自动补载，
 * 下一行就会丢掉行首 skip、整行水平错位。
 * -------------------------------------------------------------------------
 * ★v3.1 双像素（2 px/拍）—— -DPIXEL_PIXELS2_OFF 逐字回到上面这版单像素逻辑
 * -------------------------------------------------------------------------
 * 目标：**每拍交付 2 个像素**，并藏掉单像素版"每 8 像素 1 拍重装气泡"
 * （0.889 px/拍 → 2.0 px/拍）。增量端口：ready2/px2/take2/nfull/nwords。
 *
 * 结构：FIFO 头（dout）→ 两个 128bit 词槽（w0/w1 + v0/v1 乒乓）→ 像素指针 lane。
 *   - 消费侧：一拍走 (lane, lane+1)；lane==7 的那一对**跨词**（px2 = 另一槽的
 *     lane 0），需要那一槽已有效（ready2 里体现）。
 *   - 载入侧（预取）：把 FIFO 头搬进"空闲槽"，**并在同拍弹掉刚载入的那个词**。
 *     sync_fifo 是同步读 + 输出寄存器，弹出后下一个词要 2 拍才上 dout；
 *     预取把这段延迟藏在"当前词还有 4 拍可消费"的时间里，于是不再有气泡。
 *
 * ★弹词条数必须与引擎 RS_LOOP 的 drain 口径严格一致（否则下一行的词会错位）：
 *   引擎按 `dr = cover_beats − floor((skip+width)/8)` 自己 drain 行尾残词，
 *   所以读取器**只能弹"会被整词消费"的那些词**：
 *       第 k 个词在 k ≤ nfull(=floor((skip+width)/8)) 时弹，否则不弹（留给引擎）。
 *   本版把弹词时刻**提前到"载入这一拍"**（单像素版是"消费到 lane 7 那一拍"），
 *   但**弹词集合与条数逐词不变** —— 只改时刻，不改账。
 *   nwords(=ceil((skip+width)/8)) 是本行触及的词数上界：载满 nwords 个词就停，
 *   不会越过行尾去"预取"下一行的词。
 *
 * 两个已知且可接受的残余气泡（各 1 拍，且只在**行首那一个词**上，因为
 * 首个词要从 skip 起消费）：skip=6 时首词只有 1 对、skip=7 时首词只有 1 个像素，
 * 预取来不及在 2 拍内把下一个词搬上来 ⇒ 行首停 1 拍。整屏 540 行最多 540 拍
 * （<0.25%），且只发生在源非对齐（skip∈{6,7}）时。见 功能清单 §27。
 * ========================================================================= */
module stream_reader (
    input  wire           clk,
    input  wire           rst_n,
    input  wire           clr,         // 行间复位
    input  wire           en,          // 本行处理中（电平）
    input  wire [2:0]     skip,        // 本行起始 lane 0..7
    input  wire           fifo_empty,  // FIFO 是否有字（!empty 才保证 dout 有效）
    input  wire [127:0]   fifo_dout,   // FWFT 直通
    output wire           rd_en,       // 弹词（组合）
    output wire           ready,
    output wire           ready2,      // ★v3.1：本拍能否交付 2 个像素
    output wire [15:0]    px,
    output wire [15:0]    px2,         // ★v3.1：第二个像素（跨词对 = 另一槽 lane 0）
    input  wire           take,        // 本拍消费 1 个像素
    input  wire           take2,       // ★v3.1：本拍消费 2 个像素（与 take 互斥）
    input  wire [15:0]    nfull,       // ★v3.1：本行"会被整词消费"的词数
    input  wire [15:0]    nwords       // ★v3.1：本行触及的词数（载入上界）
);

`ifdef PIXEL_PIXELS2_OFF
    /* ================= 单像素版（v2.8 行为，逐字保留） ================= */
    reg [127:0] wb;
    reg [2:0]   lane;
    reg         loaded;
    reg         first_w;               // 本行第一个词还没载入

    assign px    = wb[lane*16 +: 16];
    assign ready = loaded;
    /* 组合弹词：与本拍"消费词尾像素"同拍生效（详见文件头说明） */
    assign rd_en = loaded && take && (lane == 3'd7);
    /* 双像素端口在本模式下恒定无效（上层也只用单像素路径） */
    assign px2    = 16'd0;
    assign ready2 = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb      <= 128'd0;
            lane    <= 3'd0;
            loaded  <= 1'b0;
            first_w <= 1'b1;
        end else if (clr) begin
            wb      <= 128'd0;
            lane    <= 3'd0;
            loaded  <= 1'b0;
            first_w <= 1'b1;
        end else begin
            if (!loaded) begin
                /* 数据没到就等着（行级重叠：边到边算）
                 * 注意用 empty 而不是 count：同步读 FIFO 的存储读有 1 拍流水，
                 * 只有 !empty 才保证 fifo_dout 是当前队头。 */
                if (en && !fifo_empty) begin
                    wb      <= fifo_dout;
                    lane    <= first_w ? skip : 3'd0;
                    loaded  <= 1'b1;
                    first_w <= 1'b0;
                end
            end else if (take) begin
                lane <= lane + 3'd1;         // 7→0 自然回绕
                if (lane == 3'd7)
                    loaded <= 1'b0;          // 本拍已组合弹词，下拍载入新词
            end
        end
    end
`else
    /* ================= ★v3.1 双像素版 ================= */
    reg [127:0] w0, w1;                // 两个词槽（乒乓）
    reg         v0, v1;                // 槽有效
    reg         cur;                   // 当前消费槽（0/1）
    reg [2:0]   lane;                  // cur 槽内的像素指针
    reg         first_w;               // 本行第一个词还没载入
    reg [15:0]  wc;                    // 本行已载入的词数（1..nwords）

    /* 兼容旧层次探针（tb_alpha 打印 u_fgr.loaded/lane/first_w）：
     * loaded 在双像素版里等价于"当前槽有效"。 */
    wire         loaded = cur ? v1 : v0;
    wire [127:0] wcur   = cur ? w1 : w0;
    wire [127:0] wnxt   = cur ? w0 : w1;
    wire         vn     = cur ? v0 : v1;    // 另一槽（= 下一个词）有效

    assign px     = wcur[lane*16 +: 16];
    /* lane==7 的一对跨词：第二个像素取另一槽（下一个词）的 lane 0。
     * 该槽一定存在（载入侧保证），只有 FIFO 真的没数据时 vn=0 ⇒ ready2=0 停顿。 */
    assign px2    = (lane == 3'd7) ? wnxt[15:0] : wcur[(lane + 3'd1)*16 +: 16];
    assign ready  = loaded;
    assign ready2 = loaded && ((lane != 3'd7) || vn);

    /* 本拍消费后的 lane 指针（用 4bit 算，>=8 就是"跨过/到达词尾"）：
     *   单像素：lane+1，7→8；配对：lane+2，6→8（词内最后一对 (6,7)）、7→9（跨词对 (7,0)）。
     * 必须用 lane_aft 判词尾而不是 lane==7：配对在 lane==6 时就已经把 lane 7 吃掉了。 */
    wire [3:0] lane_aft = {1'b0, lane} + (take2 ? 4'd2 : 4'd1);
    wire       cur_end  = (take || take2) && (lane_aft >= 4'd8);
    /* 载入目标槽：当前槽空（行首）→ 当前槽；另一槽空 → 另一槽；都满 → 只能等
     * 当前词消费完这一拍再顶替进来（此时下面"释放"先写 0、载入后写 1 ⇒ 不丢词） */
    wire ld_cur   = !loaded || vn;
    wire ld_ok    = !loaded || !vn || cur_end;
    wire ld_go    = en && !fifo_empty && (wc < nwords) && ld_ok;
    /* 弹词：这个词会被整词消费（k = wc+1 ≤ nfull）才弹 —— 与引擎 dr_* 同口径。
     * 载入与弹词同拍：dout 上此刻正是刚搬进槽的那个词（!fifo_empty 保证）。 */
    assign rd_en  = ld_go && (wc < nfull);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w0 <= 128'd0; w1 <= 128'd0; v0 <= 1'b0; v1 <= 1'b0;
            cur <= 1'b0; lane <= 3'd0; first_w <= 1'b1; wc <= 16'd0;
        end else if (clr) begin
            w0 <= 128'd0; w1 <= 128'd0; v0 <= 1'b0; v1 <= 1'b0;
            cur <= 1'b0; lane <= 3'd0; first_w <= 1'b1; wc <= 16'd0;
        end else begin
            /* ---- 消费侧：lane 指针 / 词切换 / 槽释放 ---- */
            if (cur_end) begin
                cur <= ~cur;
                lane <= lane_aft[2:0];         // 8→0（词内最后一对）/ 9→1（跨词对）
                if (cur) v1 <= 1'b0; else v0 <= 1'b0;
            end else if (take2)
                lane <= lane + 3'd2;
            else if (take)
                lane <= lane + 3'd1;
            /* ---- 载入侧（必须放在消费侧之后：同槽"释放 + 载入"时载入优先）---- */
            if (ld_go) begin
                if (ld_cur) begin
                    if (cur) begin w1 <= fifo_dout; v1 <= 1'b1; end
                    else     begin w0 <= fifo_dout; v0 <= 1'b1; end
                end else begin
                    if (cur) begin w0 <= fifo_dout; v0 <= 1'b1; end
                    else     begin w1 <= fifo_dout; v1 <= 1'b1; end
                end
                if (first_w) lane <= skip;         // 行首词从 skip 起消费
                first_w <= 1'b0;
                wc      <= wc + 16'd1;
            end
        end
    end
`endif
endmodule
