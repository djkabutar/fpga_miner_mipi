module mipi_rx #(parameter DLEN = 6)(
    input         rx_pixel_clk,
    input         rst_n,
    input         uart_clk,
    input         tx_busy,
    output        led,
    output        uart_inst,

/* Signals used by the MIPI RX Interface Designer instance */
	    
	output        my_mipi_rx_DPHY_RSTN,
	output        my_mipi_rx_RSTN,
	output        my_mipi_rx_CLEAR,
	output [1:0]  my_mipi_rx_LANES,
	output [3:0]  my_mipi_rx_VC_ENA,
	input         my_mipi_rx_VALID,
	input [3:0]   my_mipi_rx_HSYNC,
	input [3:0]   my_mipi_rx_VSYNC,
	input [63:0]  my_mipi_rx_DATA,
	input [5:0]   my_mipi_rx_TYPE,
	input [1:0]   my_mipi_rx_VC,
	input [3:0]   my_mipi_rx_CNT,
	input [17:0]  my_mipi_rx_ERROR,
	input         my_mipi_rx_ULPS_CLK,
	input [3:0]   my_mipi_rx_ULPS,

    output [(DLEN*8)-1:0] data,
    output        data_valid,
    output        data_available
);

assign my_mipi_rx_DPHY_RSTN = 1'b1;
assign my_mipi_rx_RSTN = 1'b1;
assign my_mipi_rx_CLEAR = 1'b0;
assign my_mipi_rx_LANES = 2'b11;         // 4 lanes
assign my_mipi_rx_VC_ENA = 4'b0001;      // Virtual Channel enable

reg [15:0] cnt;
reg state;

// always @(posedge rx_pixel_clk) begin
//     // if (my_mipi_rx_DATA[47:0] == 48'h7e7e7e7e7e7e) data_available <= 1'b1;
//     // // else if (!tx_busy & data_valid) data_valid <= 1'b1;
//     // // else if (tx_busy) <= 1'b0;
//     // else data_available <= 1'b0;
//     case (state)
//         0: begin
//             data_available <= 0;
//             if (my_mipi_rx_VALID & !tx_busy) begin
//                 // data <= (data << 48) | my_mipi_rx_DATA[47:0];
//                 data <= my_mipi_rx_DATA[47:0]
//                     | (data << 48);
//                 state <= 1;
//             end
//         end
//         1: begin
//             data_available <= 1;
//             // cnt <= 0;
//             state <= 0;
//         end
//         default: 
//             state <= 0;
//     endcase

//     if (my_mipi_rx_VALID) begin
//         cnt <= cnt + 1;
//     end
//     else begin
//         cnt <= 0;
//     end
    
//     // else data_available <= 1'b0;
// end

verify_mipi_receiver #(.DLEN(DLEN))(
    .packet(my_mipi_rx_DATA[47:0]),
    .rx_pixel_clk(rx_pixel_clk),
    .data(data),
    .my_mipi_rx_VALID(my_mipi_rx_VALID),
    .data_valid(data_valid),
    .data_available(data_available)
);

udg udg_inst(
    .clk(uart_clk), 
    .rst(rst_n),
    .fifo_we(my_mipi_rx_VALID),
	.data_in(my_mipi_rx_DATA),
	.tx(uart_inst)
);

assign led = data_available;

endmodule


module mipi_tx #(parameter DLEN = 512)(
    input         tx_pixel_clk,
    input         tx_vga_clk,
    input         data_available,
    input         write_enable,
    input[(DLEN*8)-1:0] pix_gen_data,
    input         rst_n,
    output        busy,
    output        led1,

/* Signals used by the MIPI TX Interface Designer instance */
	    
	output        my_mipi_tx_DPHY_RSTN,
	output        my_mipi_tx_RSTN,
	output        my_mipi_tx_VALID,
	output        my_mipi_tx_HSYNC,
	output        my_mipi_tx_VSYNC,
	output [63:0] my_mipi_tx_DATA,
	output [5:0]  my_mipi_tx_TYPE,
	output [1:0]  my_mipi_tx_LANES,
	output        my_mipi_tx_FRAME_MODE,
	output [15:0] my_mipi_tx_HRES,
	output [1:0]  my_mipi_tx_VC,
	output [3:0]  my_mipi_tx_ULPS_ENTER,
	output [3:0]  my_mipi_tx_ULPS_EXIT,
	output        my_mipi_tx_ULPS_CLK_ENTER,
	output        my_mipi_tx_ULPS_CLK_EXIT
);

