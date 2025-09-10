module ip_tb;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter CLK_PERIOD = 10; // 100 MHz

    logic clk;
    logic rst_n;

    // AXI4-Lite Interface instance
    Bus2Master_intf #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) s_axi4_lite (
        .ACLK(clk),
        .ARESETN(rst_n)
    );

    // DUT instantiation
    template_project #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_cpu(s_axi4_lite)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset Generation
    initial begin
        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
    end

    // AXI4-Lite Write Task
    task automatic axi4_lite_write(
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data,
        input [(DATA_WIDTH/8)-1:0] strb
    );
        begin
            // Write Address
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.AWADDR  <= addr;
            s_axi4_lite.master_cb.AWVALID <= 1'b1;
            s_axi4_lite.master_cb.AWPROT  <= 3'b000;

            // Write Data
            s_axi4_lite.master_cb.WDATA   <= data;
            s_axi4_lite.master_cb.WSTRB   <= strb;
            s_axi4_lite.master_cb.WVALID  <= 1'b1;

            // Write Response
            s_axi4_lite.master_cb.BREADY  <= 1'b1;

            // Wait handshake
            while (!(s_axi4_lite.master_cb.AWREADY && s_axi4_lite.master_cb.WREADY))
                @(s_axi4_lite.master_cb);

            // Deassert after handshake
            s_axi4_lite.master_cb.AWVALID <= 1'b0;
            s_axi4_lite.master_cb.WVALID  <= 1'b0;

            // Wait response
            while (!s_axi4_lite.master_cb.BVALID)
                @(s_axi4_lite.master_cb);

            $display("[%0t] WRITE: Addr=0x%h, Data=0x%h, BRESP=0x%h",
                     $time, addr, data, s_axi4_lite.master_cb.BRESP);

            s_axi4_lite.master_cb.BREADY <= 1'b0;
        end
    endtask

    // AXI4-Lite Read Task
    task automatic axi4_lite_read(
        input [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data
    );
        begin
            // Read Address
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.ARADDR  <= addr;
            s_axi4_lite.master_cb.ARVALID <= 1'b1;
            s_axi4_lite.master_cb.ARPROT  <= 3'b000;
            s_axi4_lite.master_cb.RREADY  <= 1'b1;

            // Wait handshake
            while (!s_axi4_lite.master_cb.ARREADY)
                @(s_axi4_lite.master_cb);

            s_axi4_lite.master_cb.ARVALID <= 1'b0;

            // Wait data
            while (!s_axi4_lite.master_cb.RVALID)
                @(s_axi4_lite.master_cb);

            data = s_axi4_lite.master_cb.RDATA;

            $display("[%0t] READ: Addr=0x%h, Data=0x%h, RRESP=0x%h",
                     $time, addr, data, s_axi4_lite.master_cb.RRESP);

            s_axi4_lite.master_cb.RREADY <= 1'b0;
        end
    endtask

    // Test Sequence
    initial begin
        logic [DATA_WIDTH-1:0] read_data;

        // Initialize interface
        s_axi4_lite.master_cb.AWADDR  <= '0;
        s_axi4_lite.master_cb.AWVALID <= 1'b0;
        s_axi4_lite.master_cb.WDATA   <= '0;
        s_axi4_lite.master_cb.WSTRB   <= '0;
        s_axi4_lite.master_cb.WVALID  <= 1'b0;
        s_axi4_lite.master_cb.BREADY  <= 1'b0;
        s_axi4_lite.master_cb.ARADDR  <= '0;
        s_axi4_lite.master_cb.ARVALID <= 1'b0;
        s_axi4_lite.master_cb.RREADY  <= 1'b0;

        wait(rst_n == 1);
        #(CLK_PERIOD * 2);

        $display("==========================================");
        $display("Starting template_project AXI4-Lite Testbench");
        $display("==========================================");

        // Example write
        axi4_lite_write(32'h00000004, 32'hDEADBEEF, 4'hF);

        // Example read
        axi4_lite_read(32'h00000004, read_data);

        $display("Read back value: 0x%h", read_data);

        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule
