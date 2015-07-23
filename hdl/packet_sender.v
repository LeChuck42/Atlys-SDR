`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:38:11 12/07/2011 
// Design Name: 
// Module Name:    packet_sender 
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
module packet_sender(
	input clk,
	input reset,
	output reg [3:0] wr_flags_o,
	output reg [31:0] wr_data_o,
	output reg wr_src_rdy_o,
	input wr_dst_rdy_i,

	input [31:0] pri_fifo_d,
	input [8:0] pri_packet_size_i,
	input pri_fifo_req,
	output reg pri_fifo_rd,
	
	input [31:0] sec_fifo_d,
	input [8:0] sec_packet_size_i,
	input sec_fifo_req,
	output reg sec_fifo_rd
    );
	 
	localparam IP_IDENTIFICATION = 16'haabb;
	localparam IP_FRAG = 13'd0;
	
	parameter SRC_PORT = 16'h1234;
	parameter DST_PORT = 16'h1234;
	parameter SRC_MAC = 48'h0037_ffff_3737;
	parameter DST_MAC = 48'h0090_F5DE_6431;//0023_dfff_3311;
	parameter DST_IP = 32'ha9fe_a299;
	parameter SRC_IP = 32'ha9fe_4d01;
	
	// Generate valid IP header checksums
	wire [15:0] header_checksum;
	reg [15:0] header_checksum_buf;
	wire [31:0] header_checksum_input;
	reg enab_checksum;
	reg header_checksum_reset;
	ip_header_checksum ip_header_checksum ( .clk(clk), .checksum(header_checksum), .header(header_checksum_input), .enab(enab_checksum), .reset(header_checksum_reset));
	

	// Packet generation FSM
	(* fsm_encoding = "user" *) 
	reg [14:0] state;
	reg pri_data_source;
	
	// Calculate packet lengths
	wire [15:0] packet_length_udp, packet_length_ip;
	reg [8:0] packet_size_count;
	assign packet_length_udp = {5'b00000, packet_size_count[8:0], 2'b00} + 4'b1010;
	assign packet_length_ip = {5'b00000, packet_size_count[8:0], 2'b00} + 5'b11110; // IP header adds 20 bytes to UDP packet

	reg [319:0] header;
	assign header_checksum_input = header[239:208];
	
	reg pri_fifo_req_latch;
	
	always @(posedge clk) begin
		if (reset) begin
			header_checksum_buf <= 0;
		end else begin
			if (enab_checksum)
				header_checksum_buf <= header_checksum;
		end
	end
	
	always @(posedge clk) begin
		if (reset) begin
			state <= 15'h0001;
			wr_flags_o <= 0;
			wr_src_rdy_o <= 0;
			header_checksum_reset <= 1;
			packet_size_count <= 0;
			enab_checksum <= 0;
			pri_data_source <= 0;
			pri_fifo_req_latch <= 0;
			pri_fifo_rd <= 0;
			sec_fifo_rd <= 0;
			header <= {
				DST_MAC,	// 48
				SRC_MAC,	// 96
				16'h0800, 16'h4500,	// 128 ethernet / IP
				packet_length_ip, IP_IDENTIFICATION[15:0],	// 160
				3'b000, IP_FRAG[12:0], 16'h4011, // 192
				16'h0000, // 208 checksum
				SRC_IP,	// 240
				DST_IP,	// 272
				SRC_PORT, DST_PORT,	// 304
				packet_length_udp }; // 320
		end else begin
			// default values for state machine
			pri_fifo_rd <= 0;
			sec_fifo_rd <= 0;
			
			// store transmission requests
			if (pri_fifo_req == 1)
				pri_fifo_req_latch <= 1;
			
			if (wr_dst_rdy_i)
				wr_flags_o <= 4'b0000; // clear mac flags
				
			enab_checksum <= 0;
			
			case(state)
			
			15'h0001:
				if (pri_fifo_req | sec_fifo_req | pri_fifo_req_latch ) begin
					// Wait until we're told to send a packet
					// Calculate packet header
					
					if (pri_fifo_req | pri_fifo_req_latch) begin// prefer primary source if available
						pri_data_source <= 1;
						packet_size_count <= pri_packet_size_i;
						pri_fifo_req_latch <= 0;
					end else begin
						pri_data_source <= 0;
						packet_size_count <= sec_packet_size_i;
					end
					header_checksum_reset <= 1;
					next_state();
				end
			15'h0002:
				begin
					header <= {
						DST_MAC,	// 48
						SRC_MAC,	// 96
						16'h0800, 16'h4500,	// 128 ethernet / IP
						packet_length_ip, IP_IDENTIFICATION[15:0],	// 160
						3'b000, IP_FRAG[12:0], 16'h4011, // 192
						16'h0000, // 208 checksum
						SRC_IP,	// 240
						DST_IP,	// 272
						SRC_PORT, DST_PORT,	// 304
						packet_length_udp }; // 320
					header_checksum_reset <= 1;
					next_state();
				end
			15'h0004:
				begin
					// start transmission
					if (wr_dst_rdy_i) begin
						wr_src_rdy_o <= 1;
						wr_flags_o <= 4'b0001; // Start of frame
					end
					transmit_header();	//1
					header_checksum_reset <= 0;
				end
			15'h0008:
				begin
					transmit_header(); //2
					header_checksum_reset <= 0;
				end
			15'h0010:	transmit_header(); //3
			15'h0020:	transmit_header(); //4
			15'h0040:	transmit_header(); //5
			15'h0080:	transmit_header(); //6
			15'h0100:	transmit_checksum(); //7
			15'h0200:	transmit_header(); //8
			15'h0400:	transmit_header(); //9
			15'h0800:	transmit_header(); //10
			
			15'h1000:
				if (wr_dst_rdy_i) begin
					wr_data_o <= 32'h0000_4142;  // UDP checksum (4), start of data payload: (4) "AB"
					next_state();
					if (pri_data_source)
						pri_fifo_rd <= 1;
					else
						sec_fifo_rd <= 1;
				 end
			// Start sending the rest of the payload
			15'h2000:
				if (wr_dst_rdy_i) begin
					if (pri_data_source) begin
						wr_data_o <= pri_fifo_d;
						pri_fifo_rd <= 1;
					end else begin
						wr_data_o <= sec_fifo_d;
						sec_fifo_rd <= 1;
					end
						
					packet_size_count <= packet_size_count - 1'b1;
					if (packet_size_count == 0) begin // switch controls packet size
						next_state();
						wr_flags_o <= 4'b0010; // 4 bytes, EOF
					end
				end
			
			// Wait until we're sure the last word has been received.
			15'h4000:
				if (wr_dst_rdy_i) begin
					wr_src_rdy_o <= 0;
					next_state();
				end
				
			endcase

		end // end if
	end // end always
		
		
	// Tasks
	
	task transmit_checksum;
	begin
		if (wr_dst_rdy_i) begin
			if (enab_checksum)
				wr_data_o <= {header_checksum, header[303:288]};
			else
				wr_data_o <= {header_checksum_buf, header[303:288]};
			header <= {header[287:0], header[319:288]};
			next_state();
			header_checksum_reset <= 1;
		end
	end
	endtask
	
	task transmit_header;
	begin
		if (wr_dst_rdy_i) begin
			wr_data_o <= header[319:288];
			header <= {header[287:0], header[319:288]};
			next_state();
			enab_checksum <= 1;
		end
	end
	endtask
	
	task next_state;
	begin
		state <= {state[13:0],state[14]};
	end
	endtask
	

endmodule
