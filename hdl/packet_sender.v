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
	reg [31:0] header_checksum_input;
	reg enab_checksum;
	reg header_checksum_reset;
	ip_header_checksum ip_header_checksum ( .clk(clk), .checksum(header_checksum), .header(header_checksum_input), .enab(enab_checksum), .reset(header_checksum_reset));
	

	// Packet generation FSM
	(* fsm_encoding = "user" *) 
	reg [3:0] state = 0;
	reg pri_data_source;
	
	// Calculate packet lengths
	wire [15:0] packet_length_udp, packet_length_ip;
	
	assign packet_length_udp = {5'b00000, packet_size_count[8:0], 2'b00} + 4'b1010;
	assign packet_length_ip = {5'b00000, packet_size_count[8:0], 2'b00} + 5'b11110; // IP header adds 20 bytes to UDP packet
			
	reg [8:0] packet_size_count = 0;
	
	wire [31:0] header_1, header_2, header_3, header_4, header_5;
	
	assign header_1 = {16'h4500, packet_length_ip};
	assign header_2 = {IP_IDENTIFICATION[15:0], 3'b000, IP_FRAG[12:0]}; // IP identification, fragment;
	assign header_3 = {16'h4011, 16'h0000}; // TTL, protocol, checksum
	assign header_4 = SRC_IP;
	assign header_5 = DST_IP;
	
	reg pri_fifo_req_latch, sec_fifo_req_latch;
	
	always @(posedge clk) begin
		if (reset) begin
			state <= 0;
			wr_flags_o <= 0;
			wr_src_rdy_o <= 0;
			header_checksum_reset <= 1;
			packet_size_count <= 0;
			enab_checksum <= 0;
			pri_data_source <= 0;
			pri_fifo_req_latch <= 0;
			sec_fifo_req_latch <= 0;
			pri_fifo_rd <= 0;
			sec_fifo_rd <= 0;
		end else begin
			// default values for state machine
			enab_checksum <= 0;
			pri_fifo_rd <= 0;
			sec_fifo_rd <= 0;
			
			// store transmission requests
			if (pri_fifo_req == 1)
				pri_fifo_req_latch <= 1;
			
			if (sec_fifo_req == 1)
				sec_fifo_req_latch <= 1;
				
			case(state)
			
			0: if (pri_fifo_req | sec_fifo_req | pri_fifo_req_latch | sec_fifo_req_latch) begin
					// Wait until we're told to send a packet
					// Calculate packet header
					
					if (pri_fifo_req | pri_fifo_req_latch) begin// prefer primary source if available
						pri_data_source <= 1;
						packet_size_count <= pri_packet_size_i;
						pri_fifo_req_latch <= 0;
					end else begin
						pri_data_source <= 0;
						packet_size_count <= sec_packet_size_i;
						sec_fifo_req_latch <= 0;
					end
					
					start_packet();
					transmit_header(DST_MAC[47:16]);
				end
				
			1: begin
					header_checksum_reset <= 0;
					header_checksum_input <= header_1;
					wr_flags_o <= 4'b0000; // clear mac flags
					transmit_header_cs({DST_MAC[15:0], SRC_MAC[47:32]});
				end
			2: begin
					header_checksum_input <= header_2;
					transmit_header_cs(SRC_MAC[31:0]);
				end
			3: begin
					header_checksum_input <= header_3;
					transmit_header_cs({16'h0800, header_1[31:16]}); // First 8 bits: hwtype ethernet (4), protocol type ipv4 (1),  header length (1) (*4), dsc (2)
				end
			4: begin
					header_checksum_input <= header_4;
					transmit_header_cs({header_1[15:0], header_2[31:16]});
				end
			5: begin
					header_checksum_input <= header_5;
					transmit_header_cs({header_2[15:0], header_3[31:16]});
				end	
			6: transmit_header({header_checksum, header_4[31:16]}); // Inject the calculated header checksum here
			7: transmit_header({header_4[15:0], header_5[31:16]});
			8: transmit_header({header_5[15:0], SRC_PORT});
			9: transmit_header({DST_PORT, packet_length_udp});
			10: if (wr_dst_rdy_i) begin
					wr_data_o <= 32'h0000_4142;  // UDP checksum (4), start of data payload: (4) "AB"
					state <= state + 1'b1;
					if (pri_data_source)
						pri_fifo_rd <= 1;
					else
						sec_fifo_rd <= 1;
				 end
			// Start sending the rest of the payload
			11:
				if (wr_dst_rdy_i) begin
					if (pri_data_source)
						wr_data_o <= pri_fifo_d;
					else
						wr_data_o <= sec_fifo_d;
						
					packet_size_count <= packet_size_count - 1'b1;
					if (packet_size_count == 0) begin // switch controls packet size
						state <= state + 1'b1;
						wr_flags_o <= 4'b0010; // 4 bytes, EOF
					end
				end
			
			// Wait until we're sure the last word has been received.
			12:
				if (wr_dst_rdy_i) begin
					wr_src_rdy_o <= 0;
					wr_flags_o <= 0;
					header_checksum_reset <= 1;
					state <= 0;
				end
				
			endcase

		end // end if
	end // end always
		
		
	// Tasks
	
	task start_packet;
	begin
		wr_src_rdy_o <= 1;	
		wr_flags_o <= 4'b0001; // Start of frame
	end
	endtask
	
	task transmit_header_cs;
		input [31:0] header;
	begin
		if (wr_dst_rdy_i) begin
			wr_data_o <= header;
			state <= state + 1'b1;
			enab_checksum <= 1;
		end
	end
	endtask
	
	task transmit_header;
		input [31:0] header;
	begin
		if (wr_dst_rdy_i) begin
			wr_data_o <= header;
			state <= state + 1'b1;
		end
	end
	endtask
	

endmodule
