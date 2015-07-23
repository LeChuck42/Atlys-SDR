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
   input wire clk,
	input wire reset,
	
	input wire [1:0] adc_cha_p,
	input wire [1:0] adc_cha_n,

	input wire [1:0] adc_chb_p,
	input wire [1:0] adc_chb_n,
	
	input wire bit_clk_p,
	input wire bit_clk_n,
	
	input wire frame_sync_p,
	input wire frame_sync_n,
	
	output wire clk_adc,
	output wire data_we,
	output wire [31:0] data,
	output reg [7:0] debug
    );

	wire [34:0] deserialized_data;
	reg synchronized;
	
	reg bitslip_en;
	
	assign data_we = synchronized;
	
	wire [13:0] data_a;
	wire [13:0] data_b;
	wire [6:0] frame_sync;
	
	assign data_a = {
		deserialized_data[0],
		deserialized_data[5],
		deserialized_data[10],
		deserialized_data[15],
		deserialized_data[20],
		deserialized_data[25],
		deserialized_data[30],
		deserialized_data[1],
		deserialized_data[6],
		deserialized_data[11],
		deserialized_data[16],
		deserialized_data[21],
		deserialized_data[26],
		deserialized_data[31] };
		
	assign data_b = {
		deserialized_data[2],
		deserialized_data[7],
		deserialized_data[12],
		deserialized_data[17],
		deserialized_data[22],
		deserialized_data[27],
		deserialized_data[32],
		deserialized_data[3],
		deserialized_data[8],
		deserialized_data[13],
		deserialized_data[18],
		deserialized_data[23],
		deserialized_data[28],
		deserialized_data[33] };
		
	assign frame_sync = {
		deserialized_data[4],
		deserialized_data[9],
		deserialized_data[14],
		deserialized_data[19],
		deserialized_data[24],
		deserialized_data[29],
		deserialized_data[34] };
	
	assign data[15:0] = {2'h0,data_a};
	assign data[31:16] = {2'h0,data_b};
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
	
	reg [3:0] bitslip_delay;
	
	always @(posedge clk_adc or posedge reset) begin
	
		if (reset) begin
			synchronized <= 0;
			bitslip_en <= 0;
			bitslip_delay <= 0;
			debug <= 8'h00;
		end else begin
			bitslip_delay <= {bitslip_delay[2:0], bitslip_en};
			bitslip_en <= 0;
			if (frame_sync == 7'b0000000 || frame_sync == 7'b1111111) begin
				synchronized <= 1'b1;  // synched if frame signal is steady for one cycle
			end else begin
				if (bitslip_en == 1'b0 && bitslip_delay == 4'h0)
					bitslip_en <= 1'b1;
				
				synchronized <= 1'b0;
			end
			debug <= {frame_sync, bitslip_en};
		end
	end
	
endmodule
