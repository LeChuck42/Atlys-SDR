`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Joel Williams
// 
// Create Date:    11:23:07 02/18/2011 
// Design Name: 
// Module Name:    ethernet_test_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Simple test framework for the Atlys' 88E1111 chip
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module soc_top # (
	SIMULATION = "FALSE"
	)
	(
	input wire clk_100_pin,
	
	// Ethernet
	output wire PhyResetOut_pin,
	input wire MII_TX_CLK_pin, // 25 MHz clock for 100 Mbps - not used here
	output reg [7:0] GMII_TXD_pin, 
	output reg GMII_TX_EN_pin,
	output reg GMII_TX_ER_pin,
	output wire GMII_TX_CLK_pin,
	input wire [7:0] GMII_RXD_pin, 
	input wire GMII_RX_DV_pin,
	input wire GMII_RX_ER_pin,
	input wire GMII_RX_CLK_pin,
	output wire MDC_pin,
	inout wire MDIO_pin,
	
	input wire [1:0] adc_cha_p,
	input wire [1:0] adc_cha_n,

	input wire [1:0] adc_chb_p,
	input wire [1:0] adc_chb_n,
	
	input wire adc_bit_clk_p,
	input wire adc_bit_clk_n,
	
	input wire adc_frame_sync_p,
	input wire adc_frame_sync_n,
	
	output wire [7:0] leds,
	input wire [7:0] sw,
	input wire [5:0] btn,
	
	// MUX Interface (VHDCI)
	output wire VHDCI_MUX_OUT_P,
	output wire VHDCI_MUX_OUT_N,

	output wire VHDCI_MUX_CLK_P,
	output wire VHDCI_MUX_CLK_N,

	input wire VHDCI_MUX_IN_P,
	input wire VHDCI_MUX_IN_N,
	
	input wire DAC_CLK_REF_P,
	input wire DAC_CLK_REF_N,

	output wire [7:0] DAC_DATA_P,
	output wire [7:0] DAC_DATA_N,
	
	output wire DAC_DATACLK_P,
	output wire DAC_DATACLK_N,
	
	output wire DAC_FRAME_P,
	output wire DAC_FRAME_N,
	
	// DDR2
	output wire [12:0] ddr2_a,
	output wire [2:0] ddr2_ba,
	output wire ddr2_ras_n,
	output wire ddr2_cas_n,
	output wire ddr2_we_n,
	output wire ddr2_rzq,
	output wire ddr2_zio,
	output wire ddr2_odt,
	output wire ddr2_cke,
	output wire ddr2_dm,
	output wire ddr2_udm,
	inout wire [15:0] ddr2_dq,
	inout wire ddr2_dqs,
	inout wire ddr2_dqs_n,
	inout wire ddr2_udqs,
	inout wire ddr2_udqs_n,
	output wire ddr2_ck,
	output wire ddr2_ck_n,

	// Serial (USB)
	output wire rs232_tx,
	input wire rs232_rx,
	
	// JTAG
	/*
	output wire tdo_pad_o,
	input wire tms_pad_i,
	input wire tck_pad_i,
	input wire tdi_pad_i,
	*/
	// Flash
	output wire flash_spi_csn,
	output wire flash_spi_sck,
	inout wire [3:0] flash_spi_io,
	
	output wire [7:0] pmod
	);

	wire wb_rst, wb_clk;
`include "wb_intercon.vh"

   localparam ADC_PACKET_SIZE = 256;

	////////////////////////////////////////////////////////////////////////
	//
	// Clock and reset generation module
	//
	////////////////////////////////////////////////////////////////////////

	wire tdo_pad_o;
	wire tms_pad_i;
	wire tck_pad_i;
	wire tdi_pad_i;

	wire dbg_tck;
	wire ddr2_if_clk;
	wire ddr2_if_rst;
	wire phy_rst;
	//wire clk_mux;
	//wire clk_mux_out;
	//wire clk_mux_div;
	//wire rst_mux_div;
	wire clk_125;
	wire rst_125;
	wire clk_125_GTX_CLK;
	wire clk_baud;
	
	clkgen clkgen0 (
		.sys_clk_pad_i (clk_100_pin),
		.rst_n_pad_i (btn[0]),
		
		.wb_clk_o (wb_clk),
		.wb_rst_o (wb_rst),
		
		
		.tck_pad_i (tck_pad_i),
		.dbg_tck_o (dbg_tck),
		.ddr2_if_clk_o (ddr2_if_clk),
		.ddr2_if_rst_o (ddr2_if_rst),
		.clk125_o(clk_125),
		.rst125_o(rst_125),
		.clk125_90_o(clk_125_GTX_CLK),
		.clk_baud_o(clk_baud)
		);

	//  Drive the GTX_CLK output from a DDR register
	ODDR2 ODDR_gmii (
		.Q(GMII_TX_CLK_pin),      // Data output (connect directly to top-level port)
		.C0(clk_125_GTX_CLK),    // 0 degree clock input
		.C1(~clk_125_GTX_CLK),    // 180 degree clock input
		.CE(1'b1),    // Clock enable input
		.D0(1'b0),    // Posedge data input
		.D1(1'b1),    // Negedge data input
		.R(1'b0),      // Synchronous reset input
		.S(1'b0)       // Synchronous preset input
		);
	
	// Register MAC outputs
	wire GMII_TX_EN, GMII_TX_ER;
	wire [7:0] GMII_TXD;
	wire GMII_GTX_CLK_int;
	
	always @(posedge GMII_GTX_CLK_int)
	begin
		GMII_TX_EN_pin <= GMII_TX_EN;
		GMII_TX_ER_pin <= GMII_TX_ER;
		GMII_TXD_pin <= GMII_TXD;
	end
	
	// LEDs for debugging
	// reg [7:0] ledreg;
	//assign leds = {mux_synced, mux_in[6:0]};//{4'b1111,pll_locked, mux_pll_locked, mux_synced, scope_triggered};;

	/*
	config_mux config_mux_inst (
		.clk(dsp_clk),
		.reset(~gemac_ready),

		.rx_ready(config_data_out_en),
		.rx_data(udp_data_out)

		.tx_full : in  STD_LOGIC;
		.tx_wr : out  STD_LOGIC;
		.tx_data : out  STD_LOGIC_VECTOR (31 downto 0);

		.address : out STD_LOGIC_VECTOR (15 downto 0);
		.wr : out STD_LOGIC;
		.rd : out STD_LOGIC;
		.dout : out STD_LOGIC_VECTOR (31 downto 0);
		.din : in STD_LOGIC_VECTOR (31 downto 0));
	*/
	localparam dw = 32; // WB data bus width
	localparam aw = 8; // WB address bus width

	wire rd2_dst_rdy, wr2_dst_rdy;
	wire wr2_src_rdy, rd2_src_rdy;
	wire [3:0]    wr2_flags;
	wire [3:0]    rd2_flags;
	wire [31:0]   rd2_data;
	wire [31:0]   wr2_data;
	wire [dw-1:0] wb_dat_o;
	wire [dw-1:0] wb_dat_i;
	wire [aw-1:0] wb_adr;
	wire wb_ack;
	wire wb_stb, wb_cyc, wb_we;
	wire [79:0]   debug_mac;
	
	simple_gemac_wrapper #(
		.RXFIFOSIZE(9), .TXFIFOSIZE(6)
		) simple_gemac_wrapper_inst (
		
		.clk125(clk_125),
		.reset(rst_125),

		// PHY pins
		.GMII_GTX_CLK(GMII_GTX_CLK_int), .GMII_TX_EN(GMII_TX_EN),
		.GMII_TX_ER(GMII_TX_ER), .GMII_TXD(GMII_TXD),
		.GMII_RX_CLK(GMII_RX_CLK_pin), .GMII_RX_DV(GMII_RX_DV_pin),
		.GMII_RX_ER(GMII_RX_ER_pin), .GMII_RXD(GMII_RXD_pin),
		.mdio(MDIO_pin), .mdc(MDC_pin),
		
		// I/O buses
		.sys_clk(clk_125),
		.rx_f36_data({rd2_flags,rd2_data}), .rx_f36_src_rdy(rd2_src_rdy), .rx_f36_dst_rdy(rd2_dst_rdy),
		.tx_f36_data({wr2_flags,wr2_data}), .tx_f36_src_rdy(wr2_src_rdy), .tx_f36_dst_rdy(wr2_dst_rdy),
		
		// Wishbone signals
		.wb_clk(wb_clk), .wb_rst(wb_rst), .wb_stb(wb_stb), .wb_cyc(wb_cyc), .wb_ack(wb_ack),
		.wb_we(wb_we), .wb_adr(wb_adr), .wb_dat_i(wb_dat_o), .wb_dat_o(wb_dat_i),
	
		.debug(debug_mac));
	
	assign pmod = debug_mac[7:0];
	
	// After the PLL has locked, configure the MAC and PHY using a state machine
	wire gemac_ready;
	wire [3:0] gemac_debug;
	gemac_configure gemac_configure (
		.clk(wb_clk),
		
		// Wishbone signals
		.wb_rst(phy_rst),
		.wb_stb(wb_stb),
		.wb_cyc(wb_cyc),
		.wb_ack(wb_ack),
		.wb_we(wb_we),
		.wb_adr(wb_adr[7:0]),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		
		.phy_reset(PhyResetOut_pin), // Connect to PHY's reset pin
		.reset(wb_rst),
		.debug(gemac_debug),
		.ready(gemac_ready)); // Signal to rest of the system that negotiation is complete



	wire [31:0] pri_fifo_d, adc_fifo_d;
	wire adc_data_re, adc_fifo_ae;

	wire [8:0] sec_packet_size_i;
	wire pri_fifo_req, pri_fifo_rd;
	assign sec_packet_size_i = ADC_PACKET_SIZE;
	
	//wire [31:0] my_ip = 32'hc0a8_2a2a;
	//wire [47:0] my_mac = 48'h0037_ffff_3737;
	//wire [31:0] dst_ip = 32'hc0a8_2a01;
	//wire [47:0] dst_mac = 48'h0090_F5DE_6431;
	wire [15:0] status_req_clk_div_val = 16'd31249; // 100 pkts/sec
	
	wire [15:0] tx_fifo_cnt;
	reg tx_fifo_status_req;
	reg [15:0] status_req_clk_div_cnt;
	
	wire rx_enable;
	wire tx_enable;
	wire gpio_tx_status_enable;
	
	always @(posedge clk_baud or posedge wb_rst) begin
		if (wb_rst) begin
			tx_fifo_status_req <= 0;
			status_req_clk_div_cnt <= 0;
		end else if (gpio_tx_status_enable == 1'b1) begin
			if (status_req_clk_div_cnt == status_req_clk_div_val) begin
				tx_fifo_status_req <= ~tx_fifo_status_req;
				status_req_clk_div_cnt <= 0;
			end else
				status_req_clk_div_cnt <= status_req_clk_div_cnt + 1;
		end else begin
			tx_fifo_status_req <= 0;
			status_req_clk_div_cnt <= 0;
		end
	end
	
	wire eth_tx_irq_flag;
	wire [31:0] eth_tx_fifo_d;
	wire eth_tx_fifo_rd;
	wire eth_tx_fifo_empty;
	wire eth_tx_fifo_full;
	wire gpio_tx_buf_rdy;

	// Send out Ethernet packets
	packet_sender packet_sender (
		.clk(clk_125),
		.reset(~gemac_ready),
		.wr_flags_o(wr2_flags),
		.wr_data_o(wr2_data),
		.wr_dst_rdy_i(wr2_dst_rdy),
		.wr_src_rdy_o(wr2_src_rdy),
		.tx_fifo_status(tx_fifo_status_req),
		.tx_fifo_cnt(tx_fifo_cnt),
		// primary interface: DMA
		.wb_clk_i(wb_clk),
		.wb_rst_i(wb_rst),
		.wb_adr_o(wb_m2s_eth_tx_dma_adr),
		.wb_stb_o(wb_m2s_eth_tx_dma_stb),
		.wb_cyc_o(wb_m2s_eth_tx_dma_cyc),
		.wb_cti_o(wb_m2s_eth_tx_dma_cti),
		.wb_bte_o(wb_m2s_eth_tx_dma_bte),
		.wb_we_o(wb_m2s_eth_tx_dma_we),
		.wb_sel_o(wb_m2s_eth_tx_dma_sel),
		.wb_dat_o(wb_m2s_eth_tx_dma_dat),
		.wb_dat_i(wb_s2m_eth_tx_dma_dat),
		.wb_ack_i(wb_s2m_eth_tx_dma_ack),
		
		.wb_addr_offset(reg_eth_tx_addr_offset),
		.wb_addr_ready(gpio_tx_buf_rdy),
		.wb_buf_size(reg_eth_tx_buf_size),
		
		// secondary interface: ADC Data
		.adc_fifo_d(adc_fifo_d),
		.adc_packet_size_i(sec_packet_size_i),
		.adc_fifo_req(~adc_fifo_ae),
		.adc_fifo_rd(adc_data_re),
		.my_mac(reg_my_mac),
		.my_ip(reg_my_ip),
		.dst_mac(reg_dst_mac),
		.dst_ip(reg_dst_ip),
		.eth_tx_irq_flag(eth_tx_irq_flag));
	
	wire [31:0] adc_data;
	wire clk_adc;
	wire adc_data_we;
	wire adc_fifo_full;
	wire adc_fifo_overflow;
	wire adc_fifo_empty;
	
	adc_sample_fifo adc_sample_fifo_inst (
		.rst(~gemac_ready || ~rx_enable), // input rst
		.wr_clk(clk_adc), // input wr_clk
		.rd_clk(clk_125), // input rd_clk
		.din(adc_data), // input [31 : 0] din
		.wr_en(adc_data_we), // input wr_en
		.rd_en(adc_data_re), // input rd_en
		.prog_empty_thresh(ADC_PACKET_SIZE), // input [9 : 0] prog_empty_thresh
		.dout(adc_fifo_d), // output [31 : 0] dout
		.full(adc_fifo_full), // output full
		.overflow(adc_fifo_overflow), // output overflow
		.empty(adc_fifo_empty), // output empty
		.prog_empty(adc_fifo_ae) // output prog_empty
	);
	
	adc_rx adc_rx (
		.clk(clk_125),
		.reset(~gemac_ready || ~rx_enable),
		
		.adc_cha_p(adc_cha_p),
		.adc_cha_n(adc_cha_n),

		.adc_chb_p(adc_chb_p),
		.adc_chb_n(adc_chb_n),
		
		.bit_clk_p(adc_bit_clk_p),
		.bit_clk_n(adc_bit_clk_n),
		
		.frame_sync_p(adc_frame_sync_p),
		.frame_sync_n(adc_frame_sync_n),
		
		.clk_adc(clk_adc),
		.data_we(adc_data_we),
		.data(adc_data),
		.debug());
	
	//assign pmod = {adc_data_we, adc_data_re, adc_fifo_full, adc_fifo_overflow, adc_fifo_empty, adc_fifo_ae, gemac_ready, udp_data_out_en};
	
	// Receive Ethernet packets
	wire [31:0] udp_data_out;
	wire udp_data_out_en;
	
	wire data_out_dac;
	wire data_out_cpu;
	
	wire rx_forward_rd;
	wire [31:0] rx_forward_data;
	wire rx_forward_last;
	wire rx_forward_empty;
	wire rx_forward_enable;
	wire gpio_rx_addr_ready;
	wire gpio_rx_packet_loss;
	wire eth_rx_irq_flag;
	
	packet_receiver packet_receiver (
		.clk(clk_125),
		.reset(~gemac_ready || ~tx_enable),
		
		.rd_flags_i(rd2_flags),
		.rd_data_i(rd2_data),
		
		.rd_src_rdy_i(rd2_src_rdy),
		.rd_dst_rdy_o(rd2_dst_rdy),
		.data_out_dac(data_out_dac),
		.data_out_cpu(data_out_cpu),
		.data_out(udp_data_out),
		
		.packet_loss(gpio_rx_packet_loss),
		.my_mac(reg_my_mac),
		.my_ip(reg_my_ip),
		.wb_clk_i(wb_clk),
		.wb_rst_i(wb_rst),
		.wb_adr_o(wb_m2s_eth_rx_dma_adr),
		.wb_stb_o(wb_m2s_eth_rx_dma_stb),
		.wb_cyc_o(wb_m2s_eth_rx_dma_cyc),
		.wb_cti_o(wb_m2s_eth_rx_dma_cti),
		.wb_bte_o(wb_m2s_eth_rx_dma_bte),
		.wb_we_o (wb_m2s_eth_rx_dma_we),
		.wb_sel_o(wb_m2s_eth_rx_dma_sel),
		.wb_dat_o(wb_m2s_eth_rx_dma_dat),
		.wb_dat_i(wb_s2m_eth_rx_dma_dat),
		.wb_ack_i(wb_s2m_eth_rx_dma_ack),
		                           
		.wb_addr_offset(reg_eth_rx_addr_offset),
		.wb_addr_ready(gpio_rx_addr_ready),
		.eth_rx_irq_flag(eth_rx_irq_flag),
		.debug()
	);
	
	dac_tx dac_tx_inst (
		.clk(clk_125),             // input  
		.reset_ext(~gemac_ready || ~tx_enable),       // input  
		.data_p(DAC_DATA_P),          // output [7:0] 
		.data_n(DAC_DATA_N),          // output [7:0] 
		.dataclk_p(DAC_DATACLK_P),       // output 
		.dataclk_n(DAC_DATACLK_N),       // output 
		.frame_p(DAC_FRAME_P),         // output 
		.frame_n(DAC_FRAME_N),         // output 
		.clk_dac_ref_p(DAC_CLK_REF_P),     // input  
		.clk_dac_ref_n(DAC_CLK_REF_N),     // input
		.data_we(data_out_dac),         // input  
		.data_in(udp_data_out),         // input  [31:0]  
		.fifo_data_cnt(tx_fifo_cnt),   // output [15:0] 
		.fifo_full(),       // output 
		.fifo_empty()       // output 
	);
	
	
	wire [31:0] or1k_irq;
	wire [31:0] or1k_dbg_dat_i;
	wire [31:0] or1k_dbg_adr_i;
	wire or1k_dbg_we_i;
	wire or1k_dbg_stb_i;
	wire or1k_dbg_ack_o;
	wire [31:0] or1k_dbg_dat_o;
	wire or1k_dbg_stall_i;
	wire or1k_dbg_ewt_i;
	wire [3:0] or1k_dbg_lss_o;
	wire [1:0] or1k_dbg_is_o;
	wire [10:0] or1k_dbg_wp_o;
	wire or1k_dbg_bp_o;
	wire or1k_dbg_rst;
	wire sig_tick;
	wire or1k_rst;
	wire flash_done;
	assign or1k_rst = wb_rst | or1k_dbg_rst | ~flash_done;
	
	mor1kx #(
		.FEATURE_DEBUGUNIT("ENABLED"),
		.FEATURE_CMOV("ENABLED"),
		.FEATURE_INSTRUCTIONCACHE("ENABLED"),
		.OPTION_ICACHE_BLOCK_WIDTH(5),
		.OPTION_ICACHE_SET_WIDTH(8),
		.OPTION_ICACHE_WAYS(4),
		.OPTION_ICACHE_LIMIT_WIDTH(32),
		.FEATURE_IMMU("DISABLED"),
		.OPTION_IMMU_SET_WIDTH(7),
		.FEATURE_DATACACHE("ENABLED"),
		.OPTION_DCACHE_BLOCK_WIDTH(5),
		.OPTION_DCACHE_SET_WIDTH(8),
		.OPTION_DCACHE_WAYS(4),
		.OPTION_DCACHE_LIMIT_WIDTH(31),
		.FEATURE_DMMU("DISABLED"),
		.OPTION_DMMU_SET_WIDTH(7),
		.OPTION_PIC_TRIGGER("LATCHED_LEVEL"),
		.IBUS_WB_TYPE("B3_REGISTERED_FEEDBACK"),
		.DBUS_WB_TYPE("B3_REGISTERED_FEEDBACK"),
		.OPTION_CPU0("CAPPUCCINO"),
		.OPTION_RESET_PC(32'h00000100)
	) mor1kx0 (
		.iwbm_adr_o(wb_m2s_or1k_i_adr),
		.iwbm_stb_o(wb_m2s_or1k_i_stb),
		.iwbm_cyc_o(wb_m2s_or1k_i_cyc),
		.iwbm_sel_o(wb_m2s_or1k_i_sel),
		.iwbm_we_o (wb_m2s_or1k_i_we),
		.iwbm_cti_o(wb_m2s_or1k_i_cti),
		.iwbm_bte_o(wb_m2s_or1k_i_bte),
		.iwbm_dat_o(wb_m2s_or1k_i_dat),
		.dwbm_adr_o(wb_m2s_or1k_d_adr),
		.dwbm_stb_o(wb_m2s_or1k_d_stb),
		.dwbm_cyc_o(wb_m2s_or1k_d_cyc),
		.dwbm_sel_o(wb_m2s_or1k_d_sel),
		.dwbm_we_o (wb_m2s_or1k_d_we ),
		.dwbm_cti_o(wb_m2s_or1k_d_cti),
		.dwbm_bte_o(wb_m2s_or1k_d_bte),
		.dwbm_dat_o(wb_m2s_or1k_d_dat),
		.clk(wb_clk),
		.rst(or1k_rst),
		.iwbm_err_i(wb_s2m_or1k_i_err),
		.iwbm_ack_i(wb_s2m_or1k_i_ack),
		.iwbm_dat_i(wb_s2m_or1k_i_dat),
		.iwbm_rty_i(wb_s2m_or1k_i_rty),
		.dwbm_err_i(wb_s2m_or1k_d_err),
		.dwbm_ack_i(wb_s2m_or1k_d_ack),
		.dwbm_dat_i(wb_s2m_or1k_d_dat),
		.dwbm_rty_i(wb_s2m_or1k_d_rty),
		.irq_i(or1k_irq),
		.du_addr_i(or1k_dbg_adr_i[15:0]),
		.du_stb_i(or1k_dbg_stb_i),
		.du_dat_i(or1k_dbg_dat_i),
		.du_we_i(or1k_dbg_we_i),
		.du_dat_o(or1k_dbg_dat_o),
		.du_ack_o(or1k_dbg_ack_o),
		.du_stall_i(or1k_dbg_stall_i),
		.du_stall_o(or1k_dbg_bp_o),
		.snoop_en_i(1'b0),
		.snoop_adr_i(0)
	);
	
	//wire flash_spi_sck_int;
	wb_flash_loader #(
			.DUMMY_CYCLES(8),
			.READ_OFFSET(24'h800000),
			.WRITE_OFFSET(32'h00000000),
			.SIZE(19),
			.SIMULATION(SIMULATION))
		flash0 (
			.CLK(wb_clk),
			.RESET(wb_rst),
			.SPI_CSN(flash_spi_csn),
			.SPI_IO(flash_spi_io),
			.SPI_CLK(flash_spi_sck),
			.DONE(flash_done),
			.WB_ADR_O(wb_m2s_flash0_adr),
			.WB_DAT_O(wb_m2s_flash0_dat),
			.WB_DAT_I(wb_s2m_flash0_dat),
			.WB_WE_O (wb_m2s_flash0_we),
			.WB_SEL_O(wb_m2s_flash0_sel),
			.WB_STB_O(wb_m2s_flash0_stb),
			.WB_ACK_I(wb_s2m_flash0_ack),
			.WB_CYC_O(wb_m2s_flash0_cyc),
			.WB_CTI_O(wb_m2s_flash0_cti),
			.WB_BTE_O(wb_m2s_flash0_bte),
			.WB_RTY_I(wb_s2m_flash0_rty),
			.WB_ERR_I(wb_s2m_flash0_err));

	wire uart0_irq;
	
	wb_uart #(.clk_div_val(27))
	uart0(
		.wb_clk_i(wb_clk),
		.wb_rst_i(wb_rst),
		
		.wb_dat_i(wb_m2s_uart0_dat[7:0]),
		.wb_dat_o(wb_s2m_uart0_dat[7:0]),
		
		.wb_adr_i(wb_m2s_uart0_adr[0]),
		
		.wb_cyc_i(wb_m2s_uart0_cyc),
		.wb_stb_i(wb_m2s_uart0_stb),
		.wb_we_i(wb_m2s_uart0_we),
		.wb_cti_i(wb_m2s_uart0_cti),
		.wb_bte_i(wb_m2s_uart0_bte),
		
		.wb_ack_o(wb_s2m_uart0_ack),
		.wb_rty_o(wb_s2m_uart0_rty),
		.wb_err_o(wb_s2m_uart0_err),
		
		.uart_out(rs232_tx),
		.uart_in(rs232_rx),
		
		.uart_int(uart0_irq));
	
	
	////////////////////////////////////////////////////////////////////////
	//
	// GENERIC JTAG TAP
	//
	////////////////////////////////////////////////////////////////////////

	wire dbg_if_select;
	wire dbg_if_tdo;
	wire jtag_tap_tdo;
	wire jtag_tap_shift_dr;
	wire jtag_tap_pause_dr;
	wire jtag_tap_update_dr;
	wire jtag_tap_capture_dr;
	wire async_reset;
	
	tap_top jtag_tap0 (
		.tdo_pad_o (tdo_pad_o),
		.tms_pad_i (tms_pad_i),
		.tck_pad_i (dbg_tck),
		.trst_pad_i (async_reset),
		.tdi_pad_i (tdi_pad_i),
		.tdo_padoe_o (),
		.tdo_o (jtag_tap_tdo),
		.shift_dr_o (jtag_tap_shift_dr),
		.pause_dr_o (jtag_tap_pause_dr),
		.update_dr_o (jtag_tap_update_dr),
		.capture_dr_o (jtag_tap_capture_dr),
		.extest_select_o (),
		.sample_preload_select_o (),
		.mbist_select_o (),
		.debug_select_o (dbg_if_select),
		.bs_chain_tdi_i (1'b0),
		.mbist_tdi_i (1'b0),
		.debug_tdi_i (dbg_if_tdo)
	);

	
	////////////////////////////////////////////////////////////////////////
	//
	// Debug Interface
	//
	////////////////////////////////////////////////////////////////////////
	adbg_top dbg_if0 (
		// OR1K interface
		.cpu0_clk_i (wb_clk),
		.cpu0_rst_o (or1k_dbg_rst),
		.cpu0_addr_o (or1k_dbg_adr_i),
		.cpu0_data_o (or1k_dbg_dat_i),
		.cpu0_stb_o (or1k_dbg_stb_i),
		.cpu0_we_o (or1k_dbg_we_i),
		.cpu0_data_i (or1k_dbg_dat_o),
		.cpu0_ack_i (or1k_dbg_ack_o),
		.cpu0_stall_o (or1k_dbg_stall_i),
		.cpu0_bp_i (or1k_dbg_bp_o),
		// TAP interface
		.tck_i (dbg_tck),
		.tdi_i (jtag_tap_tdo),
		.tdo_o (dbg_if_tdo),
		.rst_i (wb_rst),
		.capture_dr_i (jtag_tap_capture_dr),
		.shift_dr_i (jtag_tap_shift_dr),
		.pause_dr_i (jtag_tap_pause_dr),
		.update_dr_i (jtag_tap_update_dr),
		.debug_select_i (dbg_if_select),
		// Wishbone debug master
		.wb_rst_i (wb_rst),
		.wb_clk_i (wb_clk),
		.wb_dat_i (wb_s2m_dbg_dat),
		.wb_ack_i (wb_s2m_dbg_ack),
		.wb_err_i (wb_s2m_dbg_err),
		.wb_adr_o (wb_m2s_dbg_adr),
		.wb_dat_o (wb_m2s_dbg_dat),
		.wb_cyc_o (wb_m2s_dbg_cyc),
		.wb_stb_o (wb_m2s_dbg_stb),
		.wb_sel_o (wb_m2s_dbg_sel),
		.wb_we_o (wb_m2s_dbg_we),
		.wb_cti_o (wb_m2s_dbg_cti),
		.wb_bte_o (wb_m2s_dbg_bte)
	);
	
	
	////////////////////////////////////////////////////////////////////////
	//
	// DDR2 SDRAM Memory Controller
	//
	////////////////////////////////////////////////////////////////////////
	xilinx_ddr2_if # (
	.SIMULATION(SIMULATION)
	)
	xilinx_ddr2_0 (
	// R/W
	.wb0_adr_i (wb_m2s_ddr2_debug_adr),
	.wb0_bte_i (wb_m2s_ddr2_debug_bte),
	.wb0_cti_i (wb_m2s_ddr2_debug_cti),
	.wb0_cyc_i (wb_m2s_ddr2_debug_cyc),
	.wb0_dat_i (wb_m2s_ddr2_debug_dat),
	.wb0_sel_i (wb_m2s_ddr2_debug_sel),
	.wb0_stb_i (wb_m2s_ddr2_debug_stb),
	.wb0_we_i  (wb_m2s_ddr2_debug_we),
	.wb0_ack_o (wb_s2m_ddr2_debug_ack),
	.wb0_dat_o (wb_s2m_ddr2_debug_dat),
	// R/W
	.wb1_adr_i (wb_m2s_ddr2_dbus_adr),
	.wb1_bte_i (wb_m2s_ddr2_dbus_bte),
	.wb1_cti_i (wb_m2s_ddr2_dbus_cti),
	.wb1_cyc_i (wb_m2s_ddr2_dbus_cyc),
	.wb1_dat_i (wb_m2s_ddr2_dbus_dat),
	.wb1_sel_i (wb_m2s_ddr2_dbus_sel),
	.wb1_stb_i (wb_m2s_ddr2_dbus_stb),
	.wb1_we_i  (wb_m2s_ddr2_dbus_we),
	.wb1_ack_o (wb_s2m_ddr2_dbus_ack),
	.wb1_dat_o (wb_s2m_ddr2_dbus_dat),
	// RO
	.wb2_adr_i (wb_m2s_ddr2_ibus_adr),
	.wb2_bte_i (wb_m2s_ddr2_ibus_bte),
	.wb2_cti_i (wb_m2s_ddr2_ibus_cti),
	.wb2_cyc_i (wb_m2s_ddr2_ibus_cyc),
	.wb2_dat_i (wb_m2s_ddr2_ibus_dat),
	.wb2_sel_i (wb_m2s_ddr2_ibus_sel),
	.wb2_stb_i (wb_m2s_ddr2_ibus_stb),
	.wb2_we_i  (wb_m2s_ddr2_ibus_we),
	.wb2_ack_o (wb_s2m_ddr2_ibus_ack),
	.wb2_dat_o (wb_s2m_ddr2_ibus_dat),
	// WO
	.wb3_adr_i (wb_m2s_ddr2_loader_adr),
	.wb3_bte_i (wb_m2s_ddr2_loader_bte),
	.wb3_cti_i (wb_m2s_ddr2_loader_cti),
	.wb3_cyc_i (wb_m2s_ddr2_loader_cyc),
	.wb3_dat_i (wb_m2s_ddr2_loader_dat),
	.wb3_sel_i (wb_m2s_ddr2_loader_sel),
	.wb3_stb_i (wb_m2s_ddr2_loader_stb),
	.wb3_we_i  (wb_m2s_ddr2_loader_we),
	.wb3_ack_o (wb_s2m_ddr2_loader_ack),
	.wb3_dat_o (wb_s2m_ddr2_loader_dat),
	// RO
	.wb4_adr_i (wb_m2s_ddr2_eth_tx_adr),
	.wb4_bte_i (wb_m2s_ddr2_eth_tx_bte),
	.wb4_cti_i (wb_m2s_ddr2_eth_tx_cti),
	.wb4_cyc_i (wb_m2s_ddr2_eth_tx_cyc),
	.wb4_dat_i (wb_m2s_ddr2_eth_tx_dat),
	.wb4_sel_i (wb_m2s_ddr2_eth_tx_sel),
	.wb4_stb_i (wb_m2s_ddr2_eth_tx_stb),
	.wb4_we_i  (wb_m2s_ddr2_eth_tx_we),
	.wb4_ack_o (wb_s2m_ddr2_eth_tx_ack),
	.wb4_dat_o (wb_s2m_ddr2_eth_tx_dat),
	// WO
	.wb5_adr_i (wb_m2s_ddr2_eth_rx_adr),
	.wb5_bte_i (wb_m2s_ddr2_eth_rx_bte),
	.wb5_cti_i (wb_m2s_ddr2_eth_rx_cti),
	.wb5_cyc_i (wb_m2s_ddr2_eth_rx_cyc),
	.wb5_dat_i (wb_m2s_ddr2_eth_rx_dat),
	.wb5_sel_i (wb_m2s_ddr2_eth_rx_sel),
	.wb5_stb_i (wb_m2s_ddr2_eth_rx_stb),
	.wb5_we_i  (wb_m2s_ddr2_eth_rx_we),
	.wb5_ack_o (wb_s2m_ddr2_eth_rx_ack),
	.wb5_dat_o (wb_s2m_ddr2_eth_rx_dat),
	
	.wb_clk (wb_clk),
	.wb_rst (wb_rst),
	.ddr2_a (ddr2_a[12:0]),
	.ddr2_ba (ddr2_ba),
	.ddr2_ras_n (ddr2_ras_n),
	.ddr2_cas_n (ddr2_cas_n),
	.ddr2_we_n (ddr2_we_n),
	.ddr2_rzq (ddr2_rzq),
	.ddr2_zio (ddr2_zio),
	.ddr2_odt (ddr2_odt),
	.ddr2_cke (ddr2_cke),
	.ddr2_dm (ddr2_dm),
	.ddr2_udm (ddr2_udm),
	.ddr2_ck (ddr2_ck),
	.ddr2_ck_n (ddr2_ck_n),
	.ddr2_dq (ddr2_dq),
	.ddr2_dqs (ddr2_dqs),
	.ddr2_dqs_n (ddr2_dqs_n),
	.ddr2_udqs (ddr2_udqs),
	.ddr2_udqs_n (ddr2_udqs_n),
	.ddr2_if_clk (ddr2_if_clk),
	.ddr2_if_rst (ddr2_if_rst),
	.ddr2_trace_data0_o(),
	.ddr2_trace_data1_o(),
	.ddr2_trace_data2_o(),
	.ddr2_trace_data3_o(),
	.ddr2_trace_data4_o(),
	.ddr2_trace_data5_o()
	);
	
	assign wb_s2m_ddr2_ibus_err = 0;
	assign wb_s2m_ddr2_ibus_rty = 0;
	
	assign wb_s2m_ddr2_dbus_err = 0;
	assign wb_s2m_ddr2_dbus_rty = 0;
	
	////////////////////////////////////////////////////////////////////////
	//
	// SPI0 controller
	//
	////////////////////////////////////////////////////////////////////////

	//
	// Wires
	//
	wire 			spi0_irq;
	wire [4:0]	spi0_ss;
	wire 			spi0_mosi;
	wire 			spi0_miso;
	wire 			spi0_sck;
	//
	// Assigns
	//
	assign  wb_s2m_spi0_err = 0;
	assign  wb_s2m_spi0_rty = 0;
//	assign  spi0_hold_n_o = 1;
//	assign  spi0_w_n_o = 1;

	simple_spi #(.SS_WIDTH(5))
	spi0(
		// Wishbone slave interface
		.clk_i	(wb_clk),
		.rst_i	(wb_rst),
		.adr_i	(wb_m2s_spi0_adr[2:0]),
		.dat_i	(wb_m2s_spi0_dat),
		.we_i	(wb_m2s_spi0_we),
		.stb_i	(wb_m2s_spi0_stb),
		.cyc_i	(wb_m2s_spi0_cyc),
		.dat_o	(wb_s2m_spi0_dat),
		.ack_o	(wb_s2m_spi0_ack),

		// Outputs
		.inta_o		(spi0_irq),
		.sck_o		(spi0_sck),
		.ss_o		(spi0_ss),
		.mosi_o		(spi0_mosi),

		// Inputs
		.miso_i		(spi0_miso)
	);
	
	wire [32*16-1:0] reg_data_out;
	wire [32*16-1:0] reg_data_in;
	wire [   16-1:0] reg_data_we;
	
	assign reg_data_we = 0;
	assign reg_data_in = 0;
	
	wire [31:0] reg_my_ip              = reg_data_out[31:0];
	wire [47:0] reg_my_mac             = reg_data_out[79:32];
	wire [31:0] reg_dst_ip             = reg_data_out[127:96];
	wire [47:0] reg_dst_mac            = reg_data_out[175:128];
	wire [31:0] reg_eth_rx_addr_offset = reg_data_out[223:192];
	wire [31:0] reg_eth_tx_addr_offset = reg_data_out[255:224];
	wire [9:0]  reg_eth_tx_buf_size    = reg_data_out[265:256];
	
	wb_config # (
		.DATA_WIDTH(32),
		.ADDR_WIDTH(4))
	wb_config0 (
		.CLK         (wb_clk),
	    .RST         (wb_rst),
	    .WB_ADR_I    (wb_m2s_sdr_reg_adr),
	    .WB_DAT_I    (wb_m2s_sdr_reg_dat),
	    .WB_SEL_I    (wb_m2s_sdr_reg_sel),
	    .WB_WE_I     (wb_m2s_sdr_reg_we),
	    .WB_CYC_I    (wb_m2s_sdr_reg_cyc),
	    .WB_STB_I    (wb_m2s_sdr_reg_stb),
	    .WB_CTI_I    (wb_m2s_sdr_reg_cti),
	    .WB_BTE_I    (wb_m2s_sdr_reg_bte),
	    .WB_DAT_O    (wb_s2m_sdr_reg_dat),
	    .WB_ACK_O    (wb_s2m_sdr_reg_ack),
	    .WB_ERR_O    (wb_s2m_sdr_reg_err),
	    .WB_RTY_O    (wb_s2m_sdr_reg_rty),
	    .DATA_OUTPUT (reg_data_out),
	    .DATA_INPUT  (reg_data_in),
	    .DATA_WE     (reg_data_we));
	
	
	wire [31:0] gpio_in;
	wire [31:0] gpio_out;
	//wire [31:0] gpio_dir;
	reg  [31:0] gpio_in_sync, gpio_in_buf;
	
	always @(posedge wb_clk or posedge wb_rst)
		if (wb_rst) begin
			gpio_in_sync <= 0;
			gpio_in_buf <= 0;
		end else begin
			gpio_in_buf <= gpio_in;
			gpio_in_sync <= gpio_in_buf;
		end
		
	gpio gpio0 (
		.wb_clk   (wb_clk),
		.wb_rst   (wb_rst),
		.wb_adr_i (wb_m2s_gpio0_adr[2:0]),
		.wb_dat_i (wb_m2s_gpio0_dat),
		.wb_we_i  (wb_m2s_gpio0_we),
		.wb_cyc_i (wb_m2s_gpio0_cyc),
		.wb_stb_i (wb_m2s_gpio0_stb),
		.wb_cti_i (wb_m2s_gpio0_cti),
		.wb_bte_i (wb_m2s_gpio0_bte),
		.wb_sel_i (wb_m2s_gpio0_sel),
		.wb_dat_o (wb_s2m_gpio0_dat),
		.wb_ack_o (wb_s2m_gpio0_ack),
		.wb_err_o (wb_s2m_gpio0_err),
		.wb_rty_o (wb_s2m_gpio0_rty),
		.gpio_i   ({5'd0, gpio_tx_status_enable, gpio_tx_buf_rdy, gpio_rx_packet_loss, gpio_rx_addr_ready, 9'd0, gpio_in_sync[13:0]}),
		.gpio_o   (gpio_out),
		.gpio_dir_o ());
		
	wire scope_armed, scope_triggered;
	
	assign leds[6:0] = gpio_out[22:16];
	
	assign gpio_in[7:0] = sw;
	
	assign rx_enable = gpio_in_sync[0];
	assign tx_enable = gpio_in_sync[1];
	
	assign gpio_rx_addr_ready = gpio_out[23];
	assign gpio_tx_buf_rdy = gpio_out[25];
	assign gpio_tx_status_enable = gpio_out[26];
	
vhdci_mux vhdci_mux_inst (
	.clk_in(wb_clk),
	.rst_in(wb_rst),
	
	.mux_data_in({spi0_sck, spi0_mosi, spi0_ss[4], spi0_ss[3], spi0_ss[2], spi0_ss[1], spi0_ss[0]}),
	.mux_data_out({spi0_miso, gpio_in[13:8]}),
	
	.mux_synced(leds[7]),
	
	.VHDCI_MUX_IN_P(VHDCI_MUX_IN_P),
	.VHDCI_MUX_IN_N(VHDCI_MUX_IN_N),
	.VHDCI_MUX_OUT_P(VHDCI_MUX_OUT_P),
	.VHDCI_MUX_OUT_N(VHDCI_MUX_OUT_N),
	.VHDCI_MUX_CLK_P(VHDCI_MUX_CLK_P),
	.VHDCI_MUX_CLK_N(VHDCI_MUX_CLK_N),
	.debug());

	////////////////////////////////////////////////////////////////////////
	//
	// Interrupt assignment
	//
	////////////////////////////////////////////////////////////////////////
	assign or1k_irq[0] = 0; // Non-maskable inside OR1K
	assign or1k_irq[1] = 0; // Non-maskable inside OR1K
	assign or1k_irq[2] = uart0_irq;
	assign or1k_irq[3] = 0;
	assign or1k_irq[4] = 0;
	assign or1k_irq[5] = 0;
	assign or1k_irq[6] = spi0_irq;
	assign or1k_irq[7] = 0;
	assign or1k_irq[8] = eth_rx_irq_flag;
	assign or1k_irq[9] = eth_tx_irq_flag;
	assign or1k_irq[10] = 0;
	assign or1k_irq[11] = 0;
	assign or1k_irq[12] = 0;
	assign or1k_irq[13] = 0;
	assign or1k_irq[14] = 0;
	assign or1k_irq[15] = 0;
	assign or1k_irq[16] = 0;
	assign or1k_irq[17] = 0;
	assign or1k_irq[18] = 0;
	assign or1k_irq[19] = 0;
	assign or1k_irq[20] = 0;
	assign or1k_irq[21] = 0;
	assign or1k_irq[22] = 0;
	assign or1k_irq[23] = 0;
	assign or1k_irq[24] = 0;
	assign or1k_irq[25] = 0;
	assign or1k_irq[26] = 0;
	assign or1k_irq[27] = 0;
	assign or1k_irq[28] = 0;
	assign or1k_irq[29] = 0;
	assign or1k_irq[30] = 0;
	assign or1k_irq[31] = 0;

endmodule
