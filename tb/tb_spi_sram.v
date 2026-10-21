`timescale 1ns / 1ps

module tb_spi_sram;

    // System Signals
    reg        sys_clk;
    
    // SPI Bus Signals
    reg        spi_sck;
    reg        spi_cs;
    reg        spi_mosi;
    wire       spi_miso;

    // Simulation variables
    reg  [7:0] rx_data;
    integer    i;

    // Instantiate Top-Level SPI-SRAM Subsystem
    spi_sram_subsystem uut (
        .sys_clk  (sys_clk),
        .spi_sck  (spi_sck),
        .spi_cs   (spi_cs),
        .spi_mosi (spi_mosi),
        .spi_miso (spi_miso)
    );

    // Clock Generation: 50 MHz System Clock (20ns period)
    always #10 sys_clk = ~sys_clk;

    // =========================================================
    // SPI MASTER TASKS
    // =========================================================
    
    // Task to send a single byte over MOSI (SPI Mode 0)
    task send_spi_byte(input [7:0] data_in);
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                spi_mosi = data_in[i];
                #100; spi_sck = 1'b1;  // posedge SCK (sampling)
                #100; spi_sck = 1'b0;  // negedge SCK (shifting)
            end
        end
    endtask

    // Task to receive a single byte from MISO
    task receive_spi_byte(output [7:0] data_out);
        begin
            data_out = 8'h00;
            for (i = 7; i >= 0; i = i - 1) begin
                spi_mosi = 1'b0;        // Dummy MOSI line
                #100; spi_sck = 1'b1;   // Slave presents data on MISO
                data_out[i] = spi_miso; // Sample MISO bit
                #100; spi_sck = 1'b0;
            end
        end
    endtask

    // High-Level Task: Perform Full SPI Write (Cmd 0x02 + Addr + Data)
    task spi_write(input [15:0] addr, input [7:0] data);
        begin
            spi_cs = 1'b0; #50;              // Assert Chip Select
            send_spi_byte(8'h02);            // Write Command
            send_spi_byte(addr[15:8]);       // Address High
            send_spi_byte(addr[7:0]);        // Address Low
            send_spi_byte(data);             // Payload Data Byte
            #50; spi_cs = 1'b1; #200;        // Deassert Chip Select
        end
    endtask

    // High-Level Task: Perform Full SPI Read (Cmd 0x03 + Addr -> Read Data)
    task spi_read(input [15:0] addr, output [7:0] data);
        begin
            spi_cs = 1'b0; #50;              // Assert Chip Select
            send_spi_byte(8'h03);            // Read Command
            send_spi_byte(addr[15:8]);       // Address High
            send_spi_byte(addr[7:0]);        // Address Low
            receive_spi_byte(data);          // Receive Payload Byte
            #50; spi_cs = 1'b1; #200;        // Deassert Chip Select
        end
    endtask

    // STIMULUS PROCESS
    initial begin
        // Waveform Dumper for Icarus Verilog / GTKWave
        $dumpfile("sim/spi_sram.vcd");
        $dumpvars(0, tb_spi_sram);

        // Initialize Lines
        sys_clk  = 1'b0;
        spi_sck  = 1'b0;
        spi_cs   = 1'b1;
        spi_mosi = 1'b0;
        #200;

        $display("\n--- Starting SPI-SRAM Subsystem Testbench ---");

        // TEST 1: Write Byte 0xA5 to Address 0x0010
        $display("[TEST 1] Writing 0xA5 to SRAM Address 0x0010 over SPI...");
        spi_write(16'h0010, 8'hA5);

        // TEST 2: Read Byte back from Address 0x0010
        $display("[TEST 2] Reading back from SRAM Address 0x0010 over SPI...");
        spi_read(16'h0010, rx_data);
        
        // Verification Check
        if (rx_data === 8'hA5) begin
            $display("[SUCCESS] Received matching data: 0x%X", rx_data);
        end else begin
            $display("[FAIL] Expected 0xA5, but got: 0x%X", rx_data);
        end

        // TEST 3: Write Byte 0x3C to Address 0x002A
        $display("\n[TEST 3] Writing 0x3C to SRAM Address 0x002A over SPI...");
        spi_write(16'h002A, 8'h3C);

        // TEST 4: Read Byte back from Address 0x002A
        $display("[TEST 4] Reading back from SRAM Address 0x002A over SPI...");
        spi_read(16'h002A, rx_data);

        // Verification Check
        if (rx_data === 8'h3C) begin
            $display("[SUCCESS] Received matching data: 0x%X\n", rx_data);
        end else begin
            $display("[FAIL] Expected 0x3C, but got: 0x%X\n", rx_data);
        end

        $display("--- SPI-SRAM Testbench Completed ---");
        $finish;
    end

endmodule