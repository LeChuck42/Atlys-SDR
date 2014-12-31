`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:40:46 05/02/2011 
// Design Name: 
// Module Name:    ip_header_checksum 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Simple module that calculates IP header checksum. Input five 32-bit words
// with the checksum field set to 16'h0. Result is generated two clock cycles
// after the final word is input, and is then held until reset.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ip_header_checksum(
	input clk,
	output wire [15:0] checksum,
	input wire [31:0] header,
	input wire enab,
	input wire reset
    );

	reg [31:0] checksum_int;
	
	always @(posedge clk)
	if (reset) begin
		checksum_int <= 0;
		//header_count <= 0;
	end
	else
		if (enab)
		begin
			//header_count <= header_count + 1'b1;
			checksum_int <= checksum_int + header[15:0] + header[31:16];
		end
		
	assign checksum = ~(checksum_int[31:16] + checksum_int[15:0]);
	
endmodule
