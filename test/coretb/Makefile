SRC_DIR := ../../hdl
FILE_LIST := vector_coretb.v hazard3_core.v
VERILOG_FILES := $(addprefix $(SRC_DIR)/,$(FILE_LIST))
TOP_MODULE := testbench
BUILD_DIR := build
VERILATOR_FLAGS := --trace --binary --top-module $(TOP_MODULE) --relative-includes +1800-2005ext+vh

# Default target
all:
	verilator $(VERILATOR_FLAGS) $(VERILOG_FILES) --Mdir $(BUILD_DIR)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean