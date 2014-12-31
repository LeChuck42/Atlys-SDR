`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:55:15 05/02/2011
// Design Name:   ip_header_checksum
//
// Verilog Test Fixture created by ISE for module: ip_header_checksum
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_ip_header_checksum;

	// Inputs
	reg clk;
	reg [31:0] header;
	reg reset;

	// Outputs
	wire [15:0] checksum;

	// Instantiate the Unit Under Test (UUT)
	ip_header_checksum uut (
		.clk(clk), 
		.checksum(checksum), 
		.header(header), 
		.reset(reset)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		header = 0;
		reset = 1;

		// Wait 100 ns for global reset to finish
		#100;
      @(posedge clk);
		reset = 0;
		header = 32'h4500_0030;
		
		@(posedge clk);
		header = 32'h4422_4000;
		
		@(posedge clk);
		header = 32'h8006_0000;
		
		@(posedge clk);
		header = 32'h8c7c_19ac;
		
		@(posedge clk);
		header = 32'hae24_1e2b;
		
		@(posedge clk);
		
		@(posedge clk);
		$display("%h - should be 442E", checksum);

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		$display("%h - should still be 442E", checksum);
		
		
		// Verifying a header with a valid checksum should give ffff.
		
		reset = 1;
		
		@(posedge clk);
		reset = 0;
		header = 32'h4500_0030;
		
		@(posedge clk);
		header = 32'h4422_4000;
		
		@(posedge clk);
		header = 32'h8006_442e;
		
		@(posedge clk);
		header = 32'h8c7c_19ac;
		
		@(posedge clk);
		header = 32'hae24_1e2b;
		
		@(posedge clk);
		
		@(posedge clk);
		$display("%h - should be FFFF", checksum);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		$display("%h - should still be FFFF", checksum);
		
		$stop;

		
		
		
		// Add stimulus here

	end
      
	always begin	
		#10;
		clk = ~clk;
	end
endmodule

