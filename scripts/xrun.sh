#!/bin/bash

# Color variables
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
clear='\033[0m'  # Clear the color after that


# Set current directory
GIT_ROOT=$(git rev-parse --show-toplevel)

# Define output directory (run this script from the build/ folder)
cd "$GIT_ROOT/build" || exit 1

# Check if clean is requested
check_clean() {
    find ./ -type f ! -name '*.md' ! -name '*.wcfg' -exec rm -f {} +
    echo "Cleaned all files in build directory except *.md and *.wcfg"
}

# Check if help is requested
check_help() {
    echo "Usage: xrun.sh [options]"
    echo ""
    echo "Options:"
    echo "  --t|-top <top_name>              Specify the top module name"
    echo "  --N|-name_of_test <test_name>    Specify the test name (default: adder_basic_test)"
    echo "  --h|help                         Display this help message"
    echo "  --c|-clean                       Clean build"
    echo "  --v|-vivado <\"--vivado_params\">  Pass Vivado parameters"
    echo ""
    echo "Use -v \"--R\" to run all, --v \"--g\" to gui, and --v \"--g -view top_sim.wcfg\" to load waveforms"
    exit 0
}


# Display usage information
display_usage() {
    echo "../bin/xrun.sh  -t adder_tb_top --n adder_basic_test --c -v \"--g -view adder_tb_top_sim.wcfg\" "
}

# Display error message and exit
error_exit() {
    echo -e "${red}ERROR: $1${clear}"
    exit 1
}


# Parse parameters using getopts
parse_params() {
    # Set default value for TEST_NAME
    TEST_NAME="adder_basic_test"  

    options=$(getopt -a --longoptions help,clean,top:,name_of_test:,vivado: -n "xrun" -- ${0} "${@}")
    eval set -- "$options"
    while true; do
        echo "$1"
        case "$1" in
            --top)
                shift
                TOP_NAME="$1"
                echo "$1"
                ;;
            --name_of_test)
                shift
                TEST_NAME="$1"
                echo "$1"
                ;;
            --clean)
                check_clean
                ;;
            --help)
                check_help
                ;;
            --vivado)
                shift
                VIVADO_PARMS="$1"
                echo "INFO: Parameters ${1} is being passed direct to Vivado"
                ;;
            --)
                shift
                break
                ;;
            *)
                error_exit "Option '${1}' requires an argument"
                ;;
        esac
        shift
    done
}

# Main script execution
main() {
    parse_params "$@"
    display_usage

    # Check if the first parameter is provided
    if [ -z "$1" ]; then
        error_exit "No testbench name provided!"
    fi

    # Check if TOP_NAME is set
    if [ -z "$TOP_NAME" ]; then
        error_exit "No top name provided!"
    fi

    # Gera o AXI SmartConnect usando Vivado em modo batch
    echo "Generating AXI SmartConnect..."
    vivado -mode batch -source ../scripts/generate_smartconnect.tcl -notrace -nojournal -nolog

    # Verifica se a geração foi bem-sucedida
    if [ $? -ne 0 ]; then
        error_exit "Failed to generate AXI SmartConnect!"
    fi

    IP_DIR="../build/sim_output/xsim"
    # set xvlog options
    xvlog_opts="--incr --relax  -L uvm -L axi_vip_v1_1_17 -L smartconnect_v1_0 -L xilinx_vip"
    # set xvhdl options
    xvhdl_opts="--incr --relax "


    # Compila bibliotecas do IP (netlist pré-compilada)
    if [ -f "${IP_DIR}/smartconnect_bd_wrapper.sh" ]; then
        echo "Compiling IP simulation libraries..."
        xvlog $xvlog_opts -prj ${IP_DIR}/vlog.prj 2>&1 | tee compile.log
        xvhdl $xvhdl_opts -prj ${IP_DIR}/vhdl.prj 2>&1 | tee compile.log

        if [ $? -ne 0 ]; then
            error_exit "Failed to compile IP simulation"
        fi
    else
        error_exit "IP simulation script not found at ${IP_DIR}/smartconnect_bd_wrapper.sh"
    fi

    #echo ${CURRENT_DIR}
    # Generate source list path
    list=$(../scripts/srclist2path.sh "../srclist/${TOP_NAME}.srclist" 2>/dev/null)
    echo "${list}"
    # Run simulation
    # Linha xvlog incluindo os arquivos
    xvlog -L uvm -sv \
        "${XILINX_VIVADO}/data/system_verilog/uvm_1.2/uvm_macros.svh" \
        ${list} \
        -i "${XILINX_VIVADO}/data/verilog/src/unisims" \
        -i "${XILINX_VIVADO}/data/verilog/src/unimacro"


    #xelab ${TOP_NAME} --timescale 1ns/1ps -L uvm -L xil_defaultlib  -s top_sim --debug typical --mt 16 --incr
    xelab ${TOP_NAME} xil_defaultlib.glbl \
    --timescale 1ns/1ps \
    -L uvm \
    -L xil_defaultlib \
    -L axi_infrastructure_v1_1_0 \
    -L smartconnect_v1_0 \
    -L lib_cdc_v1_0_3 \
    -L proc_sys_reset_v5_0_15 \
    -L xlconstant_v1_1_9 \
    -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -L xpm \
    -s top_sim --debug typical --mt 16 --incr

    export tb_file="${TOP_NAME}"
    if [[ " ${@:2} " =~ " --g " ]] || [[ "${@:2} " =~ " --gui" ]]; then
        export RUN_GUI=1  # Enable GUI mode
    else
        export RUN_GUI=0  # Disable GUI mode (run in batch mode)
    fi

    xsim top_sim ${VIVADO_PARMS} --testplusarg UVM_TESTNAME=${TEST_NAME} --tclbatch ../scripts/save_wave.tcl
}

main "$@"