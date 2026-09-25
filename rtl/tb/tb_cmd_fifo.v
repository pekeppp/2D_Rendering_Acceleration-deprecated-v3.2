/* =========================================================================
 * tb_cmd_fifo.v — 指令 FIFO 单元自测
 * 验证：push/pop、word_count、cmd_count(=word>>3)、满空、同拍读写
 * ========================================================================= */
`timescale 1ns/1ps
module tb_cmd_fifo;
    reg          clk = 1'b0;
    reg          rst_n = 1'b0;
    reg          wr_en = 1'b0;
    reg  [31:0]  din = 32'd0;
    reg          rd_en = 1'b0;
    wire [31:0]  dout;
    wire         full, empty;
    wire [11:0]  word_count;
    wire [8:0]   cmd_count;

    cmd_fifo #(.CMD_DEPTH(256)) u_cmd (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .din(din),
        .rd_en(rd_en), .dout(dout),
        .full(full), .empty(empty),
        .word_count(word_count), .cmd_count(cmd_count)
    );

    always #5 clk = ~clk;

    integer errors = 0;
    integer i;

    task check;
        input [255:0] name;
        input ok;
        begin
            if (!ok) begin
                errors = errors + 1;
                $display("FAIL: %0s", name);
            end else begin
                $display("PASS: %0s", name);
            end
        end
    endtask

    // 等待一个时钟沿并错开 #1，保证 DUT 在下一沿采样
    task cycle;
        begin
            @(posedge clk); #1;
        end
    endtask

    initial begin
        cycle(); rst_n = 1'b1; cycle();

        // 1) 初始为空
        check("初始 empty", empty);
        check("初始 count=0", word_count == 0 && cmd_count == 0);

        // 2) 推 20 字 → word=20, cmd=2（floor(20/8)=2）
        for (i = 0; i < 20; i = i + 1) begin
            cycle();
            wr_en = 1'b1; din = 32'hA000_0000 + i;
        end
        cycle(); wr_en = 1'b0;
        check("word_count=20", word_count == 20);
        check("cmd_count=2", cmd_count == 2);
        check("非空", !empty);
        check("未满", !full);

        // 3) 逐字弹出并校验顺序（新协议：先等 !empty 再弹；同步读 FIFO 有 1 拍流水）
        for (i = 0; i < 20; i = i + 1) begin
            while (empty) cycle();
            if (dout !== (32'hA000_0000 + i)) begin
                errors = errors + 1;
                $display("FAIL: 弹出顺序 dout[%0d] 期望 %h 实际 %h", i, 32'hA000_0000 + i, dout);
            end
            rd_en = 1'b1; cycle(); rd_en = 1'b0;
        end
        while (!empty) cycle();
        check("弹空后 empty", empty);
        check("弹空后 count=0", word_count == 0);

        // 4) 空→非空（写穿透）与顺序：入队 A 读 A、入队 B 读 B
        cycle(); wr_en = 1'b1; din = 32'hAAAA_AAAA;
        cycle(); wr_en = 1'b0;
        while (empty) cycle();
        check("预推 A 后可读 A", dout == 32'hAAAA_AAAA);
        rd_en = 1'b1; cycle(); rd_en = 1'b0;
        while (!empty) cycle();
        cycle(); wr_en = 1'b1; din = 32'hBBBB_BBBB;
        cycle(); wr_en = 1'b0;
        while (empty) cycle();
        check("再推 B 后可读 B", dout == 32'hBBBB_BBBB);
        rd_en = 1'b1; cycle(); rd_en = 1'b0;
        while (!empty) cycle();
        check("清空", empty && word_count == 0);

        // 5) 填满 2048 → full=1、cmd_count=256；满后写被忽略
        for (i = 0; i < 2048; i = i + 1) begin
            cycle();
            wr_en = 1'b1; din = 32'h0000_FFFF & i;
        end
        cycle(); wr_en = 1'b0;
        check("满标志", full);
        check("满时 word_count=2048", word_count == 2048);
        check("满时 cmd_count=256", cmd_count == 256);
        cycle(); wr_en = 1'b1; din = 32'h1234_5678;
        cycle(); wr_en = 1'b0;
        check("满时写被忽略 count 不变", word_count == 2048);

        if (errors == 0)
            $display("========== tb_cmd_fifo ALL PASS ==========");
        else
            $display("========== tb_cmd_fifo FAILED: %0d ==========", errors);
        $finish;
    end
endmodule
