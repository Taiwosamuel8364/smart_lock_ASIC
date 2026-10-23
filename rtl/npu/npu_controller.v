module npu_controller #(
    parameter ARRAY_ROWS = 3,
    parameter ARRAY_COLS = 3,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 11
)(
    input  wire                  clk,
    input  wire                  rst_n,
    
    // Control Signals from SOC
    input  wire                  start,
    output reg                   done,
    output reg                   busy,

    // SRAM Interface
    output reg  [ADDR_WIDTH-1:0] sram_addr,
    output reg                   sram_ren,
    input  wire [15:0]           sram_rdata,

    // Systolic Array Control Output
    output reg                   pe_enable,
    output reg                   pe_clr_acc,
    output reg  [ARRAY_ROWS*DATA_WIDTH-1:0] ifmap_row_out,
    output reg  [ARRAY_COLS*DATA_WIDTH-1:0] weight_col_out
);

    // FSM States
    localparam STATE_IDLE      = 2'b00;
    localparam STATE_FETCH_WT  = 2'b01;
    localparam STATE_EXEC_CONV = 2'b10;
    localparam STATE_DONE      = 2'b11;

    reg [1:0] current_state, next_state;
    reg [3:0] step_counter;
    reg       sram_rdata_valid;

    // Internal Weight Buffer
    reg [ARRAY_COLS*DATA_WIDTH-1:0] weight_buffer;

    // Zero-extended 11-bit index to prevent 'x' evaluation
    wire [ADDR_WIDTH-1:0] step_ext = {7'b0, step_counter};

    // 1. Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state    <= STATE_IDLE;
            step_counter     <= 4'd0;
            sram_rdata_valid <= 1'b0;
            weight_buffer    <= {ARRAY_COLS*DATA_WIDTH{1'b0}};
        end else begin
            current_state    <= next_state;
            sram_rdata_valid <= sram_ren; // 1-cycle latency pipeline alignment

            if (current_state == STATE_EXEC_CONV || current_state == STATE_FETCH_WT)
                step_counter <= step_counter + 1'b1;
            else
                step_counter <= 4'd0;

            // Latch pre-fetched weight from SRAM into internal buffer
            if (current_state == STATE_FETCH_WT && sram_rdata_valid) begin
                weight_buffer <= {sram_rdata[7:0], sram_rdata[15:8], sram_rdata[7:0]};
            end
        end
    end

    // 2. Combinational Output & Next-State Logic
    always @(*) begin
        next_state    = current_state;
        done          = 1'b0;
        busy          = 1'b1;
        pe_clr_acc    = 1'b0;
        sram_ren      = 1'b0;
        sram_addr     = {ADDR_WIDTH{1'b0}};
        ifmap_row_out = {ARRAY_ROWS*DATA_WIDTH{1'b0}};
        
        weight_col_out = weight_buffer;
        pe_enable      = (current_state == STATE_EXEC_CONV) && sram_rdata_valid;

        case (current_state)
            STATE_IDLE: begin
                busy = 1'b0;
                if (start) begin
                    pe_clr_acc = 1'b1;
                    next_state = STATE_FETCH_WT;
                end
            end

            STATE_FETCH_WT: begin
                sram_ren  = 1'b1;
                sram_addr = 11'h000 + step_ext;
                if (step_counter == 4'd2)
                    next_state = STATE_EXEC_CONV;
            end

            STATE_EXEC_CONV: begin
                sram_ren  = 1'b1;
                sram_addr = 11'h008 + step_ext;

                if (sram_rdata_valid) begin
                    // Extract low and high bytes from SRAM 16-bit word
                    ifmap_row_out = {sram_rdata[7:0], sram_rdata[15:8], sram_rdata[7:0]};
                end

                if (step_counter == 4'd10) // Allow full array propagation
                    next_state = STATE_DONE;
            end

            STATE_DONE: begin
                done       = 1'b1;
                busy       = 1'b0;
                next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

endmodule