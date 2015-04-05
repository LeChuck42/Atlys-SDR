`default_nettype none

module vhdci_mux (
	input wire clk_in,
	input wire rst_in,
	
	input wire [6:0] mux_data_in,
	output wire [6:0] mux_data_out,
	
	output reg mux_synced,
	
	input wire VHDCI_MUX_IN_P,
	input wire VHDCI_MUX_IN_N,
	output wire VHDCI_MUX_OUT_P,
	output wire VHDCI_MUX_OUT_N,
	output wire VHDCI_MUX_CLK_P,
	output wire VHDCI_MUX_CLK_N);
	
	wire clk_mux, clk_mux_out, clk_250_int, clk_mux_div, clk_mux_div_int, mux_pll_locked, clkfbout, clkfbout_buf;
	PLL_BASE
	#(.BANDWIDTH               ("OPTIMIZED"),
		.CLK_FEEDBACK          ("CLKFBOUT"),
		.COMPENSATION          ("DCM2PLL"),
		.DIVCLK_DIVIDE         (1),
		.CLKFBOUT_MULT         (10),
		.CLKFBOUT_PHASE        (0.000),
		.CLKOUT0_DIVIDE        (2),
		.CLKOUT0_PHASE         (0.000),
		.CLKOUT0_DUTY_CYCLE    (0.500),
		.CLKOUT1_DIVIDE        (4),
		.CLKOUT1_PHASE         (90.000),
		.CLKOUT1_DUTY_CYCLE    (0.500),
		.CLKOUT2_DIVIDE        (16),
		.CLKOUT2_PHASE         (0.000),
		.CLKOUT2_DUTY_CYCLE    (0.500),
		.CLKIN_PERIOD          (10.0),
		.REF_JITTER            (0.010))
	pll_base_inst
	// Output clocks
	(
		.CLKFBOUT              (clkfbout),
		.CLKOUT0               (clk_mux),
		.CLKOUT1               (clk_250_int),
		.CLKOUT2               (clk_mux_div_int),
		.CLKOUT3               (),
		.CLKOUT4               (),
		.CLKOUT5               (),
		// Status and control signals
		.LOCKED                (mux_pll_locked),
		.RST                   (1'b0),
		// Input clock control
		.CLKFBIN               (clkfbout_buf),
		.CLKIN                 (clk_in));

	BUFG clkf_buf
	(.O (clk_mux_div),
	 .I (clk_mux_div_int));
	
	BUFG clkout_buf
	 (.O (clk_mux_out),
	  .I (clk_250_int));
	
	BUFG clkfb_buf
	(.O (clkfbout_buf),
	 .I (clkfbout));
	
	wire fpga_mux_clk;
	ODDR2 ODDR_FPGA_MUX (
		.Q(fpga_mux_clk),      // Data output (connect directly to top-level port)
		.C0(clk_mux_out),    // 0 degree clock input
		.C1(~clk_mux_out),    // 180 degree clock input
		.CE(1'b1),    // Clock enable input
		.D0(1'b0),    // Posedge data input
		.D1(1'b1),    // Negedge data input
		.R(1'b0),      // Synchronous reset input
		.S(1'b0)       // Synchronous preset input
		);

	OBUFDS #( .IOSTANDARD("LVDS_25") // Specify the output I/O standard
	) OBUFDS_inst (
		.O(VHDCI_MUX_CLK_P),     // Diff_p output (connect directly to top-level port) (p type differential o/p)
		.OB(VHDCI_MUX_CLK_N),   // Diff_n output (connect directly to top-level port) (n type differential o/p)
		.I(fpga_mux_clk)      // Buffer input (this is the single ended standard)
	);
	

	reg vhdci_mux_bitslip;
	wire [7:0] mux_in, mux_out;
	assign mux_data_out = mux_in[6:0];
	
	reg [7:0] sync_pattern;
	reg sync_mon_expect, sync_mon_valid, sync_mon_out;
	reg bitslip_sync;
	
	assign mux_out = (mux_synced) ? {sync_mon_out, mux_data_in} : sync_pattern;
	
	always @(posedge clk_mux_div or posedge rst_in)
		if (rst_in) begin
			sync_mon_out <= 0;
			mux_synced <= 0;
			vhdci_mux_bitslip <= 0;
			sync_mon_valid <= 0;
			sync_mon_expect <= 0;
			bitslip_sync <= 0;
		end else begin
			sync_mon_out <= !sync_mon_out; // output sync bit to detect loss of link on other side
			vhdci_mux_bitslip <= 0;
			bitslip_sync <= vhdci_mux_bitslip;
			if (mux_synced == 1) begin
				if (sync_mon_valid == 1) begin
					if (sync_mon_expect == mux_in[7]) begin
						sync_mon_expect <= !mux_in[7];
					end else begin
						sync_mon_valid <= 0;
						mux_synced <= 0;
					end
				end else if (mux_in != 8'h81) begin
					sync_mon_expect <= !mux_in[7];
					sync_mon_valid <= 1;
				end
			end else if (mux_in != 8'h01 && mux_in != 8'h81) begin
				if (vhdci_mux_bitslip == 0 && bitslip_sync == 0)
					vhdci_mux_bitslip <= 1;
				sync_pattern <= 8'h01;
				sync_mon_valid <= 0;
			end else begin
				if (mux_in == 8'h81 && sync_pattern == 8'h81)
					mux_synced <= 1;
				sync_pattern <= 8'h81;
				sync_mon_valid <= 0;
			end
		end
	
	
	FPGA_MUX vhdci_mux
	(
		// From the system into the device
		.DATA_IN_FROM_PINS_P     ({VHDCI_MUX_IN_P}),
		.DATA_IN_FROM_PINS_N     ({VHDCI_MUX_IN_N}),
		.DATA_IN_TO_DEVICE       (mux_in),
		// From the drive out to the system
		.DATA_OUT_FROM_DEVICE    (mux_out),
		.DATA_OUT_TO_PINS_P      ({VHDCI_MUX_OUT_P}),
		.DATA_OUT_TO_PINS_N      ({VHDCI_MUX_OUT_N}),
		.CLK_TO_PINS_P           (),
		.CLK_TO_PINS_N           (),
		.BITSLIP                 (vhdci_mux_bitslip),
		.CLK_RESET               (1'b0),
		.CLK_IN                  (clk_mux),
		.CLK_DIV_IN              (clk_mux_div),
		.LOCKED_IN               (mux_pll_locked),
		.LOCKED_OUT              (),
		.IO_RESET                (rst_in));

endmodule