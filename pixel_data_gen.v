module pixel_data_gen #(
    parameter DLEN = 32'h002b,
    parameter activeVideo_h = 640,
    parameter activeVideo_v = 480
) (
    input[(DLEN*8) - 1:0] data,
    input[9:0] x,y,
    input tx_pixel_clk,
    input data_available,
    input write_enable,
    
    output[63:0] pixel_value,
    output reg pix_flag,
    output reg busy
);

parameter SOF = 16'hEAFF;
parameter EOF = 16'hDDAA;
parameter PHL_ID = 8'h00;
parameter DTYPE = 8'h01;
parameter REM = (DLEN % 6);

parameter IDLE = 2'b00;
parameter DATA = 2'b01;
parameter EOD = 2'b10;

integer k;
reg[47:0] temp_val;
reg ext;
wire flag;
reg[1:0] state;

// always @(*) begin
//     if (pix_flag)
//         flag <= 0;
//     else
//         flag <= data_available;
// end

assign flag = pix_flag ? 0 : data_available;

always @(posedge tx_pixel_clk) begin

    case (state)
        IDLE : begin
            // busy <= 0;
            if (flag) begin
                state <= DATA;
                busy <= 1;
                pix_flag <= 1;
            end
            else if(write_enable) begin
                state <= DATA;
                busy <= 1;
            end
        end
        DATA : begin
            if (x < 1 && y < 2) begin
                temp_val <= 64'h01000000FFEA;
                k <= 0;
                ext <= 0;
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
                // k <= 0;
                // state <= EOD;
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
            else if (x == activeVideo_h - 1 & y == activeVideo_v) begin
                state <= EOD;
                pix_flag <= 0;
                temp_val <= 64'h00;
            end
            else begin
                temp_val <= 64'h00;
            end
        end
        EOD: begin
            busy <= 0;
            state <= IDLE;
        end
        default: begin
            busy <= 0;
            pix_flag <= 0;
            state <= IDLE;
        end
    endcase
    // if (data_available) begin
    //     if (x == 1 && y == 1) begin
    //         temp_val <= 64'h01000000FFEA;
    //         k <= 0;
    //         ext <= 0;
    //         // busy <= 1;
    //         // flag <= 0;
    //     end
    //     else if (x == 3 && y == 1) temp_val <= {
    //                                             PHL_ID,
    //                                             DLEN[7:0],
    //                                             DLEN[15:8],
    //                                             DLEN[23:16],
    //                                             DLEN[31:24],
    //                                             DTYPE
    //                                         };
    //     else if (ext) begin
    //         temp_val <= 64'hDD;
    //         ext <= 0;
    //         k <= 0;
    //         // busy <= 0;
    //         // data_available <= 0;
    //     end
    //     else if (k <= DLEN & busy) begin
    //         if (DLEN - k == REM) begin
    //             if (REM == 5) begin
    //                 temp_val <= (64'hAA << REM*8) | (data[(DLEN*8) - 1 -: (REM*8)]);
    //                 ext <= 1;
    //             end
    //             else if (REM == 0) begin
    //                 temp_val <= EOF;
    //             end
    //             else begin
    //                 temp_val <= (EOF << REM*8) | (data[(DLEN*8) - 1 -: (REM*8)]);
    //                 k <= 0;
    //             end
    //         end
    //         else
    //             temp_val <= data[k*8 +: 48];

    //         k <= k + 6;
    //     end
    //     else if (x == activeVideo_h - 1 && y == activeVideo_v) begin
    //         temp_val <= 64'h00;
    //         flag <= 1;
    //     end
    //     else begin
    //         temp_val <= 64'h00;
    //         // busy <= 0;
    //         // data_available <= 0;
    //     end
    // end
    // else begin
    //     temp_val <= 64'h00;
    //     // flag <= 0;
    //     // busy <= 0;
    // end
end

// always @(posedge c_clk) begin
//     if (flag) busy <= 0;
//     else busy <= 1;
// end

// assign c_clk = ~tx_pixel_clk;
assign pixel_value = temp_val;

endmodule