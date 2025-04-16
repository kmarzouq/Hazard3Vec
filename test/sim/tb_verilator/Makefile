include ../project_paths.mk

TOP       := tb
DOTF      := tb.f
CONFIG    := default
TBEXEC    := $(patsubst %.f,%,$(DOTF))
OPT_V     :=
OPT_F     := -O0

ifneq ($(CONFIG),default)
  TBEXEC := $(TBEXEC)-$(CONFIG)
endif

ifeq ($(OPT_G),1)
	OPT_V = -O3 --x-assign fast --x-initial fast --noassert --flatten
	OPT_F = -O3 -march=native
endif

FILE_LIST := $(shell HDL=$(HDL) $(SCRIPTS)/listfiles $(DOTF))
VINCDIR   := $(shell HDL=$(HDL) $(SCRIPTS)/listfiles -f flati $(DOTF))
BUILD_DIR := build-$(patsubst %.f,%,$(DOTF))
VOBJ_DIR  := $(BUILD_DIR)/obj_dir
VLIB      := $(VOBJ_DIR)/libV$(TOP).a

VERILATOR_ROOT := $(shell verilator --getenv VERILATOR_ROOT)
CXX       := g++
VERILATOR := verilator

CINCLUDE  := $(VOBJ_DIR) $(VERILATOR_ROOT)/include

VERILATOR_CPP := verilated.cpp verilated_threads.cpp verilated_vcd_c.cpp
VERILATOR_OBJ := $(addprefix $(BUILD_DIR)/,$(VERILATOR_CPP:.cpp=.o))

.PHONY: clean all lint vcc vlib

all:  $(TBEXEC)
vcc:  $(BUILD_DIR)/vcc.touch
vlib: $(BUILD_DIR)/vlib.touch

$(BUILD_DIR)/vcc.touch: $(FILE_LIST) $(wildcard *.vh) tb.cpp
	mkdir -p $(VOBJ_DIR)
	$(VERILATOR) --Mdir $(VOBJ_DIR) --cc --top-module $(TOP) $(addprefix -I,$(VINCDIR)) --trace \
	  -DCONFIG_HEADER="\"config_$(CONFIG).vh\"" -Wno-fatal -Wno-pinmissing $(OPT_V) $(FILE_LIST)
	touch $@

# CFG_GCH_IF_CLANG is set as a workaround for a verilator issue with newer GCC
# versions (see: https://github.com/verilator/verilator/issues/4730)
$(BUILD_DIR)/vlib.touch: $(BUILD_DIR)/vcc.touch
	$(MAKE) VERILATOR_ROOT=$(VERILATOR_ROOT)  -C $(VOBJ_DIR) -f V$(TOP).mk
	touch $@

# Rule to build verilator support files in parallel
$(BUILD_DIR)/%.o: $(VERILATOR_ROOT)/include/%.cpp | $(BUILD_DIR)/vlib.touch
	$(CXX) $(OPT_F) $(addprefix -I ,$(CINCLUDE)) -c $< -o $@

# Create build directory
$(BUILD_DIR):
	mkdir -p $@

# Build tb separately
$(BUILD_DIR)/tb.o: tb.cpp | $(BUILD_DIR)/vlib.touch
	$(CXX) $(OPT_F) $(addprefix -D,$(CDEFINES) $(CDEFINES_$(DOTF))) \
	  $(addprefix -I ,$(CINCLUDE)) -c $< -o $@

$(TBEXEC): $(BUILD_DIR)/tb.o $(VERILATOR_OBJ) | $(BUILD_DIR)
	$(CXX) $(OPT_F) -o $@ $^ $(wildcard $(VOBJ_DIR)/*.o) -fuse-ld=gold

clean::
	rm -rf $(BUILD_DIR) $(TBEXEC)

lint:
	$(VERILATOR) --lint-only --top-module $(TOP) $(addprefix -I,$(VINCDIR)) -DCONFIG_HEADER="\"config_$(CONFIG).vh\"" $(FILE_LIST)