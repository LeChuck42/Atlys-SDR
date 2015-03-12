/*
 *
 * Clock, reset generation unit for Atlys board
 *
 * Implements clock generation according to design defines
 *
 */

`default_nettype none
 
module clkgen
       (
	// Main clocks in, depending on board
	input  sys_clk_pad_i,
	// Asynchronous, active low reset in
	input  rst_n_pad_i,
	// Input reset - through a buffer, asynchronous
	output async_rst_o,

	// Wishbone clock and reset out
	output wb_clk_o,
	output wb_rst_o,

	// JTAG clock
	input  tck_pad_i,
	output dbg_tck_o,

	// Main memory clocks
	output ddr2_if_clk_o,
	output ddr2_if_rst_o,
	
	
	output clk100_o,
	output clk_500_prebufg,
	
	output VHDCI_MUX_CLK_P,
	output VHDCI_MUX_CLK_N,

	output clk_mux_out);
// First, deal with the asychronous reset
wire	async_rst_n;

assign async_rst_n = rst_n_pad_i;

// Everyone likes active-high reset signals...
assign async_rst_o = ~async_rst_n;

assign dbg_tck_o = tck_pad_i;

//
// Declare synchronous reset wires here
//

// An active-low synchronous reset signal (usually a PLL lock signal)
wire	sync_wb_rst_n;	   

// An active-low synchronous reset from ethernet PLL
wire	sync_eth_rst_n;


wire	sys_clk_pad_ibufg;
/* DCM0 wires */
wire	dcm0_clk0_prebufg, dcm0_clk0;
wire	dcm0_clk90_prebufg, dcm0_clk90;
wire	dcm0_clkfx_prebufg, dcm0_clkfx;
wire	dcm0_clkdv_prebufg, dcm0_clkdv;
wire	dcm0_locked;

wire	pll0_clkfb;
wire	pll0_locked;
wire	pll0_clk1_prebufg, pll0_clk1;
wire    clk_250_prebufg, clk_250;
wire    clk_125_prebufg, clk_125;
wire    clk_125_inv_prebufg, clk_125_inv;
wire    clk_io_prebufg, clk_io;
wire    clk_io_inv_prebufg, clk_io_inv;


IBUFG sys_clk_in_ibufg (
	.I	(sys_clk_pad_i),
	.O	(sys_clk_pad_ibufg)
);


// DCM providing main system/Wishbone clock
DCM_SP #(
	// Generate 266 MHz from CLKFX
	.CLKFX_MULTIPLY	(8),
	.CLKFX_DIVIDE	(3),

	// Generate 50 MHz from CLKDV
	.CLKDV_DIVIDE	(2.0)
) dcm0 (
	// Outputs
	.CLK0		(dcm0_clk0_prebufg),
	.CLK180		(),
	.CLK270		(),
	.CLK2X180	(),
	.CLK2X		(),
	.CLK90		(dcm0_clk90_prebufg),
	.CLKDV		(dcm0_clkdv_prebufg),
	.CLKFX180	(dcm0_clkfx_prebufg),
	.CLKFX		(),
	.LOCKED		(dcm0_locked),
	// Inputs
	.CLKFB		(dcm0_clk0),
	.CLKIN		(sys_clk_pad_ibufg),
	.PSEN		(1'b0),
	.RST		(async_rst_o)
);

// Daisy chain DCM-PLL to reduce jitter
PLL_BASE #(
	.BANDWIDTH             ("OPTIMIZED"),
    .CLKOUT0_DIVIDE        (2),
    .CLKOUT0_PHASE         (0.000),
    .CLKOUT0_DUTY_CYCLE    (0.500),
    .CLKOUT1_DIVIDE        (4),
    .CLKOUT1_PHASE         (90.000),
    .CLKOUT1_DUTY_CYCLE    (0.500),
	.CLKOUT2_DIVIDE        (8),
    .CLKOUT2_PHASE         (0.000),
    .CLKOUT2_DUTY_CYCLE    (0.500),
	.CLKOUT3_DIVIDE        (8),
    .CLKOUT3_PHASE         (180.000),
    .CLKOUT3_DUTY_CYCLE    (0.500),
    .CLKOUT4_DIVIDE        (16),
    .CLKOUT4_PHASE         (0.000),
    .CLKOUT4_DUTY_CYCLE    (0.500),
    .CLKOUT5_DIVIDE        (16),
    .CLKOUT5_PHASE         (180.000),
    .CLKOUT5_DUTY_CYCLE    (0.500),
	.CLK_FEEDBACK          ("CLKFBOUT"),
	.CLKFBOUT_MULT         (10),
    .CLKFBOUT_PHASE        (0.000),
	.COMPENSATION          ("DCM2PLL"),
	.DIVCLK_DIVIDE         (1),
	.REF_JITTER            (0.1),
	.RESET_ON_LOSS_OF_LOCK ("FALSE")
) pll0 (
	.CLKFBOUT	           (pll0_clkfb),
    .CLKOUT0               (clk_500_prebufg),
    .CLKOUT1               (clk_250_prebufg),
	.CLKOUT2               (clk_125_prebufg),
	.CLKOUT3               (clk_125_inv_prebufg),
    .CLKOUT4               (clk_io_prebufg),
    .CLKOUT5               (clk_io_inv_prebufg),
	.LOCKED		           (pll0_locked),
	.CLKFBIN	           (pll0_clkfb),
	.CLKIN		           (dcm0_clk90_prebufg),
	.RST		           (async_rst_o)
);

	BUFG clk_mux_buf
    (.O (clk_io),
     .I (clk_io_prebufg));
	
	BUFG clk_io_buf
    (.O (clk_io_inv),
     .I (clk_io_inv_prebufg)); 
	 
	BUFG clkout_buf
	 (.O (clk_mux_out),
	  .I (clk_250_prebufg));

	BUFG dcm0_clk0_bufg
	(.O	(dcm0_clk0),
	 .I	(dcm0_clk0_prebufg));
	
	wire fpga_mux_clk;
	
	ODDR2 ODDR_FPGA_MUX (
	  .Q(fpga_mux_clk),     // Data output (connect directly to top-level port)
      .C0(clk_io),     // 0 degree clock input
      .C1(~clk_io),    // 180 degree clock input
      .CE(1'b1),     // Clock enable input
      .D0(1'b0),     // Posedge data input
      .D1(1'b1),     // Negedge data input
      .R(1'b0),      // Synchronous reset input
      .S(1'b0)       // Synchronous preset input
      );

	OBUFDS #(
      .IOSTANDARD("LVDS_25") // Specify the output I/O standard
   ) OBUFDS_inst (
      .O(VHDCI_MUX_CLK_P),     // Diff_p output (connect directly to top-level port) (p type differential o/p)
      .OB(VHDCI_MUX_CLK_N),   // Diff_n output (connect directly to top-level port) (n type differential o/p)
      .I(fpga_mux_clk)      // Buffer input (this is the single ended standard)
   );

   
BUFG pll0_clk1_bufg
       (// Outputs
	.O	(dcm0_clkdv),
	// Inputs
	.I	(dcm0_clkdv_prebufg));

assign wb_clk_o = dcm0_clkdv;
assign sync_wb_rst_n = pll0_locked && dcm0_locked;

assign ddr2_if_clk_o = dcm0_clkfx_prebufg; // 266MHz
assign clk100_o = dcm0_clk0; // 100MHz

//
// Reset generation
//
//

// Reset generation for wishbone
reg [15:0] 	   wb_rst_shr;
always @(posedge wb_clk_o or posedge async_rst_o)
	if (async_rst_o)
		wb_rst_shr <= 16'hffff;
	else
		wb_rst_shr <= {wb_rst_shr[14:0], ~(sync_wb_rst_n)};

assign wb_rst_o = wb_rst_shr[15];

assign ddr2_if_rst_o = async_rst_o;

endmodule // clkgen
