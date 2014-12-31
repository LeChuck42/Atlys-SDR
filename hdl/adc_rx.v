`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:32:39 07/15/2014 
// Design Name: 
// Module Name:    adc_rx 
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
module adc_rx(
   input clk,
	input reset,
	
	input [1:0] adc_cha_p,
	input [1:0] adc_cha_n,

	input [1:0] adc_chb_p,
	input [1:0] adc_chb_n,
	
	input bit_clk_p,
	input bit_clk_n,
	
	input frame_sync_p,
	input frame_sync_n,
	
	output clk_adc,
	output data_we,
	output [31:0] data
    );

	wire [34:0] deserialized_data;
	reg frame_sync;
	
	reg bitslip_en;
	
	assign data[15:0] = {2'h0,deserialized_data[13:0]};
	assign data[31:16] = {2'h0,deserialized_data[27:14]};
	assign data_we = frame_sync;
	
  adc_interface adc_if
   (
  // From the system into the device
    .DATA_IN_FROM_PINS_P({frame_sync_p, adc_chb_p, adc_cha_p}), //Input pins
    .DATA_IN_FROM_PINS_N({frame_sync_n, adc_chb_n, adc_cha_n}), //Input pins
    .DATA_IN_TO_DEVICE(deserialized_data), //Output pins

    .BITSLIP(bitslip_en), //Input pin
    .CLK_IN_P(bit_clk_p),      // Differential clock from IOB
    .CLK_IN_N(bit_clk_n),      // Differential clock from IOB
    .CLK_DIV_OUT(clk_adc),   // Slow clock output
    .IO_RESET(reset)  //system reset
	);
	
	always @(posedge clk_adc) begin
	
		if (reset) begin
			frame_sync <= 0;
			bitslip_en <= 0;
		end else begin
			frame_sync <= ^deserialized_data[34:28];  // synched if frame signal is steady for one cycle
			
			if (bitslip_en == 0)
				bitslip_en <= ~^deserialized_data[34:28];
			else
				bitslip_en <= 0;
		end
	end
endmodule
