module pixel_data_gen #(parameter DLEN = 32'h002b)(
    input[(DLEN*8) - 1:0] data,
    input[9:0] x,y,
    input tx_pixel_clk,
    input data_available,
    
    output[63:0] pixel_value,
    output reg busy
);

parameter SOF = 16'hEAFF;
parameter EOF = 16'hDDAA;
parameter PHL_ID = 8'h00;
parameter DTYPE = 8'h01;
parameter REM = (DLEN % 6);

integer k;
reg[47:0] temp_val;
reg set;
reg ext;

always @(posedge tx_pixel_clk) begin
    if (data_available) begin
        if (x < 1 && y < 2) begin
            temp_val <= 64'h01000000FFEA;
            k <= 0;
            ext <= 0;
            busy <= 1;
        end
        else if (x < 3 && y < 2) temp_val <= {
                                                PHL_ID,
                                                DLEN[7:0],
                                                DLEN[15:8],
                                                DLEN[23:16],
                                                DLEN[31:24],
                                                DTYPE
                                            };
        else if (ext) begin
            temp_val <= 64'hDD;
            ext <= 0;
            k <= 0;
            busy <= 0;
            // data_available <= 0;
        end
        else if (k <= DLEN & busy) begin
            if (DLEN - k == REM) begin
                if (REM == 5) begin
                    temp_val <= (64'hAA << REM*8) | (data[(DLEN*8) - 1 -: (REM*8)]);
                    ext <= 1;
                end
                else if (REM == 0) begin
                    temp_val <= EOF;
                end
                else begin
                    temp_val <= (EOF << REM*8) | (data[(DLEN*8) - 1 -: (REM*8)]);
                    k <= 0;
                end
            end
            else
                temp_val <= data[k*8 +: 48];

            k <= k + 6;
        end
        else begin
            temp_val <= 64'h00;
            busy <= 0;
            // data_available <= 0;
        end
    end
    else begin
        temp_val <= 64'h00;
        busy <= 0;
    end
end

assign pixel_value = temp_val;

endmodule