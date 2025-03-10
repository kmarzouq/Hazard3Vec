SRC_DIR := ../../hdl/vec
FILE_LIST := bitwise.v bitwise_tb.v
VERILOG_FILES := $(addprefix $(SRC_DIR)/,$(FILE_LIST))
TOP_MODULE := bitwise_tb
BUILD_DIR := build
VERILATOR_FLAGS := --trace --binary --top-module $(TOP_MODULE) --trace-max-array 64 --timing

# Default target
all:
	verilator $(VERILATOR_FLAGS) $(VERILOG_FILES) --Mdir $(BUILD_DIR)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

iverilog:
	iverilog -s bitwise_tb $(SRC_DIR)/bitwise_tb.v $(SRC_DIR)/bitwise.v

.PHONY: all clean iverilog