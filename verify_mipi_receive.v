module verify_mipi_receiver #(DLEN = 6)(
    input [47:0] packet,
    input rx_pixel_clk,
    input my_mipi_rx_VALID,
    output reg receiving,
    output reg [(DLEN*8)-1:0] data,
    output reg data_available
);

// parameter SOF = 24'h99FFEA;
parameter SOF = 24'hEAFF99;

localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10; 

reg[23:0] pkt_id;
reg[7:0] dtype, phl_id;
reg[31:0] k, dlen;
reg[1:0] state;
reg[4:0] cnt;

wire[4:0] cnt_next;
// assign cnt_next = cnt + 1'b1;
// reg[511:0] data_value;
initial begin
    cnt = 0;
    data_available = 0;
end

always @(posedge rx_pixel_clk) begin
    case (state)
        IDLE : begin
            // data_available <= 0;
            k <= 0;
            
            if (cnt[4]) begin
                data_available <= 0;
                cnt <= 0;
            end
            else
                cnt <= cnt + 1'b1;

            if (packet[47:24] == SOF
                | packet[47:24] == 24'h99FFEA
                | packet[23:0] == SOF
                | packet[23:0] == 24'h99FFEA) begin
                state <= START;
                receiving <= 1;
                // data_valid <= 0;
                // pkt_id[7:0] <= packet[23:16];
                // pkt_id[15:8] <= packet[15:8];
                // pkt_id[23:16] <= packet[7:0];
                pkt_id <= packet[23:0];
            end
            // else begin
            //     state <= IDLE;
            //     data_valid <= 0;
            // end
            // state <= START;
        end
        START : begin
            state <= DATA;
            data <= 0;
            // dtype <= packet[31:24];
            // dlen[7:0] <= packet[15:8];
            // dlen[15:8] <= packet[7:0];
            // dlen[23:16] <= packet[47:40];
            // dlen[31:24] <= packet[39:32];
            // phl_id <= packet[23:16];
            dtype <= packet[47:40];
            dlen <= packet[39:8];
            phl_id <= packet[7:0];
        end
        DATA : begin
            if (k < dlen) begin
                // data <= (data << 48) 
                //     | {
                //         packet[31:24],
                //         packet[39:32],
                //         packet[47:40],
                //         packet[7:0],
                //         packet[15:8],
                //         packet[23:16]
                //     };
                data <= (data << 48) | ((packet[23:0] << 24) 
                        | packet[47:24]);

            end
            else if (k >= dlen) begin
                // data <= (data << 48) | packet[47:0];
                data_available <= 1;
                state <= IDLE;
                receiving <= 0;
                cnt <= 0;
            end
            // else begin
            // end
            k <= k + 6;
        end
        default: 
            state <= IDLE;
    endcase
end

// assign data = data_value;

endmodule