SRC_DIR := ../../hdl
FILE_LIST := \
  vector_coretb.v \
  hazard3_core.v \
  vector_core.v \
  vec_regfile.v \
  vec_mask.v \
  vadd32_vv.v \
  vadd32_vx.v \
  vsub_vv.v \
  vsub_vx.v \
  vmul_vv.v \
  vmul_vx.v \
  vmulh_vv.v \
  vmulh_vx.v \
  vmulhu_vv.v \
  vmulhu_vx.v \
  vdiv_vv.v \
  vdiv_vx.v \
  vdivu_vv.v \
  vdivu_vx.v \
  vwaddu_vv.v \
  vwadd_vv.v \
  vwaddu_vx.v \
  vwadd_vx.v \
  vwsubu_vv.v \
  vwsub_vv.v \
  vwsubu_vx.v \
  vwsub_vx.v
VERILOG_FILES := $(addprefix $(SRC_DIR)/,$(FILE_LIST))
TOP_MODULE := testbench
BUILD_DIR := build
VERILATOR_FLAGS := --trace --binary --top-module $(TOP_MODULE) --relative-includes --Wno-fatal --trace-max-array 1024
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