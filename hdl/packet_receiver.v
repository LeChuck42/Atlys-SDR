`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:32:29 12/08/2011 
// Design Name: 
// Module Name:    packet_receiver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Receive packets from the MAC and deal with them.
// Assume that the MAC is performing packet filtering.
// Handle two types of packets:
//
// TODO - ARP request: Generate an output signal indicating that an ARP reply should be generated
// UDP packet: Send packet payload to an output port, suitable for a UART
//
// Note, for simplicity we make a big assumption that we receive a 'standard' IP packet
// with no extra options.
//
//////////////////////////////////////////////////////////////////////////////////
module packet_receiver (
	input clk,
	input reset,
	
	input [3:0] rd_flags_i,
	input [31:0] rd_data_i,
	input rd_src_rdy_i,
	output wire rd_dst_rdy_o,
	
	output wire data_out_dac,
	output wire data_out_cpu,
	
	output reg [31:0] data_out,
	
	output reg packet_loss,
	
	input [47:0] my_mac,
	input [31:0] my_ip
	);
	
	reg data_out_reg;
	assign data_out_dac = (dst_port_buffer[0] == 1'b0)? data_out_reg : 1'b0;
	assign data_out_cpu = (dst_port_buffer[0] == 1'b1)? data_out_reg : 1'b0;
	
	// State machine
	(* fsm_encoding = "user" *) 
	reg [15:0] state;
	
	reg [15:0] packet_length;
	
	reg [47:0] dst_mac_buffer;
	wire dst_mac_match;
	
	reg [31:0] dst_ip_buffer;
	wire dst_ip_match;
	
	reg [15:0] dst_port_buffer;
	
	reg [15:0] packet_counter[0:1];
	
	assign dst_mac_match = (dst_mac_buffer == my_mac)? 1'b1 : 1'b0;
	assign dst_ip_match = (dst_ip_buffer == my_ip)? 1'b1 : 1'b0;
	
	assign rd_dst_rdy_o = rd_src_rdy_i;
	
	wire flag_eof = rd_flags_i[1];
	wire flag_sof = rd_flags_i[0];
	
	always @(posedge clk) begin
		if (reset) begin
			state <= 13'h0001;
			data_out_reg <= 0;
			dst_mac_buffer <= 0;
			dst_ip_buffer <= 0;
			dst_port_buffer <= 0;
			packet_counter[0] <= 0;
			packet_counter[1] <= 0;
			packet_loss <= 0;
		end else begin
			data_out_reg <= 0;
			
			case(state)
				13'h0001:
					// Wait for a new packet
					if (rd_src_rdy_i && flag_sof == 1) begin // SOF indicator
						dst_mac_buffer[47:16] <= rd_data_i;
						next_state();
					end
				13'h0002:
					if (rd_src_rdy_i) begin
						dst_mac_buffer[15:0] <= rd_data_i[31:16];
						// Discard SRC_MAC[47:32]
						next_state();
					end
				13'h0004:
					if (!dst_mac_match)
						state <= 13'h1000; //packet not intendet for us, skip
					else if (rd_src_rdy_i)
						next_state(); // Discard SRC_MAC[31:0]
				13'h0008:
					// Check that this is an IP packet. Otherwise, skip.
					if (rd_src_rdy_i)
						if (rd_data_i == 32'h0800_4500)
							next_state();
						else begin
							state <= 13'h1000;
							$display("packet_receiver: Not an IP packet. Skipping to end (got 0x%h, should be 0x08004500)", rd_data_i);
						end
				13'h0010:
					if (rd_src_rdy_i) begin
						packet_length <= rd_data_i[31:16] - 16'd28; // Total IP packet length, subtract IP (20) and UDP (8) headers
						next_state();
					end
				13'h0020:
					if (rd_src_rdy_i)
						// Check that this is a UDP packet with correct length. Otherwise, skip.
						if (rd_data_i[7:0] == 8'h11 || packet_length[1:0] != 2'b10)
							next_state();
						else begin
							state <= 13'h1000;
							$display("packet_receiver: Not a UDP packet. Skipping to end (got 0x%h, should be 0x11)", rd_data_i[7:0]);
						end
				13'h0040: if (rd_src_rdy_i) next_state(); // Discard checksum, SRC_IP[31:16]
				13'h0080:
					if (rd_src_rdy_i) begin
						dst_ip_buffer[31:16] <= rd_data_i[15:0];
						next_state(); // Discard SRC_IP[15:0]
					end
				13'h0100:
					if (rd_src_rdy_i) begin
						dst_ip_buffer[15:0] <= rd_data_i[31:16];
						next_state(); // Discard SRC_PORT
					end
				13'h0200:
					if (!dst_ip_match)
						state <= 13'h1000;
					else if (rd_src_rdy_i) begin
						dst_port_buffer <= rd_data_i[31:16];
						next_state(); // Discard UDP packet length
					end
				13'h0400:
					if (rd_src_rdy_i) begin
						// first payload word contains the packet counter
						$display("packet_receiver: Packet data length is %d", packet_length);
						if (packet_counter[dst_port_buffer[0]] != rd_data_i[15:0]) begin
							packet_loss <= 1;
							packet_counter[dst_port_buffer[0]] <= rd_data_i[15:0];
						end
						packet_length[1] <= 0; // -= 2
						next_state();
					end
				
				13'h0800:
					if (rd_src_rdy_i) begin
						// Read data
						data_out <= rd_data_i;
						data_out_reg <= 1;
						if (packet_length == 16'd4 || flag_eof == 1) begin
							packet_loss <= 0;
							packet_counter[dst_port_buffer[0]] <= packet_counter[dst_port_buffer[0]] + 1;
							if (flag_eof == 1)
								state <= 13'h0001;
							else
								state <= 13'h1000;
						end else
							packet_length <= packet_length - 16'd4;
					end
				13'h1000:
					// Wait until the end of the packet
					if (flag_eof == 1)
						state <= 13'h0001;
			endcase
			
		end // if
	end // always

	task next_state;
	begin
		state <= {state[14:0],state[15]};
	end
	endtask
	
endmodule
