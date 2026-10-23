module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  clr_acc,    // Resets accumulator to 0
    input  wire                  enable,     // Enables MAC calculation
    
    // Data Inputs
    input  wire [DATA_WIDTH-1:0] ifmap_in,   // Activation pixel input
    input  wire [DATA_WIDTH-1:0] weight_in,  // Weight parameter input
    
    // Systolic Forwarding Outputs (Pass-through registers)
    output reg  [DATA_WIDTH-1:0] ifmap_out,  // Passes pixel to adjacent PE
    output reg  [DATA_WIDTH-1:0] weight_out, // Passes weight to adjacent PE
    
    // Accumulator Output
    output reg  [ACC_WIDTH-1:0]  acc_out     // 32-bit MAC result
);

    // Intermediate 16-bit multiplication product
    wire signed [15:0] mult_product;
    
    // Signed multiplication of 8-bit inputs
    assign mult_product = $signed(ifmap_in) * $signed(weight_in);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifmap_out  <= {DATA_WIDTH{1'b0}};
            weight_out <= {DATA_WIDTH{1'b0}};
            acc_out    <= {ACC_WIDTH{1'b0}};
        end 
        else begin
            if (clr_acc) begin
                acc_out <= {ACC_WIDTH{1'b0}};
            end
            
            if (enable) begin
                // Forward input values to neighboring PEs on the next clock edge
                ifmap_out  <= ifmap_in;
                weight_out <= weight_in;
                
                // Accumulate Product: acc_out = acc_out + (ifmap * weight)
                acc_out    <= acc_out + mult_product;
            end
        end
    end

endmodule