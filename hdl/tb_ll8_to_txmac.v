
`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:21:23 03/31/2011
// Design Name:   ll8_to_txmac
// Module Name:   C:/Users/Administrator/Desktop/Xilinx/atlys_ethernet_test_v1/atlys_ethernet_test_v1/tb_ll8_to_txmac.v
// Project Name:  atlys_ethernet_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ll8_to_txmac
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_ll8_to_txmac;

	// Inputs
	reg clk;
	reg reset;
	reg clear;
	reg [7:0] ll_data;
	reg ll_sof;
	reg ll_eof;
	reg ll_src_rdy;
	reg tx_ack;

	// Outputs
	wire ll_dst_rdy;
	wire [7:0] tx_data;
	wire tx_valid;
	wire tx_error;
	wire [2:0] debug;

	// Instantiate the Unit Under Test (UUT)
	ll8_to_txmac uut (
		.clk(clk), 
		.reset(reset), 
		.clear(clear), 
		.ll_data(ll_data), 
		.ll_sof(ll_sof), 
		.ll_eof(ll_eof), 
		.ll_src_rdy(ll_src_rdy), 
		.ll_dst_rdy(ll_dst_rdy), 
		.tx_data(tx_data), 
		.tx_valid(tx_valid), 
		.tx_error(tx_error), 
		.tx_ack(tx_ack), 
		.debug(debug)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		clear = 0;
		ll_data = 0;
		ll_sof = 0;
		ll_eof = 0;
		ll_src_rdy = 0;
		tx_ack = 0;

		// Wait 100 ns for global reset to finish
		#100;
		reset = 0;
		
		@(posedge clk);
		
		ll_data = 1;
		tx_ack = 1;
		ll_src_rdy = 1;
		
		repeat(50) begin
			@(posedge clk);
			ll_data = ll_data + 1'b1;
			tx_ack = 0;
      end
		
		@(posedge clk);
		ll_eof = 1;
		ll_data = ll_data + 1'b1;
		
		@(posedge clk);
		ll_eof = 0;
		
		// Add stimulus here

	end
      
	always begin
		#5;
		clk = ~clk;
	end
endmodule

