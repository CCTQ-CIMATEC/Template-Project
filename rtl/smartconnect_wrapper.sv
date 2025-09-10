// smartconnect_wrapper.sv
`timescale 1ns / 1ps

module smartconnect_wrapper (
    // Clock and Reset
    input logic aclk,
    input logic aresetn,
    
    // AXI Master Interface 0 (from CPU)
    Bus2Master_intf.master s_axi_m0, // This interface is the AXI master
    
    // AXI Master Interface 1 (from custom master IP)
    Bus2Master_intf.master s_axi_m1, // This interface is the AXI master

    // AXI Master Interface 1 (from custom master IP)
    Bus2Master_intf.master s_axi_m2, // This interface is the AXI master
    
    // AXI Slave Interface 0 (to custom slave IP)
    Bus2Master_intf.slave s_axi_s0, // This interface is the AXI slave
    
    // AXI Slave Interface 1 (to custom slave IP)
    Bus2Master_intf.slave s_axi_s1 // This interface is the AXI slave
);

// Instância do wrapper gerado pelo Vivado
smartconnect_bd_wrapper smartconnect_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    
    // Master 0
    .s_axi_m0_awaddr(s_axi_m0.AWADDR),
    .s_axi_m0_awready(s_axi_m0.AWREADY),
    .s_axi_m0_awvalid(s_axi_m0.AWVALID),
    .s_axi_m0_wdata(s_axi_m0.WDATA),
    .s_axi_m0_wready(s_axi_m0.WREADY),
    .s_axi_m0_wvalid(s_axi_m0.WVALID),
    .s_axi_m0_bresp(s_axi_m0.BRESP),
    .s_axi_m0_bvalid(s_axi_m0.BVALID),
    .s_axi_m0_bready(s_axi_m0.BREADY),
    .s_axi_m0_araddr(s_axi_m0.ARADDR),
    .s_axi_m0_arready(s_axi_m0.ARREADY),
    .s_axi_m0_arvalid(s_axi_m0.ARVALID),
    .s_axi_m0_rdata(s_axi_m0.RDATA),
    .s_axi_m0_rresp(s_axi_m0.RRESP),
    .s_axi_m0_rvalid(s_axi_m0.RVALID),
    .s_axi_m0_rready(s_axi_m0.RREADY),

    // Master 1
    .s_axi_m1_awaddr(s_axi_m1.AWADDR),
    .s_axi_m1_awready(s_axi_m1.AWREADY),
    .s_axi_m1_awvalid(s_axi_m1.AWVALID),
    .s_axi_m1_wdata(s_axi_m1.WDATA),
    .s_axi_m1_wready(s_axi_m1.WREADY),
    .s_axi_m1_wvalid(s_axi_m1.WVALID),
    .s_axi_m1_bresp(s_axi_m1.BRESP),
    .s_axi_m1_bvalid(s_axi_m1.BVALID),
    .s_axi_m1_bready(s_axi_m1.BREADY),
    .s_axi_m1_araddr(s_axi_m1.ARADDR),
    .s_axi_m1_arready(s_axi_m1.ARREADY),
    .s_axi_m1_arvalid(s_axi_m1.ARVALID),
    .s_axi_m1_rdata(s_axi_m1.RDATA),
    .s_axi_m1_rresp(s_axi_m1.RRESP),
    .s_axi_m1_rvalid(s_axi_m1.RVALID),
    .s_axi_m1_rready(s_axi_m1.RREADY),

    // Master 2
    .s_axi_m2_awaddr(s_axi_m2.AWADDR),
    .s_axi_m2_awready(s_axi_m2.AWREADY),
    .s_axi_m2_awvalid(s_axi_m2.AWVALID),
    .s_axi_m2_wdata(s_axi_m2.WDATA),
    .s_axi_m2_wready(s_axi_m2.WREADY),
    .s_axi_m2_wvalid(s_axi_m2.WVALID),
    .s_axi_m2_bresp(s_axi_m2.BRESP),
    .s_axi_m2_bvalid(s_axi_m2.BVALID),
    .s_axi_m2_bready(s_axi_m2.BREADY),
    .s_axi_m2_araddr(s_axi_m2.ARADDR),
    .s_axi_m2_arready(s_axi_m2.ARREADY),
    .s_axi_m2_arvalid(s_axi_m2.ARVALID),
    .s_axi_m2_rdata(s_axi_m2.RDATA),
    .s_axi_m2_rresp(s_axi_m2.RRESP),
    .s_axi_m2_rvalid(s_axi_m2.RVALID),
    .s_axi_m2_rready(s_axi_m2.RREADY),

    // Slave 0
    .s_axi_s0_awaddr(s_axi_s0.AWADDR),
    .s_axi_s0_awready(s_axi_s0.AWREADY),
    .s_axi_s0_awvalid(s_axi_s0.AWVALID),
    .s_axi_s0_wdata(s_axi_s0.WDATA),
    .s_axi_s0_wready(s_axi_s0.WREADY),
    .s_axi_s0_wvalid(s_axi_s0.WVALID),
    .s_axi_s0_bresp(s_axi_s0.BRESP),
    .s_axi_s0_bvalid(s_axi_s0.BVALID),
    .s_axi_s0_bready(s_axi_s0.BREADY),
    .s_axi_s0_araddr(s_axi_s0.ARADDR),
    .s_axi_s0_arready(s_axi_s0.ARREADY),
    .s_axi_s0_arvalid(s_axi_s0.ARVALID),
    .s_axi_s0_rdata(s_axi_s0.RDATA),
    .s_axi_s0_rresp(s_axi_s0.RRESP),
    .s_axi_s0_rvalid(s_axi_s0.RVALID),
    .s_axi_s0_rready(s_axi_s0.RREADY),
    
    // Slave 1
    .s_axi_s1_awaddr(s_axi_s1.AWADDR),
    .s_axi_s1_awready(s_axi_s1.AWREADY),
    .s_axi_s1_awvalid(s_axi_s1.AWVALID),
    .s_axi_s1_wdata(s_axi_s1.WDATA),
    .s_axi_s1_wready(s_axi_s1.WREADY),
    .s_axi_s1_wvalid(s_axi_s1.WVALID),
    .s_axi_s1_bresp(s_axi_s1.BRESP),
    .s_axi_s1_bvalid(s_axi_s1.BVALID),
    .s_axi_s1_bready(s_axi_s1.BREADY),
    .s_axi_s1_araddr(s_axi_s1.ARADDR),
    .s_axi_s1_arready(s_axi_s1.ARREADY),
    .s_axi_s1_arvalid(s_axi_s1.ARVALID),
    .s_axi_s1_rdata(s_axi_s1.RDATA),
    .s_axi_s1_rresp(s_axi_s1.RRESP),
    .s_axi_s1_rvalid(s_axi_s1.RVALID),
    .s_axi_s1_rready(s_axi_s1.RREADY)
    
);

endmodule