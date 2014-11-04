`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Joel Williams
// 
// Create Date:    01:28:05 07/12/2011 
// Design Name: 
// Module Name:    gemac_configure 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// This module acts as a Wishbone master and configures the MAC.
// It performs the following tasks:
// - Reset the PHY
// - Set MDIO clock divider to establish correct communication rate
// - Set the PHY to "GMII to Copper" mode (it is necessary to read the existing
//   value from register 27 first to preserve the state of the other bits)
// - Poll the PHY status and wait until Ethernet negotiation is complete.
//
// TODO: Configure MAC filtering
//
//////////////////////////////////////////////////////////////////////////////////
module gemac_configure
	#(
		parameter PHY_ADDR = 5'd7 // MDIO interface address, valid for the Atlys
	) (
	input wire clk,
	output reg wb_rst,
	output reg wb_stb,
	output reg wb_cyc,
	input wire wb_ack,
	output reg wb_we,
	output reg [7:0] wb_adr,
	output reg [31:0] wb_dat_o,
	input wire [31:0] wb_dat_i,
	output reg phy_reset,
	input wire reset,
	output reg ready,
	output wire [3:0] debug
	);


	(* fsm_encoding = "user" *)
	reg [4:0] state = 0;
	reg [23:0] count = 0;
	
	assign debug[0] = (state == 0); // Resetting
	assign debug[1] = (state == 25); // Unexpected status result or PHY not detected
	assign debug[2] = (state == 26); // Waiting for auto-negotiation to complete
	assign debug[3] = (state == 27); // Done

	reg [31:0] mii_result;

	always @(posedge clk) begin
	if (reset) begin
		state <= 0;
		count <= 0;
		ready <= 0;
	end else begin
		case(state)
		
		// Reset the PHY for > 10 ms
		0: begin
			phy_reset <= 0; // active low
			wb_rst <= 1;
			count <= count + 1'b1;
			if (count[23] == 1)
				next_state();
			end
		1: begin
			count <= 24'd0;
			next_state();
			end
		2: begin // Wait for the chip to settle
			phy_reset <= 1;
			count <= count + 1'b1;
			if (count[23] == 1) begin
				next_state();
				wb_rst <= 0;
			end
			end
			
		// Set the MDIO clock divider
		3: send_wb_command(8'd20, 32'd24); // Set MDIO clock divider to 24 (at 150 MHz = 6.25 MHz)
		4: wait_for_wb_ack(); // Wait for WB acknowledgement, then go to the next state
		
		5: send_wb_command( {6'd6, 2'd0}, {5'd27, 3'd0, PHY_ADDR}); // Set to GMII mode, first by reading register ADDRESS, Reg 27 to preserve its contents.
		6: wait_for_wb_ack();
		7: send_wb_command( {6'd8, 2'd0}, 32'd6); // COMMAND = RSTAT
		8: wait_for_wb_ack();
		9: send_wb_addr({6'd9, 2'd0}); // Read MIISTATUS
		10: if (~wb_dat_i[1]) // Wait until not busy
			next_state();
		
		// Set MAC receive mode to ucast only - don't care about mcast/bcast for this UART demo
		11: send_wb_command(8'd0, 8'b010_0101); // misc_settings
		12: wait_for_wb_ack();
		
		// Now write to GMII mode register
		13: begin
			mii_result <= wb_dat_i;
			send_wb_command({6'd6, 2'd0}, {5'd27, 3'd0, PHY_ADDR}); // ADDRESS = Reg 27
			end
		14: wait_for_wb_ack();
		15: send_wb_command({6'd8, 2'd0}, {mii_result[15:4], 4'b1111}); // COMMAND = TxData, HWCFG_MODE = GMII to Copper
		16: wait_for_wb_ack();
		
		// Now wait for auto-negotiation to finish. Check by polling the PHY's status register.
		17: begin
			count <= 0;
			send_wb_command({6'd6, 2'd0}, {5'd1, 3'd0, PHY_ADDR}); // Read status register, ADDRESS = Reg 1
			end
		18: wait_for_wb_ack();
		19: send_wb_command( {6'd8, 2'd0}, 32'd2); // COMMAND = RSTAT
		20: wait_for_wb_ack();
		21: send_wb_addr({6'd9, 2'd0}); // MIISTATUS
		22: if (~wb_dat_i[1]) next_state(); // Wait until not busy
		23: send_wb_read_command({6'd10, 2'd0}); // Read MIIRX_DATA
		24: wait_for_wb_ack_and_read();
		25: if (mii_result[10:9] == 2'b00) // Check for bits that should always be set - note, need to check the implications of this, since it'll lock up here if the comparison fails
				next_state();
		26: if (mii_result[5]) // Negotiation complete
				next_state();
			else begin	// Otherwise, wait for a while and try again.
				count <= count + 1'b1;
				if (count[23])
					state <= 17;
			end
			
		// Signal that Ethernet negotiation is now complete
		27: ready <= 1; 
		
		default:
			state <= 0;
		endcase
		end
	end
	
	
	// These tasks encapsulate some of the complexity of the Wishbone bus
			
	task send_wb_addr;
		input [7:0] addr;
	begin
		wb_adr <= addr;
		next_state();
	end
	endtask
	
	task send_wb_command;
		input [7:0] addr;
		input [31:0] dat;
	begin
		wb_adr <= addr;
		wb_dat_o <= dat;
		wb_stb <= 1;
		wb_cyc <= 1;
		wb_we <= 1;
		next_state();
	end
	endtask
	
	task send_wb_read_command;
		input [7:0] addr;
	begin
		wb_adr <= addr;
		wb_we <= 0;
		wb_stb <= 1;
		wb_cyc <= 1;
		next_state();
	end
	endtask
	
	task wait_for_wb_ack;
	begin
		if (wb_ack) begin
			wb_stb <= 0;
			wb_cyc <= 0;
			wb_we <= 0;
			next_state();
		end
	end
	endtask
	
	task wait_for_wb_ack_and_read;
	begin
		if (wb_ack) begin
			wb_stb <= 0;
			wb_cyc <= 0;
			wb_we <= 0;
			mii_result <= wb_dat_i;
			next_state();
		end
	end
	endtask
	
	task next_state;
	begin
		state <= state + 1'b1;
	end
	endtask
	
endmodule
