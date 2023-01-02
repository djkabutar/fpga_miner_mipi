`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:22:25 11/20/2022 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module top (
    input hash_clk,
    
    input         tx_pixel_clk,
    input         tx_vga_clk,
    input         rst_n,
    input         rx_pixel_clk,
    input         mipi_rx_cal_clk,

/* Signals used by the MIPI RX Interface Designer instance */
	    
	output        mipi_rx_DPHY_RSTN,
	output        mipi_rx_RSTN,
	output        mipi_rx_CLEAR,
	output [1:0]  mipi_rx_LANES,
	output [3:0]  mipi_rx_VC_ENA,
	input         mipi_rx_VALID,
	input [3:0]   mipi_rx_HSYNC,
	input [3:0]   mipi_rx_VSYNC,
	input [63:0]  mipi_rx_DATA,
	input [5:0]   mipi_rx_TYPE,
	input [1:0]   mipi_rx_VC,
	input [3:0]   mipi_rx_CNT,
	input [17:0]  mipi_rx_ERROR,
	input         mipi_rx_ULPS_CLK,
	input [3:0]   mipi_rx_ULPS,

/* Signals used by the MIPI TX Interface Designer instance */
	    
	output        mipi_tx_DPHY_RSTN,
	output        mipi_tx_RSTN,
	output        mipi_tx_VALID,
	output        mipi_tx_HSYNC,
	output        mipi_tx_VSYNC,
	output [63:0] mipi_tx_DATA,
	output [5:0]  mipi_tx_TYPE,
	output [1:0]  mipi_tx_LANES,
	output        mipi_tx_FRAME_MODE,
	output [15:0] mipi_tx_HRES,
	output [1:0]  mipi_tx_VC,
	output [3:0]  mipi_tx_ULPS_ENTER,
	output [3:0]  mipi_tx_ULPS_EXIT,
	output        mipi_tx_ULPS_CLK_ENTER,
	output        mipi_tx_ULPS_CLK_EXIT, 
    output        TxD,
    output        RxD,
    output        led3,
    output        led2,
    output        tx_hs,
    output        tx_vs,
    output        uart_log
);

	// The LOOP_LOG2 parameter determines how unrolled the SHA-256
	// calculations are. For example, a setting of 1 will completely
	// unroll the calculations, resulting in 128 rounds and a large, fast
	// design.
	//
	// A setting of 2 will result in 64 rounds, with half the size and
	// half the speed. 3 will be 32 rounds, with 1/4th the size and speed.
	// And so on.
	//
	// Valid range: [0, 5]
	parameter LOOP_LOG2 = 5;
    parameter DLEN = 64;

	// No need to adjust these parameters
	localparam [5:0] LOOP = (6'd1 << LOOP_LOG2);
	// The nonce will always be larger at the time we discover a valid
	// hash. This is its offset from the nonce that gave rise to the valid
	// hash (except when LOOP_LOG2 == 0 or 1, where the offset is 131 or
	// 66 respectively).
	localparam [31:0] GOLDEN_NONCE_OFFSET = (32'd1 << (7 - LOOP_LOG2)) + 32'd1;
    wire uart_clk;
    
    
    assign tx_hs = mipi_tx_HSYNC;
    assign tx_vs = mipi_tx_VSYNC;
    assign uart_clk = mipi_rx_cal_clk;
    assign TxD = mipi_rx_VALID;

    wire [(DLEN*8)-1:0] received_data;
    wire data_valid, data_available;
    wire tx_busy;
    reg write_enable = 0;

    mipi_rx #(.DLEN(DLEN))(
        .rx_pixel_clk(rx_pixel_clk),
        .rst_n(rst_n),
        .uart_clk(uart_clk),
        .uart_inst(led3),
        .led(led2),
        .data(received_data),
        .data_valid(data_valid),
        .data_available(data_available),
        .tx_busy(tx_busy),
        
        .my_mipi_rx_DPHY_RSTN(mipi_rx_DPHY_RSTN),
        .my_mipi_rx_RSTN(mipi_rx_RSTN),
        .my_mipi_rx_CLEAR(mipi_rx_CLEAR),
        .my_mipi_rx_LANES(mipi_rx_LANES),
        .my_mipi_rx_VC_ENA(mipi_rx_VC_ENA),
        .my_mipi_rx_VALID(mipi_rx_VALID),
        .my_mipi_rx_HSYNC(mipi_rx_HSYNC),
        .my_mipi_rx_VSYNC(mipi_rx_VSYNC),
        .my_mipi_rx_DATA(mipi_rx_DATA),
        .my_mipi_rx_TYPE(mipi_rx_TYPE),
        .my_mipi_rx_VC(mipi_rx_VC),
        .my_mipi_rx_CNT(mipi_rx_CNT),
        .my_mipi_rx_ERROR(mipi_rx_ERROR),
        .my_mipi_rx_ULPS_CLK(mipi_rx_ULPS_CLK),
        .my_mipi_rx_ULPS(mipi_rx_ULPS)
    );
    
    mipi_tx #(.DLEN(5))(
        .tx_pixel_clk(tx_pixel_clk),
        .tx_vga_clk(tx_vga_clk),
        .data_available(data_available),
        .pix_gen_data(received_data),
        .write_enable(write_enable),
        .rst_n(rst_n),
        .led1(RxD),
        .busy(tx_busy),
            
        .my_mipi_tx_DPHY_RSTN(mipi_tx_DPHY_RSTN),
        .my_mipi_tx_RSTN(mipi_tx_RSTN),
        .my_mipi_tx_VALID(mipi_tx_VALID),
        .my_mipi_tx_HSYNC(mipi_tx_HSYNC),
        .my_mipi_tx_VSYNC(mipi_tx_VSYNC),
        .my_mipi_tx_DATA(mipi_tx_DATA),
        .my_mipi_tx_TYPE(mipi_tx_TYPE),
        .my_mipi_tx_LANES(mipi_tx_LANES),
        .my_mipi_tx_FRAME_MODE(mipi_tx_FRAME_MODE),
        .my_mipi_tx_HRES(mipi_tx_HRES),
        .my_mipi_tx_VC(mipi_tx_VC),
        .my_mipi_tx_ULPS_ENTER(mipi_tx_ULPS_ENTER),
        .my_mipi_tx_ULPS_EXIT(mipi_tx_ULPS_EXIT),
        .my_mipi_tx_ULPS_CLK_ENTER(mipi_tx_ULPS_CLK_ENTER),
        .my_mipi_tx_ULPS_CLK_EXIT(mipi_tx_ULPS_CLK_EXIT)
    );

	//// 
// 	reg [255:0] state = 0;
// 	reg [511:0] data = 0;
//     reg [31:0] 	    nonce = 32'h00000000;

// 	//// Hashers
// 	wire [255:0] hash, hash2;
// 	reg [5:0] cnt = 6'd0;
// 	reg feedback = 1'b0;

// 	sha256_transform #(.LOOP(LOOP)) uut (
// 		.clk(hash_clk),
// 		.feedback(feedback),
// 		.cnt(cnt),
// 		.rx_state(state),
// 		.rx_input(data),
// 		.tx_hash(hash)
// 	);
// 	sha256_transform #(.LOOP(LOOP)) uut2 (
// 		.clk(hash_clk),
// 		.feedback(feedback),
// 		.cnt(cnt),
// 		.rx_state(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
// 		.rx_input({256'h0000010000000000000000000000000000000000000000000000000080000000, hash}),
// 		.tx_hash(hash2)
// 	);


// 	//// Virtual Wire Control
// 	reg [255:0] midstate_buf = 0, data_buf = 0;
// 	wire [255:0] midstate_vw, data2_vw;
   
//    serial_receive serrx (.clk(hash_clk), .RxD(RxD), .midstate(midstate_vw), .data2(data2_vw));
   
// 	//// Virtual Wire Output
// 	reg [31:0] golden_nonce;
//    reg 		   serial_send;
//    wire 	   serial_busy;

//    serial_transmit sertx (.clk(hash_clk), .TxD(TxD), .send(serial_send), .busy(serial_busy), .word(golden_nonce));
   

// 	//// Control Unit
// 	reg is_golden_ticket = 1'b0;
// 	reg feedback_d1 = 1'b1;
// 	wire [5:0] cnt_next;
// 	wire [31:0] nonce_next;
// 	wire feedback_next;
//     wire reset;
//     assign reset = 1'b0;

// 	assign cnt_next =  reset ? 6'd0 : (LOOP == 1) ? 6'd0 : (cnt + 6'd1) & (LOOP-1);
// 	// On the first count (cnt==0), load data from previous stage (no feedback)
// 	// on 1..LOOP-1, take feedback from current stage
// 	// This reduces the throughput by a factor of (LOOP), but also reduces the design size by the same amount
// 	assign feedback_next = (LOOP == 1) ? 1'b0 : (cnt_next != {(LOOP_LOG2){1'b0}});
// 	assign nonce_next =
// 		reset ? 32'd0 :
// 		feedback_next ? nonce : (nonce + 32'd1);

	
// 	always @ (posedge hash_clk)
// 	begin
//         midstate_buf <= midstate_vw;
//         data_buf <= data2_vw;

// 		cnt <= cnt_next;
// 		feedback <= feedback_next;
// 		feedback_d1 <= feedback;

// 		// Give new data to the hasher
// 		state <= midstate_buf;
// 		data <= {384'h000002800000000000000000000000000000000000000000000000000000000000000000000000000000000080000000, nonce_next, data_buf[95:0]};
// 		nonce <= nonce_next;


// 		// Check to see if the last hash generated is valid.
// 		is_golden_ticket <= (hash2[255:224] == 32'h00000000) && !feedback_d1;
// 		if(is_golden_ticket)
// 		begin
// 			// TODO: Find a more compact calculation for this
// 			if (LOOP == 1)
// 				golden_nonce <= nonce - 32'd131;
// 			else if (LOOP == 2)
// 				golden_nonce <= nonce - 32'd66;
// 			else
// 				golden_nonce <= nonce - GOLDEN_NONCE_OFFSET;

// 		   if (!serial_busy) serial_send <= 1;
// 		end // if (is_golden_ticket)
// 		else
// 		  serial_send <= 0;
// 	end

   // die debuggenlichten

   // output [7:0] segment;
   // output [2:0] anode;

   // wire [7:0] 	segment_data;

   // inverted signals, so 1111.. to turn it off
   // assign segment = segment_data;
   
//   raw7seg disp(.clk(hash_clk), .segment(segment_data), .anode(anode), .word({midstate_vw[15:0], data2_vw[15:0]}));
   // raw7seg disp(.clk(hash_clk), .segment(segment_data), .anode(anode), .word(golden_nonce));
   
endmodule