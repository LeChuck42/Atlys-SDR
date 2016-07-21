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
	input [31:0] my_ip,
	
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
	output reg         eth_rx_irq_flag
	);
	
	reg data_out_reg;
	assign data_out_dac = (dst_port_buffer[0] == 1'b0)? data_out_reg : 1'b0;
	assign data_out_cpu = (dst_port_buffer[0] == 1'b1)? data_out_reg : 1'b0;
	
	// State machine
	(* fsm_encoding = "user" *) 
	reg [12:0] state;
	
	reg [15:0] packet_length;
	
	reg [47:0] dst_mac_buffer;
	wire dst_mac_match;
	
	reg [31:0] dst_ip_buffer;
	wire dst_ip_match;
	
	reg [15:0] dst_port_buffer;
	
	reg [15:0] packet_counter[0:1];
	
	wire forward_rd;
	wire [31:0] forward_data;
	wire forward_last;
	wire forward_empty;
	reg  forward_enable;
	reg  wb_addr_ready_edge_buf;
	
	reg wait_for_fifo;
	reg reset_fifo;
	
	assign dst_mac_match = (dst_mac_buffer == my_mac || dst_mac_buffer == 48'hFFFF_FFFF_FFFF)? 1'b1 : 1'b0;
	assign dst_ip_match = (dst_ip_buffer == my_ip)? 1'b1 : 1'b0;
	
	assign rd_dst_rdy_o = rd_src_rdy_i && ~wait_for_fifo;
	
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
			reset_fifo <= 1;
			forward_enable <= 0;
			wait_for_fifo <= 0;
		end else begin
			data_out_reg <= 0;
			case(state)
				13'h0001: begin
					reset_fifo <= 0;
						// Wait for a new packet
						if (rd_src_rdy_i && flag_sof == 1) begin // SOF indicator
							dst_mac_buffer[47:16] <= rd_data_i;
							next_state();
						end
					end
				13'h0002:
					if (rd_src_rdy_i) begin
						dst_mac_buffer[15:0] <= rd_data_i[31:16];
						// Discard SRC_MAC[47:32]
						next_state();
					end
				13'h0004:
					if (!dst_mac_match) begin
						forward_enable <= 1;
						state <= 13'h1000; //packet not intendet for us, skip
					end else if (rd_src_rdy_i)
						next_state(); // Discard SRC_MAC[31:0]
				13'h0008:
					// Check that this is an IP packet. Otherwise, skip.
					if (rd_src_rdy_i)
						if (rd_data_i == 32'h0800_4500)
							next_state();
						else begin
							forward_enable <= 1;
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
							forward_enable <= 1;
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
					if (!dst_ip_match) begin
						forward_enable <= 1;
						state <= 13'h1000;
					end else if (rd_src_rdy_i) begin
						dst_port_buffer <= rd_data_i[31:16];
						next_state(); // Discard UDP packet length
						reset_fifo <= 1;
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
							if (flag_eof == 1) begin
								reset_fifo <= 0;
								state <= 13'h0001;
							end else
								state <= 13'h1000;
						end else
							packet_length <= packet_length - 16'd4;
					end
				13'h1000:
					// Wait until the end of the packet
					if (flag_eof == 1 || wait_for_fifo == 1) begin
						reset_fifo <= 0;
						
						if (forward_enable == 1)
							wait_for_fifo <= 1;
						
						if (forward_empty == 1 || forward_enable == 0) begin
							forward_enable <= 0;
							wait_for_fifo <= 0;
							state <= 13'h0001;
						end
					end
			endcase
			
		end // if
	end // always

	task next_state;
	begin
		state <= {state[12:0],1'b0};
	end
	endtask
	
	reg eth_buf_wr;
	wire eth_buf_rd;
	wire eth_buf_full;
	wire eth_buf_empty;
	wire [32:0] forward_out;
	
	always @(posedge clk) begin
		if (reset) begin
			eth_buf_wr <= 0;
		end else begin
			if (forward_enable && !forward_empty && !eth_buf_full)
				eth_buf_wr <= 1;
			else
				eth_buf_wr <= 0;
		end
	end
	
	forward_buffer forward_buffer_inst (
		.clk(clk),
		.rst(reset_fifo),
		.din({flag_eof, rd_data_i}),
		.wr_en(rd_src_rdy_i && ~wait_for_fifo),
		.rd_en(forward_enable && !forward_empty && !eth_buf_full),
		.dout(forward_out),
		.full(),
		.empty(forward_empty));
		
	eth_rx_buf eth_rx_buf_inst (
		.rst(reset), // input rst
		.wr_clk(clk), // input wr_clk
		.rd_clk(wb_clk_i), // input rd_clk
		.din(forward_out), // input [32 : 0] din
		.wr_en(eth_buf_wr), // input wr_en
		.rd_en(eth_buf_rd), // input rd_en
		.dout({forward_last, wb_dat_o}), // output [32 : 0] dout
		.full(eth_buf_full), // output full
		.empty(eth_buf_empty)); // output empty
		
	reg [31:0] wb_addr_counter;
	reg wb_transfer_active;
	
	assign wb_we_o = 1;  // write only
	assign wb_bte_o = 0; // linear bursts
	
	assign eth_buf_rd = (wb_transfer_active) ? wb_ack_i : 0;
	
	always @(posedge wb_clk_i) begin
		if (wb_rst_i) begin
			wb_adr_o <= 0;
			wb_stb_o <= 0;
			wb_cyc_o <= 0;
			wb_cti_o <= 0; // cycle type 000 = classic, 010 incr. burst, 111 = end of burst
			wb_sel_o <= 4'b1111;
			wb_transfer_active <= 0;
			wb_addr_counter <= 0;
			wb_addr_ready_edge_buf <= 0;
			eth_rx_irq_flag <= 0;
		end else begin
			if (wb_transfer_active) begin
				wb_cyc_o <= 1;
				wb_stb_o <= 1;
				if (wb_ack_i == 1'b1) begin
					if (forward_last == 1'b0) begin
						wb_adr_o <= wb_addr_offset + wb_addr_counter;
						wb_addr_counter <= wb_addr_counter + 4;
					end else begin
						wb_cyc_o <= 0;
						wb_stb_o <= 0;
						wb_transfer_active <= 0;
						eth_rx_irq_flag <= 1;
					end
				end
			end else if (eth_buf_empty == 1'b0 && wb_addr_ready == 1'b1 && wb_addr_ready_edge_buf == 1'b0) begin
				wb_transfer_active <= 1;
				wb_adr_o <= wb_addr_offset + wb_addr_counter;
				wb_addr_counter <= wb_addr_counter + 4;
			end else if (wb_addr_ready == 1'b0) begin
				eth_rx_irq_flag <= 0;
			end
			wb_addr_ready_edge_buf <= wb_addr_ready;
		end
	end

	
endmodule
