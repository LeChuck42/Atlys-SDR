`timescale 1ns / 1ps

module dac_tx (
	input wire clk,
	input wire reset_ext,
	
	output wire [7:0] data_p,
	output wire [7:0] data_n,

	output wire dataclk_p,
	output wire dataclk_n,
	
	output wire frame_p,
	output wire frame_n,
	
	input wire clk_dac_ref_p,
	input wire clk_dac_ref_n,
	
	input wire data_we,
	input wire [31:0] data_in,
	output wire [15:0] fifo_data_cnt,
	output wire fifo_full,
	output wire fifo_empty
	);

wire clk_dac_ref;
wire clk_dac0,   dcm_dac_clk0_prebufg;
wire clk_dac90,  dcm_dac_clk90_prebufg;
wire clk_dac180, dcm_dac_clk180_prebufg;
wire clk_dac270, dcm_dac_clk270_prebufg;
wire dcm_dac_locked;

wire reset = !dcm_dac_locked || reset_ext;


IBUFDS IBUFDS_dac_ref (
	.O(clk_dac_ref), // Buffer output
	.I(clk_dac_ref_p), // Diff_p buffer input (connect directly to top-level port)
	.IB(clk_dac_ref_n) // Diff_n buffer input (connect directly to top-level port)
);

// TODO define clock period (CLKIN_PERIOD)
// DCM providing output_clocks
DCM_SP dcm_dac (
	// Outputs
	.CLK0       (dcm_dac_clk0_prebufg),
	.CLK90      (dcm_dac_clk90_prebufg),
	.CLK180     (dcm_dac_clk180_prebufg),
	.CLK270     (dcm_dac_clk270_prebufg),
	.CLK2X180   (),
	.CLK2X      (),
	.CLKDV      (),
	.CLKFX180   (),
	.CLKFX      (),
	.LOCKED     (dcm_dac_locked),
	// Inputs
	.CLKFB      (clk_dac0),
	.CLKIN      (clk_dac_ref),
	.PSEN       (1'b0),
	.RST        (reset_ext)
);

BUFG dcm_dac_clk0_bufg
	(.O (clk_dac0),
	 .I (dcm_dac_clk0_prebufg));
	 
BUFG dcm_dac_clk90_bufg
	(.O (clk_dac90),
	 .I (dcm_dac_clk90_prebufg));
	 
BUFG dcm_dac_clk180_bufg
	(.O (clk_dac180),
	 .I (dcm_dac_clk180_prebufg));

BUFG dcm_dac_clk270_bufg
	(.O (clk_dac270),
	 .I (dcm_dac_clk270_prebufg));

reg        frame_sync;
reg        channel_sync;
reg [15:0] data_out;
wire [7:0] ddr_data_out;

genvar b;
generate
	for (b=0; b<8; b=b+1) begin : dac_dout
		ODDR2 #(
			.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1"
			.INIT(1'b0), // Sets initial state of the Q output to 1'b0 or 1'b1
			.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
		) ODDR2_inst (
			.Q(ddr_data_out[b]), // 1-bit DDR output data
			.C0(clk_dac0), // 1-bit clock input
			.C1(clk_dac180), // 1-bit clock input
			.CE(1'b1), // 1-bit clock enable input
			.D0(data_out[8+b]), // 1-bit data input (associated with C0)
			.D1(data_out[b]), // 1-bit data input (associated with C1)
			.R(reset), // 1-bit reset input
			.S(1'b0) // 1-bit set input
		);
		
		OBUFDS OBUFDS_data (
			.O(data_p[b]), // Diff_p output (connect directly to top-level port)
			.OB(data_n[b]), // Diff_n output (connect directly to top-level port)
			.I(ddr_data_out[b]) // Buffer input
		);
	end
endgenerate


OBUFDS OBUFDS_frame (
	.O(frame_p), // Diff_p output (connect directly to top-level port)
	.OB(frame_n), // Diff_n output (connect directly to top-level port)
	.I(frame_sync) // Buffer input
);

wire ddr_clk_out;
ODDR2 ODDR2_clk (
	.Q(ddr_clk_out), // 1-bit DDR output data
	.C0(clk_dac90), // 1-bit clock input
	.C1(clk_dac270), // 1-bit clock input
	.CE(1'b1), // 1-bit clock enable input
	.D0(1'b1), // 1-bit data input (associated with C0)
	.D1(1'b0), // 1-bit data input (associated with C1)
	.R(reset), // 1-bit reset input
	.S(1'b0) // 1-bit set input
);

OBUFDS OBUFDS_clk (
	.O(dataclk_p), // Diff_p output (connect directly to top-level port)
	.OB(dataclk_n), // Diff_n output (connect directly to top-level port)
	.I(ddr_clk_out) // Buffer input
);

wire [31:0] tx_fifo_output;

always @(posedge clk_dac0) begin
	if (reset == 1) begin
		frame_sync <= 0;
		channel_sync <= 0;
		data_out <= 0;
	end else begin
		if (channel_sync == 1'b1) begin
			frame_sync <= ~frame_sync;
			data_out <= tx_fifo_output[15:0];
		end else begin
			data_out <= tx_fifo_output[31:16];
		end
		channel_sync <= ~channel_sync;
	end
end

dac_sample_fifo tx_fifo (
	.rst(reset_ext), // input rst
	.wr_clk(clk), // input wr_clk
	.rd_clk(clk_dac0), // input rd_clk
	.din(data_in), // input [31 : 0] din
	.wr_en(data_we), // input wr_en
	.rd_en(channel_sync), // input rd_en
	.dout(tx_fifo_output), // output [31 : 0] dout
	.full(fifo_full), // output full
	.empty(fifo_empty), // output empty
	.wr_data_count(fifo_data_cnt[14:0]) // output [14 : 0] wr_data_count
);

assign fifo_data_cnt[15] = 0;

endmodule
