`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:56:51 04/01/2011
// Design Name:   fifo_2clock_cascade
// Module Name:   C:/Users/Administrator/Desktop/Xilinx/atlys_ethernet_test_v1/atlys_ethernet_test_v1/tb_fifo_2clock_cascade.v
// Project Name:  atlys_ethernet_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo_2clock_cascade
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_fifo_2clock_cascade;

	// Inputs
	reg wclk;
	reg [35:0] datain;
	reg src_rdy_i;
	reg rclk;
	reg dst_rdy_i;
	reg arst;

	// Outputs
	wire dst_rdy_o;
	wire [15:0] space;
	wire [35:0] dataout;
	wire src_rdy_o;
	wire [15:0] occupied;

	// Instantiate the Unit Under Test (UUT)
	fifo_2clock_cascade uut (
		.wclk(wclk), 
		.datain(datain), 
		.src_rdy_i(src_rdy_i), 
		.dst_rdy_o(dst_rdy_o), 
		.space(space), 
		.rclk(rclk), 
		.dataout(dataout), 
		.src_rdy_o(src_rdy_o), 
		.dst_rdy_i(dst_rdy_i), 
		.occupied(occupied), 
		.arst(arst)
	);

	initial begin
		// Initialize Inputs
		wclk = 0;
		datain = 0;
		src_rdy_i = 0;
		rclk = 0;
		dst_rdy_i = 0;
		arst = 1;

		// Wait 100 ns for global reset to finish
		#100;
		
		@(posedge rclk)
		dst_rdy_i = 1;
      
		#50;
		@(posedge wclk);
		arst =0;
		src_rdy_i = 1;
		
		
	end

	always begin
		@(posedge wclk);
		if (dst_rdy_o)
			datain = datain + 1'b1;
	end
	
	always begin
		#4; rclk = ~rclk; // 125 MHz
	end
	
	always begin
		#3.333; wclk = ~wclk; // 150 MHz
	end
      
endmodule

