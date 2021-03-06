/*
 *
 * Clock, reset generation unit for Atlys board
 *
 * Implements clock generation according to design defines
 *
 */

`default_nettype none
 
module clkgen (
	// Main clocks in, depending on board
	input wire  sys_clk_pad_i,
	// Asynchronous, active low reset in
	input wire  rst_n_pad_i,

	// Wishbone clock and reset out
	output wire wb_clk_o,
	output wire wb_rst_o,
	
	output wire rst125_o,
	output wire clk125_o,
	output wire clk125_90_o,
	
	output wire clk_baud_o,
	// JTAG clock
	input wire  tck_pad_i,
	output wire dbg_tck_o,

	// Main memory clocks
	output wire ddr2_if_clk_o,
	output wire ddr2_if_rst_o,
	

	output wire clk_mux_out);
// First, deal with the asychronous reset
wire   async_rst;

assign async_rst = ~rst_n_pad_i;

assign dbg_tck_o = tck_pad_i;

//
// Declare synchronous reset wires here
//
wire    plls_locked_n;

wire    sys_clk_pad_ibufg;
/* DCM0 wires */
wire    dcm0_clk0_prebufg, clk_100;
wire    dcm0_clk2x_prebufg;
wire    dcm0_clkdv_prebufg, clk_baud;
wire    dcm0_clkfx_prebufg, dcm0_clkfx;
wire    dcm0_locked;


wire    pll0_locked;
wire    pll0_clkfb;
wire    pll0_clk0_prebuf, wb_clk;
wire    pll0_clk2_prebuf, clk_125;
wire    pll0_clk3_prebuf, clk_125_90;

IBUFG sys_clk_in_ibufg (
	.I  (sys_clk_pad_i),
	.O  (sys_clk_pad_ibufg)
);

// DCM providing pll and ddr clock
DCM_SP #(
	// Generate 266 MHz from CLKFX
	.CLKFX_MULTIPLY (8),
	.CLKFX_DIVIDE   (3),

	.CLKDV_DIVIDE   (16)
) dcm0 (
	// Outputs
	.CLK0       (dcm0_clk0_prebufg),
	.CLK90      (),
	.CLK180     (),
	.CLK270     (),
	.CLK2X180   (),
	.CLK2X      (dcm0_clk2x_prebufg),
	.CLKDV      (dcm0_clkdv_prebufg),
	.CLKFX180   (),
	.CLKFX      (dcm0_clkfx_prebufg),
	.LOCKED     (dcm0_locked),
	// Inputs
	.CLKFB      (clk_100),
	.CLKIN      (sys_clk_pad_ibufg),
	.PSEN       (1'b0),
	.RST        (async_rst)
);

BUFG dcm0_clk0_bufg
	(.O (clk_100),
	 .I (dcm0_clk0_prebufg));

BUFH dcm0_clkdv_bufh
	(.O (clk_baud),
	 .I (dcm0_clkdv_prebufg));


wire pll_reset = ~dcm0_locked;
// Daisy chain DCM-PLL to reduce jitter
PLL_BASE #(
	.BANDWIDTH             ("OPTIMIZED"),
	.CLKOUT0_DIVIDE        (25),
	.CLKOUT0_PHASE         (0.000),
	.CLKOUT0_DUTY_CYCLE    (0.500),
	.CLKOUT1_DIVIDE        (50),
	.CLKOUT1_PHASE         (0.000),
	.CLKOUT1_DUTY_CYCLE    (0.500),
	.CLKOUT2_DIVIDE        (8),
	.CLKOUT2_PHASE         (0.000),
	.CLKOUT2_DUTY_CYCLE    (0.500),
	.CLKOUT3_DIVIDE        (8),
	.CLKOUT3_PHASE         (90.000),
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
	.CLKIN_PERIOD          (10.0),
	.RESET_ON_LOSS_OF_LOCK ("FALSE")
) pll0 (
	.CLKFBOUT              (pll0_clkfb),
	.CLKOUT0               (pll0_clk0_prebuf),
	.CLKOUT1               (),
	.CLKOUT2               (pll0_clk2_prebuf),
	.CLKOUT3               (pll0_clk3_prebuf),
	.CLKOUT4               (),
	.CLKOUT5               (),
	.LOCKED                (pll0_locked),
	.CLKFBIN               (pll0_clkfb),
	.CLKIN                 (dcm0_clk0_prebufg),
	.RST                   (pll_reset)
);

BUFG dcm1_clkdv_bufg
	(.O  (wb_clk),
	 .I  (pll0_clk0_prebuf));

/*
BUFG pll0_clkout1_buf
	(.O (clk_250),
	 .I (pll0_clk_250_prebufg));
*/
BUFG pll0_clkout2_buf
	(.O (clk_125),
	 .I (pll0_clk2_prebuf));

BUFG pll0_clkout3_buf
	(.O (clk_125_90),
	 .I (pll0_clk3_prebuf));
/*
BUFG pll0_clkout4_buf
	(.O (clk_62_5),
	 .I (pll0_clk_62_5_prebufg));

*/
assign plls_locked_n = ~pll0_locked || ~dcm0_locked;
//assign clk500_prebufg_o = pll0_clk_500_prebufg;
assign ddr2_if_clk_o    = dcm0_clkfx_prebufg;

assign wb_clk_o      = wb_clk;
assign clk125_o      = clk_125;
assign clk125_90_o   = clk_125_90;
//assign clk250_o      = clk_250;
//assign clk62_5_o     = clk_62_5;
assign clk_baud_o    = clk_baud;
//
// Reset generation
//
//

reg [3:0] wb_rst_shr;
always @(posedge wb_clk or posedge plls_locked_n)
	if (plls_locked_n)
		wb_rst_shr <= 4'hf;
	else
		wb_rst_shr <= {wb_rst_shr[2:0], 1'b0};
assign wb_rst_o = wb_rst_shr[3];

reg [3:0] rst_125_shr;
always @(posedge clk_125 or posedge plls_locked_n)
	if (plls_locked_n)
		rst_125_shr <= 4'hf;
	else
		rst_125_shr <= {rst_125_shr[2:0], 1'b0};
assign rst125_o = rst_125_shr[3];

/*
reg [3:0] rst_62_5_shr;
always @(posedge clk_62_5 or posedge plls_locked_n)
	if (plls_locked_n)
		rst_62_5_shr <= 4'hf;
	else
		rst_62_5_shr <= {rst_62_5_shr[2:0], 1'b0};
assign rst62_5_o = rst_62_5_shr[3];
*/
assign ddr2_if_rst_o = plls_locked_n;

endmodule // clkgen
