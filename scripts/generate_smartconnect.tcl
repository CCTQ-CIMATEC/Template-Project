# generate_smartconnect_sv.tcl
set project_name "axi_smartconnect_wrapper_sv"
set part "xczu7ev-ffvc1156-2-e"

# Criar projeto temporário
create_project -force $project_name ./$project_name -part $part
set_property target_language Verilog [current_project]  # Para SystemVerilog

# Criar block design
create_bd_design "smartconnect_bd"

# Adicionar SmartConnect
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smartconnect_0

# Configurar SmartConnect para 2 masters e 3 slaves
set_property -dict [list \
    CONFIG.NUM_SI {2} \
    CONFIG.NUM_MI {3} \
    CONFIG.HAS_ARESETN {1} \
] [get_bd_cells axi_smartconnect_0]

# Criar portas externas para clock e reset
create_bd_port -dir I -type clk aclk
create_bd_port -dir I -type rst aresetn

# Conectar clock e reset
connect_bd_net [get_bd_ports aclk] [get_bd_pins axi_smartconnect_0/aclk]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins axi_smartconnect_0/aresetn]

# Criar portas externas para os masters
for {set i 0} {$i < 2} {incr i} {
    create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_m${i}
    set_property -dict [list \
        CONFIG.PROTOCOL AXI4LITE \
        CONFIG.ADDR_WIDTH {32} \
        CONFIG.DATA_WIDTH {32} \
    ] [get_bd_intf_ports s_axi_m${i}]
    connect_bd_intf_net [get_bd_intf_ports s_axi_m${i}] [get_bd_intf_pins axi_smartconnect_0/S0${i}_AXI]
}

# Criar portas externas para os slaves
for {set i 0} {$i < 3} {incr i} {
    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s${i}
    set_property -dict [list \
        CONFIG.PROTOCOL AXI4LITE \
        CONFIG.ADDR_WIDTH {32} \
        CONFIG.DATA_WIDTH {32} \
    ] [get_bd_intf_ports m_axi_s${i}]
    connect_bd_intf_net [get_bd_intf_ports m_axi_s${i}] [get_bd_intf_pins axi_smartconnect_0/M0${i}_AXI]
}

# Validar design
validate_bd_design

# Gerar wrapper HDL
make_wrapper -files [get_files ./$project_name/$project_name.srcs/sources_1/bd/smartconnect_bd/smartconnect_bd.bd] -top
add_files -norecurse ./$project_name/$project_name.srcs/sources_1/bd/smartconnect_bd/hdl/smartconnect_bd_wrapper.v

# Gerar produtos de saída
generate_target all [get_files ./$project_name/$project_name.srcs/sources_1/bd/smartconnect_bd/smartconnect_bd.bd]

# Fechar projeto
close_project