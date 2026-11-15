`timescale 1ns/1ps
module tb_apu_overflow;
 logic clk=0,rst=0,clear=0,valid=0;
 logic signed [7:0] a=0,b=0;
 logic signed [31:0] acc;
 apu_mac_pipe dut(.clk(clk),.rst(rst),.clear(clear),.valid(valid),.a(a),.b(b),.acc(acc));
 always #5 clk=~clk;
 initial begin
  rst=1; @(posedge clk); #1; rst=0;
  // White-box boundary test: seed accumulator at INT32_MAX, then add 1.
  force dut.acc = 32'sh7fffffff;
  @(negedge clk); a=8'sd1; b=8'sd1; valid=1;
  @(posedge clk); #1; release dut.acc;
  @(negedge clk); valid=0;
  @(posedge clk); #1;
  if(acc !== 32'sh80000000) $fatal(1,"INT32 wraparound failed: %h",acc);
  $display("PASS: INT32 accumulator wraps from 0x7fffffff to 0x80000000");
  $finish;
 end
endmodule
