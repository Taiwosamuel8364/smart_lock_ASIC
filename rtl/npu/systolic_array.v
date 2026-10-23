module systolic_array #(
    parameter ARRAY_ROWS = 3,
    parameter ARRAY_COLS = 3,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire                               clr_acc,
    input  wire                               enable,

    // Row-wise input streams for activations (left side of array)
    input  wire [ARRAY_ROWS*DATA_WIDTH-1:0]   ifmap_row_in,

    // Column-wise input streams for weights (top side of array)
    input  wire [ARRAY_COLS*DATA_WIDTH-1:0]   weight_col_in,

    // Flattened 2D array of 32-bit accumulated outputs (ARRAY_ROWS x ARRAY_COLS)
    output wire [ARRAY_ROWS*ARRAY_COLS*ACC_WIDTH-1:0] acc_matrix_out
);

    // 2D Interconnect Wires for Data Forwarding between PEs
    wire [DATA_WIDTH-1:0] ifmap_wire  [0:ARRAY_ROWS-1][0:ARRAY_COLS];
    wire [DATA_WIDTH-1:0] weight_wire [0:ARRAY_ROWS][0:ARRAY_COLS-1];
    wire [ACC_WIDTH-1:0]  acc_wire    [0:ARRAY_ROWS-1][0:ARRAY_COLS-1];

    // Connect Array Inputs to the Outer Wire Boundaries
    genvar r, c;
    generate
        // Connect left-side row inputs
        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin : gen_ifmap_inputs
            assign ifmap_wire[r][0] = ifmap_row_in[(r+1)*DATA_WIDTH-1 -: DATA_WIDTH];
        end

        // Connect top-side column inputs
        for (c = 0; c < ARRAY_COLS; c = c + 1) begin : gen_weight_inputs
            assign weight_wire[0][c] = weight_col_in[(c+1)*DATA_WIDTH-1 -: DATA_WIDTH];
        end
    endgenerate

    // 2D Grid Instantiation using Nested Generate Loops
    generate
        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin : gen_rows
            for (c = 0; c < ARRAY_COLS; c = c + 1) begin : gen_cols
                
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk        (clk),
                    .rst_n      (rst_n),
                    .clr_acc    (clr_acc),
                    .enable     (enable),
                    .ifmap_in   (ifmap_wire[r][c]),      // Input from left
                    .weight_in  (weight_wire[r][c]),     // Input from top
                    .ifmap_out  (ifmap_wire[r][c+1]),    // Forward to right PE
                    .weight_out (weight_wire[r+1][c]),   // Forward to bottom PE
                    .acc_out    (acc_wire[r][c])         // Local 32-bit accumulator
                );

                // Flatten 2D accumulator outputs into 1D output bus
                assign acc_matrix_out[((r*ARRAY_COLS + c)+1)*ACC_WIDTH-1 -: ACC_WIDTH] = acc_wire[r][c];

            end
        end
    endgenerate

endmodule