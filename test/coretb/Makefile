SRC_DIR := ../../hdl
FILE_LIST := vector_coretb.v hazard3_core.v vector_core.v vec_regfile.v
VERILOG_FILES := $(addprefix $(SRC_DIR)/,$(FILE_LIST))
TOP_MODULE := testbench
BUILD_DIR := build
VERILATOR_FLAGS := --trace --binary --top-module $(TOP_MODULE) --relative-includes

# Default target
all:
	verilator $(VERILATOR_FLAGS) $(VERILOG_FILES) --Mdir $(BUILD_DIR)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean