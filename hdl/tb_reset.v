`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:54:07 12/09/2011
// Design Name:   reset
// Module Name:   C:/Users/Administrator/Desktop/Xilinx/atlys_ethernet_test_v1/atlys_ethernet_test_v1/tb_reset.v
// Project Name:  atlys_ethernet_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: reset
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_reset;

	// Inputs
	reg clk;
	reg pll_lock;
	reg clk_150;
	reg ext_reset;

	// Outputs
	wire rst_100;
	wire rst_150;

	// Instantiate the Unit Under Test (UUT)
	reset uut (
		.clk(clk), 
		.pll_lock(pll_lock), 
		.rst_1(rst_100), 
		.clk_2(clk_150), 
		.rst_2(rst_150), 
		.ext_reset(ext_reset)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		pll_lock = 0;
		clk_150 = 0;
		ext_reset = 0;

		// Wait 100 ns for global reset to finish
		#100;
      pll_lock = 1'b1;
		// Add stimulus here

		#200;
		ext_reset = 1'b1;
		
		repeat(3)
			@(posedge clk);
		
		ext_reset = 0;
		#100;
		
		$stop;
	end
      
	always begin
		#5; clk = ~clk;
	end
	
	always begin
		#4; clk_150 = ~clk_150;
	end
endmodule

