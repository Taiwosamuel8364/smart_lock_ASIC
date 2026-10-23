module spi_sram_subsystem (
    input         sys_clk,
    input         spi_sck,
    input         spi_cs,
    input         spi_mosi,
    output        spi_miso,
    
    // NPU Direct Interface Ports
    input  [10:0] npu_addr,
    input         npu_ren,
    output [15:0] npu_rdata
);

    // Internal interconnect wires
    wire [15:0] w_sAddress;
    wire        w_sCSn, w_sOEn, w_sWRn, w_sDqDir;
    wire [7:0]  w_sDqOut, w_sDqIn;
    wire [15:0] w_sram_read_data;

    // Active flags
    wire w_spi_active = ~w_sCSn;
    wire w_sram_sel   = w_spi_active | npu_ren;
    wire w_sram_rwbar = w_spi_active ? (~w_sWRn ? 1'b0 : 1'b1) : 1'b1;

    // Address multiplexer
    wire [10:0] w_final_addr = w_spi_active ? w_sAddress[11:1] : npu_addr;

    // Byte lane decoding
    wire w_lane0 = w_spi_active ? ~w_sAddress[0] : 1'b1;
    wire w_lane1 = w_spi_active ?  w_sAddress[0] : 1'b1;

    // Direct output connections
    assign npu_rdata = w_sram_read_data;
    
    // Select byte to send back to SPI bridge without feedback contention
    assign w_sDqIn = w_sAddress[0] ? w_sram_read_data[15:8] : w_sram_read_data[7:0];

    // Instantiate SPI-to-RAM bridge
    spi2ram u_spi2ram_bridge (
        .spi_sck   (spi_sck),
        .spi_cs    (spi_cs),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .sAddress  (w_sAddress),
        .sCSn      (w_sCSn),
        .sOEn      (w_sOEn),
        .sWRn      (w_sWRn),
        .sDqDir    (w_sDqDir),
        .sDqOut    (w_sDqOut),
        .sDqIn     (w_sDqIn)
    );

    // Instantiate 16-bit wide SRAM
    sram u_sram_block (
        .clk        (sys_clk),
        .rwbar      (w_sram_rwbar),
        .sel        (w_sram_sel),
        .addr       (w_final_addr),
        .lane0      (w_lane0),
        .lane1      (w_lane1),
        .write_data ({w_sDqOut, w_sDqOut}),
        .read_data  (w_sram_read_data)
    );

endmodule