SRCS := ../../common/init.S main.c asm.s
APP  := add
CCFLAGS = -march=rv32imacv_zicsr_zifencei_zba_zbb_zbkb_zbs -O3
AFLAGS = -march=rv32imacv_zicsr_zifencei_zba_zbb_zbkb_zbs
TBEXEC       = ../../tb_verilator/tb
LDSCRIPT     = ../../common/memmap.ld
INCDIR       = ../../common


include ../../common/src_only_app.mk
