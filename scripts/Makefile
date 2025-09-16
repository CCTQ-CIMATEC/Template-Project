# Makefile for Vivado simulation flow

# ======================
# Variables
# ======================
TOP_NAME      ?= adder_tb_top
TEST_NAME     ?= adder_basic_test
VIVADO_PARMS  ?=
IP_DEPENDENCIES ?=

GIT_ROOT      := $(shell git rev-parse --show-toplevel)
BUILD_DIR     := $(GIT_ROOT)/build

# Flags globais
XVLOG_OPTS_BASE := --incr --relax -L uvm
XVHDL_OPTS_BASE := --incr --relax
XELAB_OPTS_BASE := -L uvm -L xil_defaultlib

# Definições específicas de cada IP

XVLOG_OPTS_smartconnect     := --incr --relax -L uvm -L axi_vip_v1_1_17 -L smartconnect_v1_0 -L xilinx_vip
XVHDL_OPTS_smartconnect     := --incr --relax
XELAB_OPTS_smartconnect     := -L axi_infrastructure_v1_1_0 -L smartconnect_v1_0 -L lib_cdc_v1_0_3 -L proc_sys_reset_v5_0_15 -L xlconstant_v1_1_9 -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -L xpm \

# Expansão automática das opções de acordo com IP_DEPENDENCIES
XVLOG_OPTS := $(XVLOG_OPTS_BASE) $(foreach ip,$(IP_DEPENDENCIES),$($(addprefix XVLOG_OPTS_,$(ip))))
XVHDL_OPTS := $(XVHDL_OPTS_BASE) $(foreach ip,$(IP_DEPENDENCIES),$($(addprefix XVHDL_OPTS_,$(ip))))
XELAB_OPTS := $(XELAB_OPTS_BASE) $(foreach ip,$(IP_DEPENDENCIES),$($(addprefix XELAB_OPTS_,$(ip))))

# ======================
# Phony targets
# ======================
.PHONY: all help clean generate compile elaborate simulate run gui

all: run

help:
	@echo "Usage: make [target] [VARIABLES=...]"
	@echo ""
	@echo "Targets:"
	@echo "  clean        - Clean build directory"
	@echo "  generate     - Generate AXI SmartConnect"
	@echo "  compile      - Compile IP simulation libraries"
	@echo "  elaborate    - Elaborate design with xelab"
	@echo "  simulate     - Run simulation in batch mode"
	@echo "  gui          - Run simulation in GUI mode"
	@echo ""
	@echo "Variables:"
	@echo "  TOP_NAME=<top_module>        (default: $(TOP_NAME))"
	@echo "  TEST_NAME=<test_name>        (default: $(TEST_NAME))"
	@echo "  VIVADO_PARMS=\"--g ...\"       (default: none)"


# ======================
# Targets
# ======================

clean:
	@find $(BUILD_DIR) -type f ! -name '*.md' ! -name '*.wcfg' -exec rm -f {} +
	@echo "Cleaned all files in build directory except *.md and *.wcfg"

# ======================
# IP Handling (foreach)
# ======================

# Generate step for each IP
define GEN_TEMPLATE
generate_$(1):
	@echo "Generating IP: $(1)"
	@cd $(BUILD_DIR) && \
	vivado -mode batch -source ../scripts/generate_$(1).tcl -notrace -nojournal -nolog || \
	(echo "ERROR: Failed to generate IP $(1)" && exit 1)
endef

# Compile step for each IP
define COMPILE_TEMPLATE
compile_$(1): generate_$(1)
	@echo "Compiling IP simulation libraries for $(1)..."
	@cd $(BUILD_DIR) && \
	xvlog $$(XVLOG_OPTS_$(1)) -prj sim_output_$(1)/xsim/vlog.prj && \
	xvhdl $$(XVHDL_OPTS_$(1)) -prj sim_output_$(1)/xsim/vhdl.prj || \
	(echo "ERROR: Failed to compile IP $(1)" && exit 1)
endef

# Expand rules for each IP in IP_DEPENDENCIES
$(foreach ip,$(IP_DEPENDENCIES),$(eval $(call GEN_TEMPLATE,$(ip))))
$(foreach ip,$(IP_DEPENDENCIES),$(eval $(call COMPILE_TEMPLATE,$(ip))))

# Meta targets
generate: $(foreach ip,$(IP_DEPENDENCIES),generate_$(ip))
compile_ip: $(foreach ip,$(IP_DEPENDENCIES),compile_$(ip))

# ======================
# Core Simulation Flow
# ======================

compile: compile_ip
	@cd $(BUILD_DIR) && \
	list=$$(../scripts/srclist2path.sh "../srclist/$(TOP_NAME).srclist" 2>/dev/null); \
	xvlog -L uvm -sv \
		"$$XILINX_VIVADO/data/system_verilog/uvm_1.2/uvm_macros.svh" $$list \
		-i "$$XILINX_VIVADO/data/verilog/src/unisims" \
		-i "$$XILINX_VIVADO/data/verilog/src/unimacro"; \

elaborate: compile
	@echo
	@echo "### ELABORATING ###"
	xelab $(TOP_NAME) --timescale 1ns/1ps \
		${XELAB_OPTS} \
		-s top_sim --debug typical --mt 16 --incr

simulate: elaborate
	@cd $(BUILD_DIR) && \
	@echo
	@echo "### RUNNING SIMULATION ###"
	xsim top_sim $(VIVADO_PARMS) --testplusarg UVM_TESTNAME=$(TEST_NAME) --tclbatch ../scripts/save_wave.tcl

run: simulate

gui:
	@$(MAKE) run VIVADO_PARMS="--gui -view $(TOP_NAME)_sim.wcfg"
