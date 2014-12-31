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
	
	output wire data_out_en,
	output reg [7:0] data_out
	);
	
	// Signal to the external process that some valid data is being output.
	reg data_out_reg;
	assign data_out_en = data_out_reg;
	
	// State machine
	(* fsm_encoding = "user" *) 
	reg [5:0] state;
	
	reg [15:0] packet_length;
	reg [31:0] word_buffer;
	
	// This is a bit convoluted, but it defines the states in which we wish to read
	// from the MAC. States 0-8 are waiting for the packet and reading out the header,
	// which does not require any pauses.
	// States 12 and 16 are where the final byte of the word is being output AND it is not EOF. 
	// State 30 is where the end of the packet is being sought.
	//
	// The alternative would be to read the packet into BRAM, and only start examining
	// it when the entire packet has been received
	assign rd_dst_rdy_o = rd_src_rdy_i & ((state <= 9) || (state == 12) || (state == 16) || (state == 30));
	
	always @(posedge clk) begin
		if (reset) begin
			state <= 0;
			data_out_reg <= 0;
		end else begin
		
			// Only proceed while new data is available
			
			case(state)
				0:
					begin
					// Wait for a new packet
					data_out_reg <= 0;
					if (rd_src_rdy_i && (rd_flags_i == 4'b0001)) // SOF indicator
						state <= state + 1'b1; // Discard DST_MAC[47:16]
					end
				1: if (rd_src_rdy_i) state <= state + 1'b1; // Discard DST_MAC[15:0], SRC_MAC[47:32]
				2: if (rd_src_rdy_i) state <= state + 1'b1; // Discard SRC_MAC[31:0]
				3:
					// Check that this is an IP packet. Otherwise, skip.
					if (rd_src_rdy_i)
						if (rd_data_i == 32'h0800_4500)
							state <= state + 1'b1;
						else begin
							state <= 30;
							$display("packet_receiver: Not an IP packet. Skipping to end (got 0x%h, should be 0x08004500)", rd_data_i);
						end
				4: if (rd_src_rdy_i) begin
						packet_length <= rd_data_i[31:16] - 16'd28; // Total IP packet length, subtract IP (20) and UDP (8) headers
						state <= state + 1'b1;
					end
				5: if (rd_src_rdy_i)
						// Check that this is a UDP packet. Otherwise, skip.
						if (rd_data_i[7:0] == 8'h11)
							state <= state + 1'b1;
						else begin
							state <= 30;
							$display("packet_receiver: Not a UDP packet. Skipping to end (got 0x%h, should be 0x11)", rd_data_i[7:0]);
						end
				6: if (rd_src_rdy_i) state <= state + 1'b1; // Discard checksum, SRC_IP[31:16]
				7: if (rd_src_rdy_i) state <= state + 1'b1; // Discard SRC_IP[15:0], DST_IP[31:16]
				8: if (rd_src_rdy_i) state <= state + 1'b1; // Discard DST_IP[15:0], SRC_PORT
				9: if (rd_src_rdy_i) state <= state + 1'b1; // Discard DST_PORT, UDP packet length
				10: if (rd_src_rdy_i) begin
					$display("packet_receiver: Packet data length is %d", packet_length);

					word_buffer <= rd_data_i;
					// We may or may not send out this byte, depending on data_out_reg.
					data_out <= rd_data_i[15:8];
					
					// The first word is a special case, as it may have 0-2 bytes of data
					// in the payload.
					case (packet_length)
						16'd0: begin
							// End of packet with one or two bytes of header, no data
							$display("packet-receiver: empty packet");
							state <= 30;
							end
						16'd1: begin
							// End of packet with one byte of data
							$display("packet-receiver: one byte packet");
							data_out_reg <= 1;
							state <= 30;
							end
						16'd2: begin
							// End of packet with two bytes of data
							$display("packet-receiver: two byte packet");
							data_out_reg <= 1;
							state <= 11;
							end

						default: begin
							// EOF not set. Read two bytes and continue.
							//data_out_reg <= 1;
							state <= 25; // Delay for a few cycles, and then go to state 12 
							packet_length <= packet_length - 16'd2;
						end
						
					endcase
					end
				
				11: begin
					// Read final byte of data and then finish
					data_out <= word_buffer[7:0];
					state <= 30;
					end
				
				12: begin
					// Read one more byte of data before continuing
					data_out <= word_buffer[7:0];
					if (rd_src_rdy_i)
						state <= state + 1'b1;
					end
				
				13: begin
					data_out <= rd_data_i[31:24];
					word_buffer <= rd_data_i;
					// We can either get 1, 2, 3, 4, or 4+ bytes
					case(packet_length)
						16'd1: state <= 30; // Read first byte and finish
						16'd2: state <= 17; // Read out two bytes and finish
						16'd3: state <= 18; // Read out three bytes and finish
						default: state <= 14; // Read out four bytes (and optionally finish)

						
					endcase
					end
				
				// READING FOUR BYTES AND OPTIONALLY FINISHING
				
				14: begin
					// Read second byte
					data_out <= word_buffer[23:16];
					state <= 15;
					end
					
				15: begin
					// Read third byte
					data_out <= word_buffer[15:8];
					state <= 16;
					end
				
				16: begin
					// Read fourth byte
					data_out <= word_buffer[7:0];
					
					if (packet_length == 16'd4) begin 
						// We had exactly four bytes left in this word - EOF 
						state <= 30;
					end else begin
						state <= 13;
						packet_length <= packet_length - 16'd4;
					end
					
					end
				
				// READING TWO BYTES AND FINISHING
				
				17: begin
					// Read second byte and finish
					data_out <= word_buffer[23:16];
					state <= 30;
					end
				
				// READING THREE BYTES AND FINISHING
				
				18: begin
					// Read second byte, then one more
					data_out <= word_buffer[23:16];
					state <= 19;
					end
					
				19: begin
					// Read third byte, then finish.
					data_out <= word_buffer[15:8];
					state <= 30;
					end
				
				// Short delay to allow FIFO to get enough data
				25: state <= 26;
				26: state <= 27;
				27: begin
					data_out_reg <= 1;
					state <= 12;
					end
					
				30: begin
					// Wait until the end of the packet
					data_out_reg <= 0;
					if (rd_flags_i[1] == 1)
						state <= 0;
					end
			endcase
			
		end // if
	end // always

	
endmodule
