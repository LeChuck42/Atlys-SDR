`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:13:34 12/08/2011
// Design Name:   packet_sender
// Module Name:   C:/Users/Administrator/Desktop/Xilinx/atlys_ethernet_test_v1/atlys_ethernet_test_v1/tb_packet_sender.v
// Project Name:  atlys_ethernet_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: packet_sender
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_packet_sender;

	// Inputs
	reg clk;
	reg reset;
	reg wr_dst_rdy_i;
	reg [7:0] packet_size_i;
	reg start;

	// Outputs
	wire [3:0] wr_flags_o;
	wire [31:0] wr_data_o;
	wire wr_src_rdy_o;

	// Instantiate the Unit Under Test (UUT)
	packet_sender uut (
		.clk(clk), 
		.reset(reset), 
		.wr_flags_o(wr_flags_o), 
		.wr_data_o(wr_data_o), 
		.wr_src_rdy_o(wr_src_rdy_o), 
		.wr_dst_rdy_i(wr_dst_rdy_i), 
		.packet_size_i(packet_size_i), 
		.start(start)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		wr_dst_rdy_i = 0;
		packet_size_i = 8'b0001_0000;
		start = 0;

		#100;
		
		reset <= 0;
		wr_dst_rdy_i <= 1;
		
		@(posedge clk);
		start <= 1;
		
		@(posedge clk);
		start <= 0;
		
		#2000;

		// Simulate a pause flag from the MAC
		wr_dst_rdy_i <= 0;
		
		#200;
		wr_dst_rdy_i <= 1;
		
		// Wait for EOF
		wait(wr_flags_o == 4'b0010);
		
		@(posedge clk);
		@(posedge clk);
		
		$stop;
	end
      
	always begin	
		#10;
		clk = ~clk;
	end

endmodule

