#!/bin/sh

RTL="../rtl/ff_top_lx45.v ../rtl/ff.v ../rtl/ff_top.v \
     ../rtl/m68000.v ../rtl/pokey.v ../rtl/pal.v ../rtl/prom_2b.v \
     ../rtl/coderom16.v ../rtl/coderam.v ../rtl/rom_6lm.v ../rtl/rom_136020_16.v \
     ../rtl/ram_pfram.v ../rtl/ram_moram.v ../rtl/ram_coloram.v \
     ../rtl/nvram.v ../rtl/ram_dp256x8.v ../rtl/ram_256x8.v \
     ../rtl/car_lx45.v ../rtl/scanconvert2_lx45.v ../rtl/ram_dp128kx8.v ../rtl/ds_dac.v"

INC="+incdir+../m68k +incdir+../rtl"

PLI=+loadvpi=../pli/vga/vga.so:vpi_compat_bootstrap

#DEBUG=+define+debug=1

cver +define+SIMULATION=1 $PLI $DEBUG $INC $RTL ff_top_lx45_tb.v xilinx.v
