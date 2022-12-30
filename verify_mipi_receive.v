module verify_mipi_receiver #(DLEN = 6)(
    input [47:0] packet,
    input rx_pixel_clk,
    input my_mipi_rx_VALID,
    output reg [(DLEN*8)-1:0] data,
    output reg data_valid,
    output reg data_available
);

// parameter SOF = 24'h99FFEA;
parameter SOF = 24'hEAFF99;

localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10; 

reg start, sof_received;
reg[23:0] pkt_id;
reg[7:0] dtype, phl_id;
reg packet_id_received, dlen_received;
reg[31:0] k, dlen;
reg[1:0] state;
// reg[511:0] data_value;

always @(posedge rx_pixel_clk) begin
    case (state)
        IDLE : begin
            data_available <= 0;
            k <= 0;

            if (packet[47:24] == SOF) begin
                state <= START;
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
                data_valid <= 1;
                state <= IDLE;
            end
            // else begin
            // end
            k <= k + 6;
        end
        default: 
            state <= IDLE;
    endcase
    
    
    
    
    // if ((packet[47:16] == SOF) && !start && !sof_received) begin
    //     start <= 1;
    //     sof_received <= 1;
    //     pkt_id <= packet[15:0];
    //     packet_id_received <= 1;
    //     start <= 0;
    // end
    // else if(packet_id_received) begin
    //     dtype <= packet[47:40];
    //     dlen[7:0] <= packet[39:32];
    //     dlen[15:8] <= packet[31:24];
    //     dlen[23:16] <= packet[23:16];
    //     dlen[31:24] <= packet[15:8];
    //     phl_id <= packet[7:0];
    //     packet_id_received <= 0;
    //     dlen_received <= 1;
    // end
    // else if(dlen_received && k < dlen) begin
    //     data <= (data << 48) | packet[47:0];
    //     k <= k + 1;
    // end
    // else if(dlen_received && k == dlen) begin
    //     dlen_received <= 0;
    //     k <= 0;
    //     sof_received <= 0;
    //     data_valid <= 1;
    // end
    // else begin
    //     data_valid <= 0;
    // end
end

// assign data = data_value;

endmodule