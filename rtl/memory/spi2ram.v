module spi2ram
( 
    //spi interface
    input spi_sck,
    input spi_cs,
    input spi_mosi,
    output  spi_miso, 
    //ram interface  
 
    output [15:0] sAddress ,
    output sCSn,
    output sOEn,
    output sWRn,
    output sDqDir,
    output [7:0] sDqOut,
    input [7:0] sDqIn
);
 
    reg [7:0] rINBUF;
    reg [7:0] rOUTBUF;
    assign spi_miso = rOUTBUF[7];
 
 
    reg [5:0] rCnt;
    reg  rCntOV;
    wire sCnt8;
    assign sCnt8 = (~|(rCnt[2:0])) & ((|rCnt[5:3]) | rCntOV);
    //assign sCnt8 = (~|(rCnt[2:0])) & ((|rCnt[5:3]) );
 
 
    reg [7:0] rCmd;
    reg [7:0] rState;
    reg [15:0] rAddress;
    reg rReadFlag1, rReadFlag2; 
    assign sAddress = rReadFlag1 ? {rAddress[15:8], rINBUF} : rAddress;
 
    wire sRamOE;
    assign sRamOE = sCnt8 & (rReadFlag1 | rReadFlag2);
 
    reg rWriteFlag1;
    wire sRamWR; 
    assign sRamWR = sCnt8 & spi_sck & rWriteFlag1;
 
 
    //reg [7:0] rRamWrBuf; 
    //assign sDqOut = sRamWR?rINBUF:8'h00;
    assign sDqOut =  rINBUF;
 
    reg rCmdGotFlag;
 
 
    assign sCSn = sOEn & sWRn;
    assign sOEn = ~sRamOE;
    assign sWRn = ~sRamWR;
    assign sDqDir = sRamWR;
 
    always@(posedge spi_sck , posedge spi_cs )begin
        if(spi_cs)begin
            rINBUF <= 'b0;
            rCnt <= 'b0; 
        end
        else
        begin 
            rINBUF <= {rINBUF[6:0], spi_mosi}; 
            rCnt <= rCnt + 1'b1;   
        end
    end
 
 
 
    always@( negedge spi_sck , posedge spi_cs ) begin
 
        if(spi_cs)begin
            rWriteFlag1 <= 'b0;
            rReadFlag1 <= 'b0;
            rReadFlag2 <= 'b0; 
            rAddress <= 'b0;
            rCmdGotFlag <= 0; 
            rCmd  <= 0; 
				rCntOV <= 1'b0;
        end
        else
        if(sCnt8)begin
            if(!rCmdGotFlag)begin
                rCmdGotFlag <= 1'b1;
					 rCntOV <= 1'b1;
                rCmd <= rINBUF; 
                if(rINBUF == 8'h05) rOUTBUF <= rState; 
                if(rINBUF == 8'h04) rState[1] <= 1'b0; 
                if(rINBUF == 8'h06) rState[1] <= 1'b1; 
                if(rINBUF == 8'h9f) rOUTBUF <= 8'h20; 
            end
            else begin  
                case(rCmd[3:0])
                4'h1:begin
                    if( rCnt[5:3] == 3'b010 ) rState <= rINBUF; 
                    end
                4'h2:begin
                    if( rWriteFlag1 == 'b0 )begin
                        case( rCnt[5:3])   
                        3'b010: begin 
                            rAddress[15:8] <= rINBUF;   
                        end
                        3'b011: begin
                            rAddress[15:0] <= {rAddress[15:8], rINBUF};  
                            rWriteFlag1 <= 1'b1;
                        end 
                        endcase  
                    end
                    else begin
                        //rRamWrBuf <= rINBUF;
                        rAddress <= rAddress + 1'b1; 
                    end
 
                    end
                4'h3:begin
                    if( rReadFlag2 == 'b0 )begin
                        case( rCnt[5:3])   
                        3'b010: begin 
									rAddress[15:8] <= rINBUF; 
									rOUTBUF <= 8'h00; 
									rReadFlag1 <= 'b1; 
									end
                        3'b011: begin
									rAddress[15:0] <= {rAddress[15:8], rINBUF} + 1'b1; 
									rOUTBUF <= sDqIn;
									rReadFlag2 <= 'b1;  
									rReadFlag1<= 'b0; 
                        end 
                        endcase  
                    end 
                    else begin
                        rOUTBUF <= sDqIn;
                        rAddress <= rAddress + 1'b1; 
                    end
                    end
                4'h4:begin
 
                    end
                4'h5:begin
								rOUTBUF <= rState;  
                    end
                4'h6:begin
 
                    end
                4'hf:begin
                        case( rCnt[5:3])   
                        3'b010: begin 
                            rOUTBUF <= 8'h11;
                        end
                        3'b011: begin 
                            rOUTBUF <= 8'h22;
                        end  
                        endcase  
                    end
                 default:begin
 
                    end 
                endcase 
            end 
        end
        else begin
            rOUTBUF <= {rOUTBUF[6:0],1'b0}; 
        end 
    end
 
 
endmodule