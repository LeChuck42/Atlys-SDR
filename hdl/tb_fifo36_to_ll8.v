`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:00:56 03/31/2011
// Design Name:   fifo36_to_ll8
// Module Name:   C:/Users/Administrator/Desktop/Xilinx/atlys_ethernet_test_v1/atlys_ethernet_test_v1/tb_fifo36_to_ll8.v
// Project Name:  atlys_ethernet_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo36_to_ll8
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_fifo36_to_ll8;

	// Inputs
	reg clk;
	reg reset;
	reg clear;
	reg [35:0] f36_data;
	reg f36_src_rdy_i;
	reg ll_dst_rdy_n;

	// Outputs
	wire f36_dst_rdy_o;
	wire [7:0] ll_data;
	wire ll_sof_n;
	wire ll_eof_n;
	wire ll_src_rdy_n;
	wire [31:0] debug;

	// Instantiate the Unit Under Test (UUT)
	fifo36_to_ll8 uut (
		.clk(clk), 
		.reset(reset), 
		.clear(clear), 
		.f36_data(f36_data), 
		.f36_src_rdy_i(f36_src_rdy_i), 
		.f36_dst_rdy_o(f36_dst_rdy_o), 
		.ll_data(ll_data), 
		.ll_sof_n(ll_sof_n), 
		.ll_eof_n(ll_eof_n), 
		.ll_src_rdy_n(ll_src_rdy_n), 
		.ll_dst_rdy_n(ll_dst_rdy_n), 
		.debug(debug)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		clear = 0;
		f36_data = 0;
		f36_src_rdy_i = 1;
		ll_dst_rdy_n = 0;

		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;

		#10;
		f36_data = 36'b0001_00000000_11111111_00000000_11111111;
		
		#10;
		f36_data = 36'b0000_11111111_00000000_11111111_00000000;
		
		#10;
		f36_data = 36'b0000_00000000_11111111_00000000_11111111;
		
		#10;
		f36_data = 36'b0000_11111111_00000000_11111111_00000000;
		

		// Add stimulus here

	end
	
	always begin
		#5;
		clk = ~clk;
	end
      
endmodule

