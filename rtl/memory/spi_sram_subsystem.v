module spi_sram_subsystem (
    input         sys_clk,
    input         spi_sck,
    input         spi_cs,
    input         spi_mosi,
    output        spi_miso
);

    // Internal interconnect wires
    wire [15:0] w_sAddress;
    wire        w_sCSn, w_sOEn, w_sWRn, w_sDqDir;
    wire [7:0]  w_sDqOut, w_sDqIn;

    // Control signals
    wire w_sram_sel   = ~w_sCSn;
    wire w_sram_rwbar = ~w_sWRn ? 1'b0 : 1'b1;

    // Byte lane decoding based on LSB of SPI address
    wire w_lane0 = ~w_sAddress[0]; // Even address -> Low byte
    wire w_lane1 =  w_sAddress[0]; // Odd address  -> High byte

    // 16-bit read data multiplexer (selects high or low byte to return to SPI)
    wire [15:0] w_sram_read_data;
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
    // w_sAddress[11:1] selects the 2K word entry
    sram u_sram_block (
        .clk        (sys_clk),
        .rwbar      (w_sram_rwbar),
        .sel        (w_sram_sel),
        .addr       (w_sAddress[11:1]),          // 11-bit word index
        .lane0      (w_lane0),                   // Enable low byte write
        .lane1      (w_lane1),                   // Enable high byte write
        .write_data ({w_sDqOut, w_sDqOut}),      // Duplicate byte onto both lanes
        .read_data  (w_sram_read_data)           // Full 16-bit word read output
    );

endmodule