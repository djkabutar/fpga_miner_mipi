module verify_mipi_receiver (
    input [47:0] packet,
    input rx_pixel_clk,
    output reg [511:0] data,
    output reg data_valid
);

reg start, sof_received;
reg[15:0] pkt_id;
reg[7:0] dtype, phl_id;
reg packet_id_received, dlen_received;
reg[31:0] k, dlen;
// reg[511:0] data_value;

always @(posedge rx_pixel_clk) begin
    if ((packet[47:16] == 32'h8899FFEA) && !start && !sof_received) begin
        start <= 1;
        sof_received <= 1;
        pkt_id <= packet[15:0];
        packet_id_received <= 1;
        start <= 0;
    end
    else if(packet_id_received) begin
        dtype <= packet[47:40];
        dlen[7:0] <= packet[39:32];
        dlen[15:8] <= packet[31:24];
        dlen[23:16] <= packet[23:16];
        dlen[31:24] <= packet[15:8];
        phl_id <= packet[7:0];
        packet_id_received <= 0;
        dlen_received <= 1;
    end
    else if(dlen_received && k < dlen) begin
        data <= (data << 48) | packet[47:0];
        k <= k + 1;
    end
    else if(dlen_received && k == dlen) begin
        dlen_received <= 0;
        k <= 0;
        sof_received <= 0;
        data_valid <= 1;
    end
    // else begin
    //     data_valid <= 0;
    // end
end

// assign data = data_value;

endmodule