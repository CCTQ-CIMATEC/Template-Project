module template_project #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst_n,
    Bus2Master_intf s_axi_cpu
);
    
    // Hardware Interface
    CSR_IP_Map__in_t  hwif_in;
    CSR_IP_Map__out_t hwif_out;
    
    Bus2Master_intf #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) s_axi_ctrl_read_write (
        .ACLK(clk),
        .ARESETN(rst_n)
    );

    Bus2Master_intf #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) s_axi_regmap (
        .ACLK(clk),
        .ARESETN(rst_n)
    );

    Bus2Master_intf #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) s_axi_regbank_target (
        .ACLK(clk),
        .ARESETN(rst_n)
    );

    Bus2Master_intf #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) s_axi_regbank_source (
        .ACLK(clk),
        .ARESETN(rst_n)
    );

    axi4lite_csr_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) regmap (
        .clk(clk),
        .rst(rst_n),
        
        // APB4 Interface
        .axi4lite2Master_intf(s_axi_regmap.slave),
        
        // Hardware Interface
        .hwif_in(hwif_in),
        .hwif_out(hwif_out)
    );

    regbank #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) rb_source (
        .clk(clk),
        .rst(rst_n),
        
        // APB4 Interface
        .axi4lite2Master_intf(s_axi_regbank_source.slave)
    );

    regbank #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) rb_target (
        .clk(clk),
        .rst(rst_n),
        
        // APB4 Interface
        .axi4lite2Master_intf(s_axi_regbank_target.slave)
    );

    bus_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ctrl_read_write (
        .clk(clk),
        .rst(rst_n),
        
        // APB4 Interface
        .axi4lite2Master_intf(s_axi_ctrl_read_write.master)
    );

    smartconnect_wrapper smartconnect_wrapper_inst (
        .aclk(clk),
        .aresetn(rst_n),
        .s_axi_m0(s_axi_regmap),
        .s_axi_m1(s_axi_regbank_target),
        .s_axi_m2(s_axi_regbank_source),
        .s_axi_s0(s_axi_cpu),
        .s_axi_s1(s_axi_ctrl_read_write)
    );


endmodule