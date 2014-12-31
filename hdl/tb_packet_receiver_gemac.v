`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Joel Williams
//
// Create Date:   23:14:49 12/11/2011
// Design Name:   tb_packet_receiver_gemac
// Target Device:  
// Tool versions:  
// Description: 
//
// Test bench for the packet receiver that incorporates the full GEMAC RX chain
// so that the FIFOs can be exercised completely.
//
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_packet_receiver_gemac;

	// Inputs
	reg clk125;
	reg reset;
	reg GMII_RX_CLK;
	reg GMII_RX_DV;
	reg GMII_RX_ER;
	reg [7:0] GMII_RXD;
	reg sys_clk;
	wire rx_f36_dst_rdy;
	reg [35:0] tx_f36_data;
	reg tx_f36_src_rdy;
	reg wb_clk;
	reg wb_rst;
	reg wb_stb;
	reg wb_cyc;
	reg wb_we;
	reg [7:0] wb_adr;
	reg [31:0] wb_dat_i;

	// Outputs
	wire GMII_GTX_CLK;
	wire GMII_TX_EN;
	wire GMII_TX_ER;
	wire [7:0] GMII_TXD;
	wire [35:0] rx_f36_data;
	wire rx_f36_src_rdy;
	wire tx_f36_dst_rdy;
	wire wb_ack;
	wire [31:0] wb_dat_o;
	wire mdc;
	wire [79:0] debug;

	// Bidirs
	wire mdio;
	
	reg [7:0] pkt_rom [0:127];
	
	
	wire [7:0] data_out;
	wire data_out_en;

	// Instantiate the Unit Under Test (UUT)
	simple_gemac_wrapper uut_sgw (
		.clk125(clk125), 
		.reset(reset), 
		.GMII_GTX_CLK(GMII_GTX_CLK), 
		.GMII_TX_EN(GMII_TX_EN), 
		.GMII_TX_ER(GMII_TX_ER), 
		.GMII_TXD(GMII_TXD), 
		.GMII_RX_CLK(GMII_RX_CLK), 
		.GMII_RX_DV(GMII_RX_DV), 
		.GMII_RX_ER(GMII_RX_ER), 
		.GMII_RXD(GMII_RXD), 
		.sys_clk(sys_clk), 
		.rx_f36_data(rx_f36_data), 
		.rx_f36_src_rdy(rx_f36_src_rdy), 
		.rx_f36_dst_rdy(rx_f36_dst_rdy), 
		.tx_f36_data(tx_f36_data), 
		.tx_f36_src_rdy(tx_f36_src_rdy), 
		.tx_f36_dst_rdy(tx_f36_dst_rdy), 
		.wb_clk(wb_clk), 
		.wb_rst(wb_rst), 
		.wb_stb(wb_stb), 
		.wb_cyc(wb_cyc), 
		.wb_ack(wb_ack), 
		.wb_we(wb_we), 
		.wb_adr(wb_adr), 
		.wb_dat_i(wb_dat_i), 
		.wb_dat_o(wb_dat_o), 
		.mdio(mdio), 
		.mdc(mdc), 
		.debug(debug)
	);

	packet_receiver uut_pr (
		.clk(sys_clk), 
		.reset(reset), 
		.rd_flags_i(rx_f36_data[35:32]), 
		.rd_data_i(rx_f36_data[31:0]), 
		.rd_src_rdy_i(rx_f36_src_rdy), 
		.rd_dst_rdy_o(rx_f36_dst_rdy), 
		.data_out_en(data_out_en), 
		.data_out(data_out)
	);
	
	initial begin
		// Initialize Inputs
		clk125 = 0;
		reset = 1;
		GMII_RX_CLK = 0;
		GMII_RX_DV = 0;
		GMII_RX_ER = 0;
		GMII_RXD = 0;
		sys_clk = 0;
		tx_f36_data = 0;
		tx_f36_src_rdy = 0;
		wb_clk = 0;
		wb_rst = 1;
		wb_stb = 0;
		wb_cyc = 0;
		wb_we = 0;
		wb_adr = 0;
		wb_dat_i = 0;
		

		// Wait 100 ns for global reset to finish
		#100;
        
		reset = 0;
		wb_rst = 0;
		
		#2000;
		

		ReceivePacketFromFile("test_packet_small.mem", 72);
		
		#10000;
		
		ReceivePacketFromFile("test_packet_larger.mem", 72);
		
		#2000;
		
		$stop;
		
	end
   
	
	always begin
		#8; GMII_RX_CLK = ~GMII_RX_CLK;
		#8; clk125 =~ clk125;
		#10; sys_clk = ~sys_clk; 
		#10; wb_clk = ~wb_clk;
	end
	
	
	task ReceivePacketFromFile;
		input [8*63:0] filename;
		input [31:0] data_len;
		reg [31:0] count;
	begin
		$display("%d: Sending packet from file %s", $time, filename);
		$readmemh(filename, pkt_rom);
		count <= 0;
		#1;
		while (count < (data_len-1))
		begin
			@(posedge GMII_RX_CLK);
			GMII_RX_DV <= 1;
			GMII_RXD <= pkt_rom[count];
			count <= count + 1'b1;
		end
		
		@(posedge GMII_RX_CLK);
		
		GMII_RX_DV <= 0;
		GMII_RXD <= 0;
		
	end	
	endtask
	
endmodule

