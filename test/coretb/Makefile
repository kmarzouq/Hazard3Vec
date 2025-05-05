SRC_DIR := ../../hdl
FILE_LIST := vector_coretb.v hazard3_core.v vector_core.v vec_regfile.v vadd32_vv.v vsub_vv.v vmul_vv.v vmulh_vv.v vmulhu_vv.v vdiv_vv.v vdivu_vv.v vec_mask.v
VERILOG_FILES := $(addprefix $(SRC_DIR)/,$(FILE_LIST))
TOP_MODULE := testbench
BUILD_DIR := build
VERILATOR_FLAGS := --trace --binary --top-module $(TOP_MODULE) --relative-includes --Wno-fatal --trace-max-array 1024 -j 0
IV_FLAGS := -s $(TOP_MODULE) -I $(SRC_DIR)/

# Default target
all:
	verilator $(VERILATOR_FLAGS) $(VERILOG_FILES) --Mdir $(BUILD_DIR)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

iverilog:
	iverilog $(IV_FLAGS) $(VERILOG_FILES)

.PHONY: all clean