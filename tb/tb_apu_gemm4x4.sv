`timescale 1ns/1ps
module tb_apu_gemm4x4;
 logic clk=0, rst=0, start=0;
 logic [127:0] a_matrix='0, b_matrix='0;
 logic busy, done;
 logic [511:0] c_matrix;
 integer cycles;
 apu_matrix_controller dut(.clk(clk),.rst(rst),.start(start),.a_matrix(a_matrix),.b_matrix(b_matrix),.busy(busy),.done(done),.c_matrix(c_matrix));
 always #5 clk=~clk;
 task automatic run_identity_case(input integer case_id);
  begin
   @(negedge clk);
   a_matrix=128'h01000000000100000000010000000001;
   b_matrix=128'h01000000000100000000010000000001;
   start=1;
   @(posedge clk); #1; cycles=1;
   @(negedge clk); start=0;
   while(!done && cycles<12) begin @(posedge clk); #1; cycles=cycles+1; end
   if(!done) $fatal(1,"timeout case %0d",case_id);
   if(cycles!=7) $fatal(1,"latency case %0d expected 7 got %0d",case_id,cycles);
   if(c_matrix !== 512'h00000001_00000000_00000000_00000000_00000000_00000001_00000000_00000000_00000000_00000000_00000001_00000000_00000000_00000000_00000000_00000001)
    $fatal(1,"identity GEMM mismatch case %0d: %h",case_id,c_matrix);
   $display("PASS identity GEMM case %0d: latency=%0d cycles",case_id,cycles);
  end
 endtask
 initial begin
  rst=1; repeat(2) @(posedge clk); #1 rst=0;
  run_identity_case(1);
  // The next request is accepted while DONE is high: initiation interval is 7 clocks.
  run_identity_case(2);
  $display("PASS: APU v0.2 latency and back-to-back throughput");
  $finish;
 end
endmodule
