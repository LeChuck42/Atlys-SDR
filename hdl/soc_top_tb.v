`timescale 1ns / 1ps
`default_nettype none
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:22:06 10/27/2014
// Design Name:   ethernet_test_top
// Module Name:   
// Project Name:  atlys_ethernet_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: 
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module soc_top_tb;

	// Inputs
	reg clk_100_pin;
	reg clk_10_pin;
	reg MII_TX_CLK_pin;
	wire [7:0] GMII_RXD_pin;
	wire GMII_RX_DV_pin;
	reg GMII_RX_ER_pin;
	reg GMII_RX_CLK_pin;
	reg [1:0] adc_cha_p;
	wire [1:0] adc_cha_n;
	reg [1:0] adc_chb_p;
	wire [1:0] adc_chb_n;
	reg adc_bit_clk_p;
	wire adc_bit_clk_n;
	reg adc_frame_sync_p;
	wire adc_frame_sync_n;
	reg [7:0] sw;
	reg [5:0] btn;
	wire VHDCI_MUX_IN_P;
	wire VHDCI_MUX_IN_N;
	reg rs232_rx;

	// Outputs
	wire PhyResetOut_pin;
	wire [7:0] GMII_TXD_pin;
	wire GMII_TX_EN_pin;
	wire GMII_TX_ER_pin;
	wire GMII_TX_CLK_pin;
	wire MDC_pin;
	wire [7:0] leds;
	wire VHDCI_MUX_OUT_P;
	wire VHDCI_MUX_OUT_N;
	wire VHDCI_MUX_CLK_P;
	wire VHDCI_MUX_CLK_N;
	wire rs232_tx;
	
	
	// ram
	wire [12:0] ddr2_a;
	wire [2:0] ddr2_ba;
	wire ddr2_ras_n;
	wire ddr2_cas_n;
	wire ddr2_we_n;
	wire ddr2_rzq;
	wire ddr2_zio;
	wire ddr2_odt;
	wire ddr2_cke;
	wire ddr2_dm;
	wire ddr2_udm;
	wire [15:0] ddr2_dq;
	wire ddr2_dqs;
	wire ddr2_dqs_n;
	wire ddr2_udqs;
	wire ddr2_udqs_n;
	wire ddr2_ck;
	wire ddr2_ck_n;
	
	// flash
	
	wire flash_sck;
	wire flash_csn;
	wire [3:0] flash_io;
	
	// Bidirs
	wire MDIO_pin;

	glbl glbl ();
	// Instantiate the Unit Under Test (UUT)
	soc_top #(
	.SIMULATION("TRUE")
	)
	uut (
		.clk_100_pin(clk_100_pin), 
		.PhyResetOut_pin(PhyResetOut_pin), 
		.MII_TX_CLK_pin(MII_TX_CLK_pin), 
		.GMII_TXD_pin(GMII_TXD_pin), 
		.GMII_TX_EN_pin(GMII_TX_EN_pin), 
		.GMII_TX_ER_pin(GMII_TX_ER_pin), 
		.GMII_TX_CLK_pin(GMII_TX_CLK_pin), 
		.GMII_RXD_pin(GMII_RXD_pin), 
		.GMII_RX_DV_pin(GMII_RX_DV_pin), 
		.GMII_RX_ER_pin(GMII_RX_ER_pin), 
		.GMII_RX_CLK_pin(GMII_RX_CLK_pin), 
		.MDC_pin(MDC_pin), 
		.MDIO_pin(MDIO_pin), 
		.adc_cha_p(adc_cha_p), 
		.adc_cha_n(adc_cha_n), 
		.adc_chb_p(adc_chb_p), 
		.adc_chb_n(adc_chb_n), 
		.adc_bit_clk_p(adc_bit_clk_p), 
		.adc_bit_clk_n(adc_bit_clk_n), 
		.adc_frame_sync_p(adc_frame_sync_p), 
		.adc_frame_sync_n(adc_frame_sync_n), 
		.leds(leds), 
		.sw(sw), 
		.btn(btn), 
		.VHDCI_MUX_OUT_P(VHDCI_MUX_OUT_P), 
		.VHDCI_MUX_OUT_N(VHDCI_MUX_OUT_N), 
		.VHDCI_MUX_CLK_P(VHDCI_MUX_CLK_P), 
		.VHDCI_MUX_CLK_N(VHDCI_MUX_CLK_N), 
		.VHDCI_MUX_IN_P(VHDCI_MUX_IN_P), 
		.VHDCI_MUX_IN_N(VHDCI_MUX_IN_N), 
		.rs232_tx(rs232_tx), 
		.rs232_rx(rs232_rx),
		.ddr2_a(ddr2_a),
		.ddr2_ba(ddr2_ba),
		.ddr2_ras_n(ddr2_ras_n),
		.ddr2_cas_n(ddr2_cas_n),
		.ddr2_we_n(ddr2_we_n),
		.ddr2_rzq(ddr2_rzq),
		.ddr2_zio(ddr2_zio),
		.ddr2_odt(ddr2_odt),
		.ddr2_cke(ddr2_cke),
		.ddr2_dm(ddr2_dm),
		.ddr2_udm(ddr2_udm),
		.ddr2_dq(ddr2_dq),
		.ddr2_dqs(ddr2_dqs),
		.ddr2_dqs_n(ddr2_dqs_n),
		.ddr2_udqs(ddr2_udqs),
		.ddr2_udqs_n(ddr2_udqs_n),
		.ddr2_ck(ddr2_ck),
		.ddr2_ck_n(ddr2_ck_n),
		/*
		.tdo_pad_o(),
		.tms_pad_i(),
		.tck_pad_i(),
		.tdi_pad_i(),
		*/
		.flash_spi_csn(flash_csn),
		.flash_spi_sck(flash_sck),
		.flash_spi_io(flash_io)

	);
	
	ddr2_model_c3 ddr2_model_c3_inst (
		.ck(ddr2_ck),
		.ck_n(ddr2_ck_n),
		.cke(ddr2_cke),
		.cs_n(1'b0),
		.ras_n(ddr2_ras_n),
		.cas_n(ddr2_cas_n),
		.we_n(ddr2_we_n),
		.dm_rdqs({ddr2_udm, ddr2_dm}),
		.ba(ddr2_ba),
		.addr(ddr2_a),
		.dq(ddr2_dq),
		.dqs({ddr2_udqs, ddr2_dqs}),
		.dqs_n({ddr2_udqs_n, ddr2_dqs_n}),
		.rdqs_n(),
		.odt(ddr2_odt)
	);

	wire [3:0] delayed_io;
	wire delayed_csn;
	wire delayed_sck;
	assign #3 delayed_csn = flash_csn;
	assign #1 delayed_sck = flash_sck;
	
	genvar i;
	generate
	for (i=0; i<4; i=i+1)
		begin: gen_delay_wire
			bidir_delay #(.Tab(3), .Tba(3)) bidir_delay_wire (
				.a(flash_io[i]),
				.b(delayed_io[i]));
		end
	endgenerate
	
	defparam soc_top_tb.flash0.memory_file = "flash0_mem.txt";
	N25Qxxx flash0 (
		.S(delayed_csn),
		.C(delayed_sck),
		.HOLD_DQ3(delayed_io[3]),
		.DQ0(delayed_io[0]),
		.DQ1(delayed_io[1]),
		.Vcc(3300),
		.Vpp_W_DQ2(delayed_io[2]));
	
		   // Loopback
   assign GMII_RX_DV_pin  = GMII_TX_EN_pin;
   assign GMII_RXD_pin    = GMII_TXD_pin;
   wire GMII_RX_CLK   = GMII_TX_CLK_pin;
	
	assign VHDCI_MUX_IN_N = ~VHDCI_MUX_IN_P;
	assign adc_frame_sync_n = ~adc_frame_sync_p;
	assign adc_bit_clk_n = ~adc_bit_clk_p;
	assign adc_cha_n = ~adc_cha_p;
	assign adc_chb_n = ~adc_chb_p;
	reg mux_clk_en;
	reg [7:0] mux_data;
	reg [2:0] mux_counter;
	initial begin
		// Initialize Inputs
		clk_100_pin = 0;
		clk_10_pin = 0;
		MII_TX_CLK_pin = 0;
		GMII_RX_ER_pin = 0;
		GMII_RX_CLK_pin = 0;
		adc_cha_p = 0;
		adc_chb_p = 0;
		adc_bit_clk_p = 0;
		adc_frame_sync_p = 0;
		mux_clk_en = 1;
		sw = 0;
		rs232_rx = 1;
		mux_data = 8'h01;
		mux_counter = 0;
		btn = 6'b111110;
		// Wait for global reset to finish
		#10000;
		btn = 6'b111111;
		/*#500;
		mux_clk_en = 0;
		#1000;
		mux_clk_en = 1;*/
		/*
		#20000;
		btn = 6'b111110;
		#1234;
		btn = 6'b111111;
		#20000;
		btn = 6'b111110;
		#2345;
		btn = 6'b111111;
		#20000;
		btn = 6'b111110;
		#123;
		btn = 6'b111111;
		#20000;
		btn = 6'b111110;
		#1500;
		*/
      /*
		rs232_send(8'h52); // set rising trigger
		#234;
		rs232_send(8'h00);
		rs232_send(8'h00);
		rs232_send(8'h00);
		rs232_send(8'h00);
		rs232_send(8'h00);
		
		rs232_send(8'h00);
		rs232_send(8'h00);
		rs232_send(8'h00);
		rs232_send(8'h40);
		rs232_send(8'h00);
		
		#100;*/
		rs232_send(8'h41); // arm scope
	end
	
	task rs232_send;
		input [7:0] data;
		reg[4:0] i;
		begin
			rs232_rx = 0;
			#1000;
			for (i=0; i<8; i=i+1) begin
				rs232_rx = data[i];
				#1000;
			end
			rs232_rx = 1;
			#1000;
		end
	endtask
      
	always begin
		#4;
		GMII_RX_CLK_pin <= ~GMII_RX_CLK_pin;
	end
	reg mux_clk;
	reg rx_delayed, tx_delayed;
	wire rx_internal;
	
	always @(VHDCI_MUX_CLK_P or mux_clk_en)
		if (mux_clk_en)
			mux_clk <= #0.8 VHDCI_MUX_CLK_P;
		else
			mux_clk <= 1'b0;
			
	always @(rx_internal)
		rx_delayed <= #0.8 rx_internal;
		
	always @(VHDCI_MUX_OUT_P)
		tx_delayed <= #0.9 VHDCI_MUX_OUT_P;
		
	assign VHDCI_MUX_IN_P = rx_delayed;
	main rx_sim_inst (
		.CLK_FPGA(1'b0),
		.MUX_CLK(mux_clk),
		.MUX_IN(tx_delayed),
		.MUX_OUT(rx_internal),
		.FPGA_PGOOD(1'b1),
		.DAC_ALARM(1'b0)
		
		);
		
	always begin
		#5;
		clk_100_pin = ~clk_100_pin;
	end
	
	always begin
		#50;
		clk_10_pin = ~clk_10_pin;
	end
	
endmodule

