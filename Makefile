.PHONY: test rtl-test overflow-test crosscheck all

test:
	python3 -m unittest discover -s tests -v

rtl-test:
	iverilog -g2012 -o /tmp/apu_v02_tb rtl/apu_systolic_array_4x4.sv rtl/apu_matrix_controller.sv tb/tb_apu_gemm4x4.sv
	vvp /tmp/apu_v02_tb

overflow-test:
	iverilog -g2012 -o /tmp/apu_overflow_tb rtl/apu_systolic_array_4x4.sv tb/tb_apu_overflow.sv
	vvp /tmp/apu_overflow_tb

crosscheck:
	python3 tests/run_python_rtl_crosscheck.py

all: test rtl-test overflow-test crosscheck
