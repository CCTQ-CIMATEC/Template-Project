# Makefile for Vivado simulation flow

# ======================
# Variables/Parameters
# ======================
TOP_NAME      ?= adder_tb_top
TEST_NAME     ?= adder_basic_test
VIVADO_PARMS  ?= "--R"
IP_DEPENDENCIES ?=

# ======================
# Variables
# ======================
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

ifndef XILINX_VIVADO
    $(error XILINX_VIVADO is not set. Please run source Vivado settings script)
endif

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

# Generate step for each IP with timestamp
define GEN_TEMPLATE
# file target that actually does the generation and touches the timestamp
$(BUILD_DIR)/.gen_$(1).timestamp:
	@echo
	@echo "### GENERATING IP: $(1) ###"
	@cd $(BUILD_DIR) && \
	vivado -mode batch -source ../scripts/generate_$(1).tcl -notrace -nojournal -nolog || \
	(echo "ERROR: Failed to generate IP $(1)" && exit 1)
	@touch $$@

# phony wrapper that prints SKIPPED if timestamp exists, otherwise triggers generation
.PHONY: generate_$(1)
generate_$(1):
	@if [ -f $(BUILD_DIR)/.gen_$(1).timestamp ]; then \
		echo "### SKIPPED GENERATING IP: $(1) (already up-to-date) ###"; \
	else \
		$(MAKE) --no-print-directory $(BUILD_DIR)/.gen_$(1).timestamp; \
	fi
endef


# ==== Compile step for each IP with timestamp ====
define COMPILE_TEMPLATE
# file target that compiles the IP (depends on the gen timestamp)
$(BUILD_DIR)/.comp_$(1).timestamp: $(BUILD_DIR)/.gen_$(1).timestamp
	@echo
	@echo "### COMPILING IP: $(1) ###"
	@cd $(BUILD_DIR) && \
	xvlog $$(XVLOG_OPTS_$(1)) -prj sim_output_$(1)/xsim/vlog.prj && \
	xvhdl $$(XVHDL_OPTS_$(1)) -prj sim_output_$(1)/xsim/vhdl.prj || \
	(echo "ERROR: Failed to compile IP $(1)" && exit 1)
	@touch $$@

# phony wrapper that prints SKIPPED if compiled already, otherwise triggers compile
.PHONY: compile_$(1)
compile_$(1): generate_$(1)
	@if [ -f $(BUILD_DIR)/.comp_$(1).timestamp ]; then \
		echo "### SKIPPED COMPILING IP: $(1) (already up-to-date) ###"; \
	else \
		$(MAKE) --no-print-directory $(BUILD_DIR)/.comp_$(1).timestamp; \
	fi
endef


# ==== Expand templates for every ip in IP_DEPENDENCIES ====
$(foreach ip,$(IP_DEPENDENCIES),$(eval $(call GEN_TEMPLATE,$(ip))))
$(foreach ip,$(IP_DEPENDENCIES),$(eval $(call COMPILE_TEMPLATE,$(ip))))


# ==== Meta targets ====
.PHONY: generate compile_ip
generate: $(foreach ip,$(IP_DEPENDENCIES),generate_$(ip))
compile_ip: $(foreach ip,$(IP_DEPENDENCIES),compile_$(ip))

# -------------------------
# Core compile and elaborate (timestamp + wrapper)
# -------------------------

# actual file target that compiles core/top sources and touches .comp_core.timestamp
$(BUILD_DIR)/.comp_core.timestamp: $(foreach ip,$(IP_DEPENDENCIES),$(BUILD_DIR)/.comp_$(ip).timestamp)
	@echo
	@echo "### COMPILING CORE/TOP SOURCES ###"
	@cd $(BUILD_DIR) && \
	list=$$(../scripts/srclist2path.sh "../srclist/$(TOP_NAME).srclist" 2>/dev/null); \
	xvlog -L uvm -sv \
		"$(XILINX_VIVADO)/data/system_verilog/uvm_1.2/uvm_macros.svh" $$list \
		-i "$(XILINX_VIVADO)/data/verilog/src/unisims" \
		-i "$(XILINX_VIVADO)/data/verilog/src/unimacro"; \
	touch $@

# phony wrapper for compile (core) that prints SKIPPED if already compiled
.PHONY: compile
compile: compile_ip
	@if [ -f $(BUILD_DIR)/.comp_core.timestamp ]; then \
		echo "### SKIPPED CORE COMPILATION (already up-to-date) ###"; \
	else \
		$(MAKE) --no-print-directory $(BUILD_DIR)/.comp_core.timestamp; \
	fi

# elaborate: file target that runs xelab and touches .elaborate.timestamp
$(BUILD_DIR)/.elaborate.timestamp: $(BUILD_DIR)/.comp_core.timestamp
	@echo
	@echo "### ELABORATING DESIGN ###"
	@cd $(BUILD_DIR) && \
	xelab $(TOP_NAME) --timescale 1ns/1ps \
		${XELAB_OPTS} \
		-s top_sim --debug typical --mt 16 --incr || \
	(echo "ERROR: xelab failed" && exit 1)
	@touch $$@

# phony wrapper for elaborate (prints SKIPPED if already elaborated)
.PHONY: elaborate
elaborate: compile
	@if [ -f $(BUILD_DIR)/.elaborate.timestamp ]; then \
		echo "### SKIPPED ELABORATION (already up-to-date) ###"; \
	else \
		$(MAKE) --no-print-directory $(BUILD_DIR)/.elaborate.timestamp; \
	fi

simulate: elaborate
	@cd $(BUILD_DIR) && \
	@echo
	@echo "### RUNNING SIMULATION ###"
	xsim top_sim $(VIVADO_PARMS) --testplusarg UVM_TESTNAME=$(TEST_NAME) --tclbatch ../scripts/save_wave.tcl

run: simulate

gui:
	@$(MAKE) run VIVADO_PARMS="--gui -view $(TOP_NAME)_sim.wcfg"