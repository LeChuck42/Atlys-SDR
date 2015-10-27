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
	output wire VHDCI_MUX_CLK_N,
	output wire [7:0] debug);
	
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
	reg [2:0] delay_sync_state;
	
	reg vhdci_mux_bitslip;
	wire [7:0] mux_in;
	reg  [7:0] mux_in_sync;
	reg  [7:0] mux_out;
	assign mux_data_out = mux_in[6:0];
	
	reg [7:0] sync_pattern;
	reg sync_mon_expect, sync_mon_valid, sync_mon_out;
	reg bitslip_sync;
	
	wire reset_sync = rst_in | (!mux_pll_locked);
	always @(posedge clk_mux_div or posedge reset_sync)
		if (reset_sync) begin
			sync_mon_out <= 0;
			mux_synced <= 0;
			vhdci_mux_bitslip <= 0;
			sync_mon_valid <= 0;
			sync_mon_expect <= 0;
			bitslip_sync <= 0;
			sync_pattern <= 8'h00;
			mux_out <= 8'h00;
			mux_in_sync <= 8'h00;
		end else begin
			sync_mon_out <= !sync_mon_out; // output sync bit to detect loss of link on other side
			vhdci_mux_bitslip <= 0;
			bitslip_sync <= vhdci_mux_bitslip;
			mux_out <= (mux_synced) ? {sync_mon_out, mux_data_in} : sync_pattern;
			mux_in_sync <= mux_in;
			if (mux_synced == 1) begin
				if (sync_mon_valid == 1) begin
					if (sync_mon_expect == mux_in_sync[7]) begin
						sync_mon_expect <= !mux_in_sync[7];
					end else begin
						sync_mon_valid <= 0;
						mux_synced <= 0;
					end
				end else if (mux_in_sync != 8'h81) begin
					sync_mon_expect <= !mux_in_sync[7];
					sync_mon_valid <= 1;
				end
			end else begin
				sync_mon_valid <= 0;
				if (delay_sync_state == 3'b101) begin
					if (mux_in_sync != 8'h01 && mux_in_sync != 8'h81) begin
						if (vhdci_mux_bitslip == 0 && bitslip_sync == 0)
							vhdci_mux_bitslip <= 1;
						sync_pattern <= 8'h01;
					end else begin
						if (mux_in_sync == 8'h81 && sync_pattern == 8'h81 && vhdci_mux_bitslip == 0 && bitslip_sync == 0)
							mux_synced <= 1;
						sync_pattern <= 8'h81;
					end
				end
			end
		end
	
	wire delay_busy;
	reg  delay_busy_sync;
	reg  delay_cal;
	reg  delay_ce;
	reg  delay_inc;
	reg [7:0] mux_in_buf;
	reg  io_reset;
	reg [4:0] delay_half_shift;
	always @(posedge clk_mux_div or posedge reset_sync)
		if (reset_sync) begin
			delay_cal <= 0;
			delay_inc <= 1;
			delay_ce <= 0;
			io_reset <= 1;
			delay_sync_state <= 3'b000;
			delay_half_shift <= 15;
			delay_busy_sync <= 1'b0;
		end else begin
			delay_busy_sync <= delay_busy;
			case (delay_sync_state)
				3'b000 : begin	// start calibration
						io_reset <= 0;
						delay_cal <= 1;
						delay_sync_state <= 3'b001;
					end
				3'b001 : begin	// wait for calibration
						if (delay_cal == 0 && delay_busy == 0 && delay_busy_sync == 0) begin
							delay_sync_state <= 3'b011;
							io_reset <= 1;
						end
						delay_cal <= 0;
					end
				3'b011 : begin	// wait for rx data and store reference
						io_reset <= 0;
						if (mux_in_sync != 8'h00) begin
							mux_in_buf <= mux_in_sync;
							delay_sync_state <= 3'b010;
						end
					end
				3'b010 : begin	// increment delay
						delay_ce <= 1;
						delay_sync_state <= 3'b110;
					end
				3'b110 : begin	// wait for delay
						if (delay_ce == 0 && delay_busy == 0 && delay_busy_sync == 0) begin
							if (mux_in_sync != mux_in_buf) begin
								delay_sync_state <= 3'b111;
							end else begin
								delay_sync_state <= 3'b010;
							end
						end
						delay_ce <= 0;
					end
				3'b111 : begin // edge found, shift to mid
						if (delay_ce == 0 && delay_busy == 0 && delay_busy_sync == 0) begin
							if (delay_half_shift == 0) begin
								delay_sync_state <= 3'b101;
							end else begin
								delay_ce <= 1;
								delay_half_shift <= delay_half_shift - 1;
							end
						end else begin
							delay_ce <= 0;
						end
					end
				3'b101 : begin // ready
					delay_sync_state <= 3'b101;
					end
			endcase
		end
		
	assign debug[7] = delay_cal;
	assign debug[6] = delay_ce;
	assign debug[5] = (delay_sync_state == 3'b101)?1'b1:1'b0;
	assign debug[4] = sync_mon_valid;
	assign debug[3] = sync_mon_expect;
	assign debug[2] = bitslip_sync;
	assign debug[1] = vhdci_mux_bitslip;
	assign debug[0] = mux_synced;
	
	FPGA_MUX fpga_mux_inst
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
		.DELAY_BUSY              (delay_busy), //Output pins
		.DELAY_CLK               (clk_mux_div), //Input pins
		.DELAY_DATA_CAL          (delay_cal), //Input pins
		.DELAY_DATA_CE           (delay_ce),                     // Enable signal for delay 
		.DELAY_DATA_INC          (delay_inc),                    // Delay increment (high), decrement (low) signal
		.BITSLIP                 (vhdci_mux_bitslip),
		.CLK_RESET               (1'b0),
		.CLK_IN                  (clk_mux),
		.CLK_DIV_IN              (clk_mux_div),
		.LOCKED_IN               (mux_pll_locked),
		.LOCKED_OUT              (),
		.IO_RESET                (io_reset));

endmodule
