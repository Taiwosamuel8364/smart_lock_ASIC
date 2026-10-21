module sram (
    input             clk,
    input             rwbar,       // 0 = Write, 1 = Read
    input             sel,         // Chip Select
    input      [10:0] addr,        // 11 bits = 2048 entries (2047:0)
    input             lane0,       // Low byte enable
    input             lane1,       // High byte enable
    input      [15:0] write_data,  // 16-bit input bus
    output reg [15:0] read_data    // 16-bit output bus
);

    // 2048 x 8-bit memory arrays for low and high byte lanes
    reg [7:0] lo_array [0:2047];
    reg [7:0] hi_array [0:2047];

    // Synchronous Read & Write Operations on Clock Edge
    always @(posedge clk) begin
        if (sel) begin
            // Write Operation
            if (!rwbar) begin
                if (lane0) lo_array[addr] <= write_data[7:0];
                if (lane1) hi_array[addr] <= write_data[15:8];
            end
            
            // Synchronous Read Operation
            else begin
                read_data[7:0]  <= lo_array[addr];
                read_data[15:8] <= hi_array[addr];
            end
        end
    end

endmodule