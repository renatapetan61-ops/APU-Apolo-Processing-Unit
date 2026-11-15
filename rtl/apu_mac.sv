// APU — Unidade de Processamento Apolo
// v0.1: signed INT8 multiply-accumulate, INT32 accumulator.
module apu_mac (
    input  logic               clk,
    input  logic               rst,
    input  logic               valid,
    input  logic               clear,
    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,
    output logic signed [31:0] acc
);
    logic signed [15:0] product;
    always_comb product = a * b;

    always_ff @(posedge clk) begin
        if (rst)
            acc <= 32'sd0;
        else if (valid) begin
            if (clear)
                acc <= {{16{product[15]}}, product};
            else
                acc <= acc + {{16{product[15]}}, product};
        end
    end
endmodule
