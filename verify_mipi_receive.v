module verify_mipi_receiver (
    input [47:0] packet,
    input rx_pixel_clk,
    output reg [511:0] data,
    output reg data_valid
);

reg start, sof_received;
reg[31:0] pkt_id, dlen;
reg[7:0] dtype, phl_id;
reg packet_id_received, dlen_received;
reg[31:0] k;
// reg[511:0] data_value;

always @(posedge rx_pixel_clk) begin
    if ((packet[15:0] == 16'hEAFF) && !start && !sof_received) begin
        start <= 1;
        sof_received <= 1;
    end
    else if(start) begin
        pkt_id <= packet[47:16];
        packet_id_received <= 1;
        start <= 0;
    end
    else if(packet_id_received) begin
        dtype <= packet[7:0];
        dlen <= packet[39:8];
        phl_id <= packet[47:40];
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