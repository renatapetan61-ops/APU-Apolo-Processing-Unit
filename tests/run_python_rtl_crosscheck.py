#!/usr/bin/env python3
"""Generate randomized matrices, compute a Python oracle, and compare RTL output."""
import random
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def pack(matrix, width):
    value = 0
    for r in range(4):
        for c in range(4):
            value |= (matrix[r][c] & ((1 << width) - 1)) << ((r * 4 + c) * width)
    return f"{width * 16}'h{value:0{width * 4}x}"

def gemm(a, b):
    out = []
    for r in range(4):
        row = []
        for c in range(4):
            value = sum(a[r][k] * b[k][c] for k in range(4)) & 0xffffffff
            if value >= 0x80000000:
                value -= 0x100000000
            row.append(value)
        out.append(row)
    return out

def main():
    rng = random.Random(20261115)
    cases = []
    for _ in range(16):
        a = [[rng.randint(-128, 127) for _ in range(4)] for _ in range(4)]
        b = [[rng.randint(-128, 127) for _ in range(4)] for _ in range(4)]
        cases.append((a, b, gemm(a, b)))

    task_lines = []
    for index, (a, b, expected) in enumerate(cases, 1):
        task_lines.append("        run_case(%s, %s, %s, %d);" %
                          (pack(a, 8), pack(b, 8), pack(expected, 32), index))

    tb = chr(96) + "timescale 1ns/1ps\n" + """
module tb_apu_python_crosscheck;
 logic clk=0, rst=0, start=0;
 logic [127:0] a_matrix='0, b_matrix='0;
 logic busy, done;
 logic [511:0] c_matrix;
 integer cycles;
 apu_matrix_controller dut(.clk(clk),.rst(rst),.start(start),
  .a_matrix(a_matrix),.b_matrix(b_matrix),.busy(busy),.done(done),.c_matrix(c_matrix));
 always #5 clk=~clk;
 task automatic run_case(input logic [127:0] a_in, input logic [127:0] b_in,
  input logic [511:0] expected, input integer case_id);
  begin
   @(negedge clk); a_matrix=a_in; b_matrix=b_in; start=1;
   @(posedge clk); #1; cycles=1;
   @(negedge clk); start=0;
   while(!done && cycles<12) begin @(posedge clk); #1; cycles=cycles+1; end
   if(!done) $fatal(1,"timeout case %0d",case_id);
   if(cycles!=7) $fatal(1,"latency case %0d got %0d",case_id,cycles);
   if(c_matrix !== expected) $fatal(1,"Python/RTL mismatch case %0d got %h expected %h",case_id,c_matrix,expected);
   $display("PASS Python/RTL matrix %0d",case_id);
  end
 endtask
 initial begin
  rst=1; repeat(2) @(posedge clk); #1 rst=0;
""" + "\n".join(task_lines) + """
  $display("PASS: all Python/SystemVerilog cross-checks");
  $finish;
 end
endmodule
"""

    with tempfile.TemporaryDirectory(prefix="apu_v02_") as tmp:
        tmpdir = Path(tmp)
        tb_path = tmpdir / "tb_apu_python_crosscheck.sv"
        exe_path = tmpdir / "apu_crosscheck"
        tb_path.write_text(tb, encoding="utf-8")
        compile_cmd = [
            "iverilog", "-g2012", "-o", str(exe_path),
            str(ROOT / "rtl/apu_systolic_array_4x4.sv"),
            str(ROOT / "rtl/apu_matrix_controller.sv"),
            str(tb_path),
        ]
        subprocess.run(compile_cmd, check=True, cwd=ROOT)
        run = subprocess.run(["vvp", str(exe_path)], check=True, cwd=ROOT,
                             text=True, capture_output=True)
        print(run.stdout, end="")

if __name__ == "__main__":
    main()
