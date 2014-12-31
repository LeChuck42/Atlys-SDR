`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:31:22 12/09/2011 
// Design Name: 
// Module Name:    reset 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Reset supervisor that waits for PLL lock, and synchronises reset signals to
// the 150 MHz clock domain
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module reset(

	input clk,
	input pll_lock,
	output rst_1,
	
	input clk_2,
	output rst_2,
	input ext_reset
	
    );


	parameter RST_DELAY = 3;
	
	reg rst_1_reg = 1; // Hold in reset at startup
	
	reg [RST_DELAY-1:0] rst_dly = {RST_DELAY{1'b1}};
	
	// Note, you could inject a signal such as a SPST switch input instead of the zero
	// to allow you to reset the PLL manually.
	always @(posedge clk)
		if (pll_lock)
			{rst_1_reg, rst_dly} <= {rst_dly, 1'b0};
	
	assign rst_1 = rst_1_reg;
	
	// Get PLL lock signal into second clock domain
	reg [1:0] pll_lock_q;
	always @(posedge clk)
		pll_lock_q <= {pll_lock_q[0], pll_lock};
	
	// Get reset into the second clock domain
	
	reg rst_2_reg = 1'b1;
	reg [RST_DELAY-1:0] rst_dly_2 = {RST_DELAY{1'b1}};
	
	always @(posedge clk_2)
		if (pll_lock_q[1])
			{rst_2_reg, rst_dly_2} <= {rst_dly_2, ext_reset};
	
	assign rst_2 = rst_2_reg;
	
endmodule
