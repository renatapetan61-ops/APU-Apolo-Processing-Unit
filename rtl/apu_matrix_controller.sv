// APU v0.2 — 4x4 INT8 GEMM controller. Matrices are row-major, LSB element first.
module apu_matrix_controller (
 input logic clk, rst, start,
 input logic [127:0] a_matrix, b_matrix,
 output logic busy, done,
 output logic [511:0] c_matrix
);
 typedef enum logic [2:0] {IDLE, CLEAR_ACC, FEED, DRAIN, DONE} state_t;
 state_t state;
 logic [127:0] a_reg, b_reg;
 logic [1:0] k_index;
 logic array_clear, array_valid;
 always_comb begin
  array_clear = 1'b0; array_valid = 1'b0;
  busy = (state != IDLE) && (state != DONE);
  done = (state == DONE);
  case (state)
   CLEAR_ACC: array_clear = 1'b1;
   FEED: array_valid = 1'b1;
   default: begin end
  endcase
 end
 apu_systolic_array_4x4 u_array(
  .clk(clk), .rst(rst), .clear(array_clear), .valid(array_valid),
  .a_rows(a_reg), .b_cols(b_reg), .k_index({4'b0000,k_index}), .c_matrix(c_matrix));
 always_ff @(posedge clk) begin
  if (rst) begin state <= IDLE; a_reg <= '0; b_reg <= '0; k_index <= '0; end
  else case (state)
   IDLE: if (start) begin a_reg <= a_matrix; b_reg <= b_matrix; k_index <= 0; state <= CLEAR_ACC; end
   CLEAR_ACC: begin k_index <= 0; state <= FEED; end
   FEED: if (k_index == 3) state <= DRAIN; else k_index <= k_index + 1'b1;
   DRAIN: state <= DONE;
   DONE: if (start) begin a_reg <= a_matrix; b_reg <= b_matrix; k_index <= 0; state <= CLEAR_ACC; end else state <= IDLE;
   default: state <= IDLE;
  endcase
 end
endmodule
