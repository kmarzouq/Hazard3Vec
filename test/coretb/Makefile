SRC_DIR := ../../hdl
FILE_LIST := vector_coretb.v vector_core.v vec_regfile.v vec/reduction.v vec/vec_int_alu.v vec/vec_int_cmp.v vec/vec_merge.v vec/vec_macc.v vec/vec_mask_logic.v \
	vadd32_vv.v vsub_vv.v vmul_vv.v vmulh_vv.v vmulhu_vv.v vdiv_vv.v vdivu_vv.v \
	vadd32_vx.v vsub_vx.v vmul_vx.v vmulh_vx.v vmulhu_vx.v vdiv_vx.v vdivu_vx.v \
	vwadd_vv.v vwadd_vx.v vwaddu_vv.v vwaddu_vx.v vwsub_vv.v vwsub_vx.v vwsubu_vv.v vwsubu_vx.v \
	vec_mask.v
VERILOG_FILES := $(addprefix $(SRC_DIR)/,$(FILE_LIST))
TOP_MODULE := testbench
BUILD_DIR := build
VERILATOR_FLAGS := --trace --binary --top-module $(TOP_MODULE) --relative-includes --Wno-fatal --trace-max-array 1024 -j 0
IV_FLAGS := -s $(TOP_MODULE) -I $(SRC_DIR)/ -grelative-include -v -i

# Default target
all:
	verilator $(VERILATOR_FLAGS) $(VERILOG_FILES) --Mdir $(BUILD_DIR)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

iverilog:
	iverilog $(IV_FLAGS) $(VERILOG_FILES)

.PHONY: all clean