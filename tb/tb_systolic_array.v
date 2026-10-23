`timescale 1ns / 1ps

module tb_systolic_array;

    localparam ROWS       = 3;
    localparam COLS       = 3;
    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH  = 32;

    reg                                clk;
    reg                                rst_n;
    reg                                clr_acc;
    reg                                enable;
    reg  [ROWS*DATA_WIDTH-1:0]         ifmap_row_in;
    reg  [COLS*DATA_WIDTH-1:0]         weight_col_in;
    wire [ROWS*COLS*ACC_WIDTH-1:0]     acc_matrix_out;

    // Instantiate 3x3 Systolic Array
    systolic_array #(
        .ARRAY_ROWS(ROWS),
        .ARRAY_COLS(COLS),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .clr_acc(clr_acc),
        .enable(enable),
        .ifmap_row_in(ifmap_row_in),
        .weight_col_in(weight_col_in),
        .acc_matrix_out(acc_matrix_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);

        clk           = 1'b0;
        rst_n         = 1'b0;
        clr_acc       = 1'b0;
        enable        = 1'b0;
        ifmap_row_in  = 0;
        weight_col_in = 0;

        #20; rst_n = 1'b1; #10;

        $display("\n--- Starting 3x3 Systolic Array Testbench ---");

        // Drive inputs across 3 rows and 3 columns
        // Rows (ifmaps): Row2 = 3, Row1 = 2, Row0 = 1
        // Cols (weights): Col2 = 6, Col1 = 5, Col0 = 4
        enable        = 1'b1;
        ifmap_row_in  = {8'sd3, 8'sd2, 8'sd1};
        weight_col_in = {8'sd6, 8'sd5, 8'sd4};
        #10;

        $display("PE(0,0) [Expected 1*4=4]:  %d", $signed(acc_matrix_out[0*ACC_WIDTH +: ACC_WIDTH]));
        $display("PE(1,1) [Expected 2*5=10]: %d", $signed(acc_matrix_out[4*ACC_WIDTH +: ACC_WIDTH]));
        $display("PE(2,2) [Expected 3*6=18]: %d", $signed(acc_matrix_out[8*ACC_WIDTH +: ACC_WIDTH]));

        $display("\n--- Systolic Array Simulation Complete ---");
        $finish;
    end

endmodule