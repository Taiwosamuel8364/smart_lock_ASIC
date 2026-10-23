`timescale 1ns / 1ps

module tb_npu;

    // Clock & System Signals
    reg        sys_clk;
    reg        rst_n;

    // SPI Bus Interface
    reg        spi_sck;
    reg        spi_cs;
    reg        spi_mosi;
    wire       spi_miso;

    // NPU Control Signals
    reg        npu_start;
    wire       npu_done;
    wire       npu_busy;

    // Subsystem Interconnect Wires
    wire [10:0] sram_addr;
    wire        sram_ren;
    wire [15:0] sram_rdata;
    wire [3*3*32-1:0] acc_matrix_out;

    integer i;

    // 1. Instantiate SPI-SRAM Memory Subsystem
    spi_sram_subsystem memory_subsystem_inst (
        .sys_clk   (sys_clk),
        .spi_sck   (spi_sck),
        .spi_cs    (spi_cs),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .npu_addr  (sram_addr),
        .npu_ren   (sram_ren),
        .npu_rdata (sram_rdata)
    );

    // 2. Instantiate Full NPU Core (Controller + Systolic Array)
    npu #(
        .ARRAY_ROWS(3),
        .ARRAY_COLS(3),
        .DATA_WIDTH(8),
        .ACC_WIDTH(32)
    ) npu_core_inst (
        .clk(sys_clk),
        .rst_n(rst_n),
        .start(npu_start),
        .done(npu_done),
        .busy(npu_busy),
        .sram_addr(sram_addr),
        .sram_ren(sram_ren),
        .sram_rdata(sram_rdata),
        .acc_matrix_out(acc_matrix_out)
    );

    // Clock Generation: 50 MHz System Clock
    always #10 sys_clk = ~sys_clk;

    // =========================================================
    // SPI MASTER HELPER TASKS
    // =========================================================
    task send_spi_byte(input [7:0] data_in);
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                spi_mosi = data_in[i];
                #100; spi_sck = 1'b1;
                #100; spi_sck = 1'b0;
            end
        end
    endtask

    task spi_write(input [15:0] addr, input [7:0] data);
        begin
            spi_cs = 1'b0; #50;
            send_spi_byte(8'h02);      // SPI Write Command
            send_spi_byte(addr[15:8]); // Address High
            send_spi_byte(addr[7:0]);  // Address Low
            send_spi_byte(data);       // Payload Byte
            #50; spi_cs = 1'b1; #200;
        end
    endtask

    // =========================================================
    // TEST PROCEDURE
    // =========================================================
    initial begin
        $dumpfile("sim/npu_integration.vcd");
        $dumpvars(0, tb_npu);

        // Signal Initialization
        sys_clk   = 1'b0;
        rst_n     = 1'b0;
        spi_sck   = 1'b0;
        spi_cs    = 1'b1;
        spi_mosi  = 1'b0;
        npu_start = 1'b0;

        #100;
        rst_n = 1'b1; // Release Reset
        #100;

        $display("\n==================================================");
        $display("   NPU + SPI-SRAM Integration Testbench Starting   ");
        $display("==================================================");

        // STEP 1: Pre-load Weights into SRAM over SPI
        $display("\n[STEP 1] Loading Weights into SRAM via SPI...");
        spi_write(16'h0000, 8'h02); // Weight 0
        spi_write(16'h0001, 8'h03); // Weight 1
        spi_write(16'h0002, 8'h04); // Weight 2

        // STEP 2: Pre-load IFMAP Pixels into SRAM over SPI
        $display("[STEP 2] Loading IFMAP Pixels into SRAM via SPI...");
        
        // SRAM Word 008 (SPI 0x0010 & 0x0011)
        spi_write(16'h0010, 8'd3);  
        spi_write(16'h0011, 8'd4);  

        // SRAM Word 009 (SPI 0x0012 & 0x0013)
        spi_write(16'h0012, 8'd2);  
        spi_write(16'h0013, 8'd5);  

        // SRAM Word 00A (SPI 0x0014 & 0x0015)
        spi_write(16'h0014, 8'd6);  
        spi_write(16'h0015, 8'd1);  

        // SRAM Word 00B (SPI 0x0016 & 0x0017)
        spi_write(16'h0016, 8'd4);  
        spi_write(16'h0017, 8'd2);
        
        // STEP 3: Trigger NPU Execution
        $display("\n[STEP 3] Triggering NPU Start Pulse...");
        #50;
        npu_start = 1'b1;
        #20;
        npu_start = 1'b0;

        // STEP 4: Wait for NPU Execution Completion
        $display("[STEP 4] Waiting for NPU 'done' pulse...");
        wait(npu_done == 1'b1);
        #20;

        $display("\n[SUCCESS] NPU Execution Completed!");
        $display("--------------------------------------------------");
        $display("Accumulator Matrix Output (PE Results):");
        $display("  PE(0,0): %d", $signed(acc_matrix_out[31:0]));
        $display("  PE(1,1): %d", $signed(acc_matrix_out[4*32 +: 32]));
        $display("  PE(2,2): %d", $signed(acc_matrix_out[8*32 +: 32]));
        $display("==================================================\n");

        $finish;
    end

endmodule