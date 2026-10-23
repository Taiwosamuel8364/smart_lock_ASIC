`timescale 1ns / 1ps

module tb_pe;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH  = 32;

    // DUT Signals
    reg                   clk;
    reg                   rst_n;
    reg                   clr_acc;
    reg                   enable;
    reg  [DATA_WIDTH-1:0] ifmap_in;
    reg  [DATA_WIDTH-1:0] weight_in;

    wire [DATA_WIDTH-1:0] ifmap_out;
    wire [DATA_WIDTH-1:0] weight_out;
    wire [ACC_WIDTH-1:0]  acc_out;

    // Instantiate Processing Element (PE)
    pe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .clr_acc(clr_acc),
        .enable(enable),
        .ifmap_in(ifmap_in),
        .weight_in(weight_in),
        .ifmap_out(ifmap_out),
        .weight_out(weight_out),
        .acc_out(acc_out)
    );

    // Clock Generation: 100 MHz (10ns period)
    always #5 clk = ~clk;

    // Stimulus Process
    initial begin
        // Waveform Dumper for GTKWave
        $dumpfile("sim/pe.vcd");
        $dumpvars(0, tb_pe);

        // Initialize Signals
        clk       = 1'b0;
        rst_n     = 1'b0;
        clr_acc   = 1'b0;
        enable    = 1'b0;
        ifmap_in  = 8'sd0;
        weight_in = 8'sd0;

        #20;
        rst_n = 1'b1; // Release reset
        #10;

        $display("\n--- Starting Processing Element (PE) Testbench ---");

        // TEST 1: Single MAC Operation (3 * 4 = 12)
        $display("[TEST 1] Computing 3 * 4...");
        enable    = 1'b1;
        ifmap_in  = 8'sd3;
        weight_in = 8'sd4;
        #10; // Wait for clock edge

        if (acc_out === 32'sd12)
            $display("[PASS] acc_out = %d (Expected: 12)", $signed(acc_out));
        else
            $display("[FAIL] acc_out = %d (Expected: 12)", $signed(acc_out));

        // TEST 2: Accumulate Second Product (12 + (5 * -2) = 2)
        $display("[TEST 2] Accumulating 5 * -2...");
        ifmap_in  = 8'sd5;
        weight_in = -8'sd2;
        #10;

        if (acc_out === 32'sd2)
            $display("[PASS] acc_out = %d (Expected: 2)", $signed(acc_out));
        else
            $display("[FAIL] acc_out = %d (Expected: 2)", $signed(acc_out));

        // TEST 3: Verify Forwarding Registers (systolic output check)
        if (ifmap_out === 8'sd5 && weight_out === -8'sd2)
            $display("[PASS] Systolic outputs correctly forwarded: ifmap_out=%d, weight_out=%d", $signed(ifmap_out), $signed(weight_out));
        else
            $display("[FAIL] Forwarding mismatch: ifmap_out=%d, weight_out=%d", $signed(ifmap_out), $signed(weight_out));

        // TEST 4: Clear Accumulator
        $display("[TEST 4] Asserting clr_acc...");
        clr_acc   = 1'b1;
        ifmap_in  = 8'sd10;
        weight_in = 8'sd10;
        #10;
        clr_acc   = 1'b0;

        if (acc_out === 32'sd0)
            $display("[PASS] Accumulator successfully cleared: acc_out = %d", acc_out);
        else
            $display("[FAIL] Accumulator clear failed: acc_out = %d", acc_out);

        $display("\n--- PE Testbench Completed ---");
        $finish;
    end

endmodule