// APU v0.2 — 4x4 parallel MAC array; registered product then accumulation.
module apu_mac_pipe (
 input logic clk, rst, clear, valid,
 input logic signed [7:0] a, b,
 output logic signed [31:0] acc
);
 logic signed [15:0] product_q;
 logic product_valid_q;
 always_ff @(posedge clk) begin
  if (rst) begin product_q <= '0; product_valid_q <= 1'b0; acc <= '0; end
  else if (clear) begin product_q <= '0; product_valid_q <= 1'b0; acc <= '0; end
  else begin
   if (product_valid_q) acc <= acc + {{16{product_q[15]}}, product_q};
   if (valid) product_q <= a * b;
   product_valid_q <= valid;
  end
 end
endmodule

module apu_systolic_array_4x4 (
 input logic clk, rst, clear, valid,
 input logic [127:0] a_rows, b_cols,
 input logic [5:0] k_index,
 output logic [511:0] c_matrix
);
 genvar r, c;
 generate
  for (r=0; r<4; r=r+1) begin: g_row
   for (c=0; c<4; c=c+1) begin: g_col
    wire signed [7:0] a_value;
    wire signed [7:0] b_value;
    wire signed [31:0] acc_value;
    assign a_value = $signed(a_rows[((r*4)+k_index)*8 +: 8]);
    assign b_value = $signed(b_cols[((k_index*4)+c)*8 +: 8]);
    assign c_matrix[((r*4)+c)*32 +: 32] = acc_value;
    apu_mac_pipe u_pe(.clk(clk), .rst(rst), .clear(clear), .valid(valid),
                      .a(a_value), .b(b_value), .acc(acc_value));
   end
  end
 endgenerate
endmodule