parameter syncPulse_h= 80;            
parameter backPorch_h= 50;             
parameter activeVideo_h= 640;            
parameter frontPorch_h= 50; 
           
parameter syncPulse_v= 80;              
parameter backPorch_v = 5;             
parameter activeVideo_v = 480;            
parameter frontPorch_v = 5;

wire[3:0] video_pattern;
wire[4:0]  vga_r_patgen;
wire[5:0]  vga_g_patgen;
wire[4:0]  vga_b_patgen; 

wire hsync_patgen;
wire vsync_patgen; 
wire valid_h_patgen;
wire valid_v_patgen;

wire [9:0] x,y;
video_gen #(.syncPulse_h (syncPulse_h),
            .backPorch_h (backPorch_h),
            .activeVideo_h (activeVideo_h),
            .frontPorch_h (frontPorch_h),
            .syncPulse_v (syncPulse_v),
            .backPorch_v (backPorch_v),
            .activeVideo_v (activeVideo_v),
            .frontPorch_v (frontPorch_v)
            ) patgen (
                    .rst (~busy),
                    .clk (tx_vga_clk),
                    .video_pattern (video_pattern),
                    .video_valid_h_o (valid_h_patgen),
                    .video_valid_h_o_2 (),
                    .video_hsync_o (hsync_patgen),
                    .video_hsync_o_2 (),
                    .video_vsync_o (vsync_patgen),
                    .video_valid_v_o (valid_v_patgen),
                    .red_o (vga_r_patgen),
                    .green_o (vga_g_patgen),
                    .blue_o (vga_b_patgen),
                    .x(x),
                    .y(y)
                    );
                    

wire [63:0] pixel_data;
// reg [(DLEN*8)-1:0] pix_gen_data = "god yzal eht revo spmuj xof nworb kciuq eht";
// wire busy;
reg [26:0] cnt;
wire send_confirmation;

pixel_data_gen #(.DLEN(DLEN),
    .activeVideo_h(activeVideo_h),
    .activeVideo_v(activeVideo_v)
) (
    .data(send_confirmation ? "dilav": pix_gen_data),
    .x(x),
    .y(y),
    .pix_flag(send_confirmation),
    .data_available(data_available),
    .busy(busy),
    .write_enable(write_enable),
    .tx_pixel_clk(tx_pixel_clk),
    .pixel_value(pixel_data)
);

// assign pixel_data = data_available ? input_data : 64'h204F4C4C4548;
// assign pixel_data = (x < 2 && y < 2) ? 64'h01000000FFEA : 64'h204F4C4C4548; 
                   // (x == 2 && y == 0) ? 64'h010004000000 :
                   // (x == 4 && y == 0) ? 64'h43484152AADD : 64'h000000000000;
assign led1 = busy;
                    
assign my_mipi_tx_DPHY_RSTN = data_available | busy;
assign my_mipi_tx_RSTN = data_available | busy;
assign my_mipi_tx_VALID = valid_h_patgen;
assign my_mipi_tx_HSYNC = hsync_patgen;//hsync_patgen_PC;
assign my_mipi_tx_VSYNC = vsync_patgen;//vsync_patgen_PC;
assign my_mipi_tx_DATA =  pixel_data;//64'h204f4c4c4548;// tx_pixel_data_PC;//pixel_data; 64'hff0000ff0000; //: 64'd0;//tx_pixel_data_PC;//64'hFF111111000000;
assign my_mipi_tx_TYPE = 6'h24;			// RGB565
assign my_mipi_tx_LANES = 2'b01;                // 2 lanes
assign my_mipi_tx_FRAME_MODE = 1'b0;            // Generic Frame Mode
assign my_mipi_tx_HRES = activeVideo_h;         // Number of pixels per line
assign my_mipi_tx_VC = 2'b00;                   // Virtual Channel select
assign my_mipi_tx_ULPS_ENTER = 4'b0000;
assign my_mipi_tx_ULPS_EXIT = 4'b0000;
assign my_mipi_tx_ULPS_CLK_ENTER = 1'b0;
assign my_mipi_tx_ULPS_CLK_EXIT = 1'b0;

endmodule