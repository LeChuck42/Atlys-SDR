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
	output reg   wr_src_rdy_o,
	input        wr_dst_rdy_i,
	
	input        tx_fifo_status,
	input [15:0] tx_fifo_cnt,
	
	input              wb_clk_i,
	input              wb_rst_i,
	output reg [31:0]  wb_adr_o,
	output reg         wb_stb_o,
	output reg         wb_cyc_o,
	output reg  [2:0]  wb_cti_o,
	output      [1:0]  wb_bte_o,
	output             wb_we_o,
	output reg  [3:0]  wb_sel_o,
	output     [31:0]  wb_dat_o,
	input      [31:0]  wb_dat_i,
	input              wb_ack_i,
	
	input      [31:0]  wb_addr_offset,
	input              wb_addr_ready,
	input      [8:0]   wb_buf_size,
	
	input [31:0] adc_fifo_d,
	input [8:0]  adc_packet_size_i,
	input        adc_fifo_req,
	output reg   adc_fifo_rd,
	
	input [47:0] my_mac,
	input [31:0] my_ip,
	input [47:0] dst_mac,
	input [31:0] dst_ip,
	
	output       eth_tx_irq_flag);
	 
	localparam IP_IDENTIFICATION = 16'haabb;
	localparam IP_FRAG = 13'd0;
	
	parameter SRC_PORT = 16'h4711;
	parameter DST_PORT_FIFO = 16'h1230;
	parameter DST_PORT_PRI = 16'h1231;
	parameter DST_PORT_SEC = 16'h1232;
	
	// Generate valid IP header checksums
	wire [15:0] header_checksum;
	reg [15:0] header_checksum_buf;
	wire [31:0] header_checksum_input;
	reg enab_checksum;
	reg header_checksum_reset;
	
	ip_header_checksum ip_header_checksum (
		.clk(clk),
		.checksum(header_checksum),
		.header(header_checksum_input),
		.enab(enab_checksum),
		.reset(header_checksum_reset));

	// Packet generation FSM
	(* fsm_encoding = "user" *) 
	reg [14:0] state;
	reg [1:0] data_source;
	reg [15:0] dst_port;
	
	localparam SOURCE_PRI = 2'b00;
	localparam SOURCE_SEC = 2'b01;
	localparam SOURCE_TX_FIFO = 2'b10;
	
	always @(data_source) begin
		if (data_source == SOURCE_SEC)
			dst_port <= DST_PORT_SEC;
		else
			dst_port <= DST_PORT_FIFO;
	end
	
	// Calculate packet lengths
	wire [15:0] packet_length_udp, packet_length_ip;
	reg [8:0] packet_size_count;
	reg [15:0] packet_counter;
	
	assign packet_length_udp = {5'b00000, packet_size_count[8:0], 2'b00} + 4'b1010;
	assign packet_length_ip = {5'b00000, packet_size_count[8:0], 2'b00} + 5'b11110; // IP header adds 20 bytes to UDP packet

	reg [319:0] header;
	assign header_checksum_input = header[239:208];
	
	wire [31:0] dma_fifo_d;
	reg dma_fifo_rd;
	reg dma_fifo_req;
	reg dma_fifo_req_buf;
	reg dma_fifo_req_sync;
	reg dma_fifo_req_done;
	reg tx_fifo_status_int;
	reg tx_fifo_status_sync;
	reg tx_fifo_status_req;
	
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
			data_source <= 0;
			dma_fifo_req_done <= 0;
			dma_fifo_rd <= 0;
			adc_fifo_rd <= 0;
			packet_counter <= 0;
			tx_fifo_status_int <= 0;
			tx_fifo_status_req <= 0;
			tx_fifo_status_sync <= 0;
			dma_fifo_req_sync <= 0;
			dma_fifo_req_buf <= 0;
			header <= {
				dst_mac,	// 48
				my_mac,	// 96
				16'h0800, 16'h4500,	// 128 ethernet / IP
				packet_length_ip, IP_IDENTIFICATION[15:0],	// 160
				3'b000, IP_FRAG[12:0], 16'h4011, // 192
				16'h0000, // 208 checksum
				my_ip,	// 240
				dst_ip,	// 272
				SRC_PORT, dst_port,	// 304
				packet_length_udp }; // 320
		end else begin
		
			dma_fifo_req_sync <= dma_fifo_req_buf;
			dma_fifo_req_buf <= dma_fifo_req;
			
			// default values for state machine
			dma_fifo_rd <= 0;
			adc_fifo_rd <= 0;
			
			tx_fifo_status_sync <= tx_fifo_status_int;
			tx_fifo_status_int <= tx_fifo_status;
			
			if (tx_fifo_status_sync == 0 && tx_fifo_status_int == 1)
				tx_fifo_status_req <= 1;
			
			if (wr_dst_rdy_i)
				wr_flags_o <= 4'b0000; // clear mac flags
			
			if (dma_fifo_req_sync == 1'b0) begin
				dma_fifo_req_done <= 1'b0;
			end
			
			
			casez(state)
			
			15'b??????????????1: // state 1
				if (dma_fifo_req_sync | adc_fifo_req | tx_fifo_status_req) begin
					// Wait until we're told to send a packet
					// Calculate packet header
					if (tx_fifo_status_req) begin
						data_source <= SOURCE_TX_FIFO;
						tx_fifo_status_req <= 0;
						packet_size_count <= 0;
						next_state();
					end else if (dma_fifo_req_sync == 1'b1) begin // prefer primary source if available
						if (dma_fifo_req_done == 1'b0 && dma_fifo_empty == 1'b0) begin
							data_source <= SOURCE_PRI;
							next_state();
						end
					end else begin
						data_source <= SOURCE_SEC;
						packet_size_count <= adc_packet_size_i;
						next_state();
					end
					header_checksum_reset <= 1;
				end
			15'b?????????????1?: // state 2
				if (data_source == SOURCE_PRI) begin
					// skip header (generated by sw)
					dma_fifo_rd <= 1;
					header_checksum_reset <= 1;
				end else begin
					header <= {
						dst_mac,	// 48
						my_mac,	// 96
						16'h0800, 16'h4500,	// 128 ethernet / IP
						packet_length_ip, IP_IDENTIFICATION[15:0],	// 160
						3'b000, IP_FRAG[12:0], 16'h4011, // 192
						16'h0000, // 208 checksum
						my_ip,	// 240
						dst_ip,	// 272
						SRC_PORT, dst_port,	// 304
						packet_length_udp }; // 320
					header_checksum_reset <= 1;
					next_state();
				end
			15'b????????????1??: // state 3
				// start transmission
				if (wr_dst_rdy_i) begin
					wr_src_rdy_o <= 1;
					wr_flags_o <= 4'b0001; // Start of frame
					
					if (data_source == SOURCE_PRI) begin
						state <= 15'h2000;
						wr_data_o <= dma_fifo_d;
						dma_fifo_rd <= 1;
					end else begin
						transmit_header();	//1
						header_checksum_reset <= 0;
					end
				end
			15'b???????????1???: // state 4
				begin
					transmit_header(); //2
					header_checksum_reset <= 0;
				end
			15'b??????????1????: // state 5
				transmit_header(); //3
			15'b?????????1?????: // state 6
				transmit_header(); //4
			15'b????????1??????: // state 7
				transmit_header(); //5
			15'b???????1???????: // state 8
				transmit_header(); //6
			15'b??????1????????: // state 9
				transmit_checksum(); //7
			15'b?????1?????????: // state 10
				transmit_header(); //8
			15'b????1??????????: // state 11
				transmit_header(); //9
			15'b???1???????????: // state 12
				transmit_header(); //10
			
			15'b??1????????????: // state 13
				if (wr_dst_rdy_i) begin
					if (data_source == SOURCE_TX_FIFO) begin
						wr_data_o <= {16'h0000, tx_fifo_cnt};
						state <= 15'h4000;
						wr_flags_o <= 4'b0010; // EOF
					end else begin
						next_state();
						
						wr_data_o <= {16'h0000, packet_counter};  // UDP checksum + running packet counter
						adc_fifo_rd <= 1;
					
					end
				 end
			// Start sending the rest of the payload
			15'b?1?????????????: // state 14
				if (wr_dst_rdy_i) begin
					
					if (data_source == SOURCE_PRI) begin
						wr_data_o <= dma_fifo_d;
						if (dma_fifo_empty == 1'b1) begin
							next_state();
							dma_fifo_req_done <= 1;
							wr_flags_o <= 4'b0010; // 4 bytes, EOF
						end else begin
							dma_fifo_rd <= 1;
						end
						
					end else begin
						wr_data_o <= adc_fifo_d;
						if (packet_size_count == 0) begin // switch controls packet size
							next_state();
							wr_flags_o <= 4'b0010; // 4 bytes, EOF
						end else begin
							adc_fifo_rd <= 1;
							packet_size_count <= packet_size_count - 1'b1;
						end
						
					end
				end
			
			// Wait until we're sure the last word has been received.
			15'b1??????????????: // state 15
				if (wr_dst_rdy_i) begin
					wr_src_rdy_o <= 0;
					next_state();
					if (data_source == SOURCE_SEC) begin
						packet_counter <= packet_counter + 1;
					end
				end
				
			endcase

		end // end if
	end // end always
	
	reg eth_buf_wr;
	reg wb_transfer_active;
	reg [31:0] wb_addr_counter;
	
	reg dma_fifo_req_done_buf;
	reg dma_fifo_req_done_sync;
	
	
	wb_fifo wb_fifo_inst(
	  .rst(wb_rst_i),
	  .wr_clk(wb_clk_i),
	  .rd_clk(clk),
	  .din(wb_dat_i),
	  .wr_en(wb_ack_i),
	  .rd_en(dma_fifo_rd),
	  .dout(dma_fifo_d),
	  .full(),
	  .empty(dma_fifo_empty)
	);

	reg eth_tx_irq_flag_int;
	assign eth_tx_irq_flag = eth_tx_irq_flag_int;
	
	always @(posedge wb_clk_i) begin
		if (wb_rst_i) begin
			eth_buf_wr <= 0;
			wb_transfer_active <= 0;
			wb_adr_o <= 0;
			wb_stb_o <= 0;
			wb_cyc_o <= 0;
			wb_cti_o <= 0; // cycle type 000 = classic, 010 incr. burst, 111 = end of burst
			wb_sel_o <= 4'b1111;
			wb_addr_counter <= 0;
			dma_fifo_req_done_sync <= 0;
			dma_fifo_req_done_buf <= 0;
			eth_tx_irq_flag_int <= 0;
		end else begin
		
			dma_fifo_req_done_sync <= dma_fifo_req_done_buf;
			dma_fifo_req_done_buf <= dma_fifo_req_done;
			
			if (eth_tx_irq_flag_int == 1'b1) begin
				if (wb_addr_ready == 1'b0) begin
					eth_tx_irq_flag_int <= 1'b0;
				end
			end else if (dma_fifo_req == 1'b1) begin
				if (dma_fifo_req_done_sync == 1'b1) begin
					dma_fifo_req <= 1'b0;
					eth_tx_irq_flag_int <= 1'b1;
				end
			end else if (wb_transfer_active) begin
				wb_cyc_o <= 1'b1;
				wb_stb_o <= 1'b1;
				if (wb_ack_i == 1'b1) begin
					if (wb_addr_counter >= wb_buf_size) begin
						wb_transfer_active <= 0;
						wb_cyc_o <= 1'b0;
						wb_stb_o <= 1'b0;
						dma_fifo_req <= 1'b1;
					end else begin
						wb_adr_o <= wb_addr_offset + wb_addr_counter;
						wb_addr_counter <= wb_addr_counter + 4;
					end
				end
			end else begin
				wb_cyc_o <= 1'b0;
				wb_stb_o <= 1'b0;
				if (wb_addr_ready == 1'b1) begin
					wb_transfer_active <= 1'b1;
					wb_adr_o <= wb_addr_offset + wb_addr_counter;
					wb_addr_counter <= wb_addr_counter + 4;
				end
			end
		end
	end
	
		
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
