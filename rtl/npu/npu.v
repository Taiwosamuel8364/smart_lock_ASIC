module npu #(
    parameter ARRAY_ROWS = 3,
    parameter ARRAY_COLS = 3,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire                               start,
    output wire                               done,
    output wire                               busy,

    // SRAM Interface to Memory Subsystem
    output wire [10:0]                        sram_addr,
    output wire                               sram_ren,
    input  wire [15:0]                        sram_rdata,

    // Raw Accumulator Output Matrix
    output wire [ARRAY_ROWS*ARRAY_COLS*ACC_WIDTH-1:0] acc_matrix_out
);

    wire pe_enable;
    wire pe_clr_acc;
    wire [ARRAY_ROWS*DATA_WIDTH-1:0] ifmap_row;
    wire [ARRAY_COLS*DATA_WIDTH-1:0] weight_col;

    // Instantiate Controller
    npu_controller #(
        .ARRAY_ROWS(ARRAY_ROWS),
        .ARRAY_COLS(ARRAY_COLS),
        .DATA_WIDTH(DATA_WIDTH)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),
        .busy(busy),
        .sram_addr(sram_addr),
        .sram_ren(sram_ren),
        .sram_rdata(sram_rdata),
        .pe_enable(pe_enable),
        .pe_clr_acc(pe_clr_acc),
        .ifmap_row_out(ifmap_row),
        .weight_col_out(weight_col)
    );

    // Instantiate 2D Systolic Array
    systolic_array #(
        .ARRAY_ROWS(ARRAY_ROWS),
        .ARRAY_COLS(ARRAY_COLS),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) array_inst (
        .clk(clk),
        .rst_n(rst_n),
        .clr_acc(pe_clr_acc),
        .enable(pe_enable),
        .ifmap_row_in(ifmap_row),
        .weight_col_in(weight_col),
        .acc_matrix_out(acc_matrix_out)
    );

endmodule