.PHONY: test rtl-test

test:
	python3 -m unittest discover -s tests -v

rtl-test:
	iverilog -g2012 -o /tmp/apu_mac_tb rtl/apu_mac.sv tb/tb_apu_mac.sv
	vvp /tmp/apu_mac_tb
