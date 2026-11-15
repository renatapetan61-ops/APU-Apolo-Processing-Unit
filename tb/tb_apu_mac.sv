`timescale 1ns/1ps
module tb_apu_mac;
    logic clk = 0, rst = 0, valid = 0, clear = 0;
    logic signed [7:0] a = 0, b = 0;
    logic signed [31:0] acc;

    apu_mac dut(.clk(clk), .rst(rst), .valid(valid),
                .clear(clear), .a(a), .b(b), .acc(acc));
    always #5 clk = ~clk;

    task automatic tick;
        @(posedge clk); #1;
    endtask

    initial begin
        rst = 1; tick();
        if (acc !== 0) $fatal(1, "reset failed: %0d", acc);
        rst = 0;

        a = 8'sd3; b = 8'sd4; valid = 1; clear = 1; tick();
        if (acc !== 32'sd12) $fatal(1, "positive product failed: %0d", acc);

        a = -8'sd2; b = 8'sd5; clear = 0; tick();
        if (acc !== 32'sd2) $fatal(1, "signed accumulation failed: %0d", acc);

        valid = 0; a = 8'sd99; b = 8'sd99; tick();
        if (acc !== 32'sd2) $fatal(1, "hold failed: %0d", acc);

        valid = 1; clear = 1; a = -8'sd128; b = -8'sd128; tick();
        if (acc !== 32'sd16384) $fatal(1, "INT8 extreme failed: %0d", acc);

        $display("PASS: APU MAC RTL tests");
        $finish;
    end
endmodule
