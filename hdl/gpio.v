module gpio
(
	input               wb_clk,
	input               wb_rst,
	
	input      [2:0]    wb_adr_i,
	input      [31:0]   wb_dat_i,
	input               wb_we_i,
	input               wb_cyc_i,
	input               wb_stb_i,
	input      [2:0]    wb_cti_i,
	input      [1:0]    wb_bte_i,
	input      [3:0]    wb_sel_i,
	output reg [31:0]   wb_dat_o,
	output reg          wb_ack_o,
	output              wb_err_o,
	output              wb_rty_o,
	
	input      [31:0]   gpio_i,
	output reg [31:0]   gpio_o,
	output reg [31:0]   gpio_dir_o
);


// GPIO dir register
always @(posedge wb_clk or posedge wb_rst)
	if (wb_rst)
		gpio_dir_o <= 0; // All set to in at reset
	else if (wb_cyc_i & wb_stb_i & wb_we_i) begin
		if (wb_adr_i == 4'b100) begin
			if (wb_sel_i[0] == 1)
				gpio_dir_o[7:0] <= wb_dat_i[7:0];
			if (wb_sel_i[1] == 1)
				gpio_dir_o[15:8] <= wb_dat_i[15:8];
			if (wb_sel_i[2] == 1)
				gpio_dir_o[23:16] <= wb_dat_i[23:16];
			if (wb_sel_i[3] == 1)
				gpio_dir_o[31:24] <= wb_dat_i[31:24];
		end
	end


// GPIO data out register
always @(posedge wb_clk or posedge wb_rst)
	if (wb_rst)
		gpio_o <= 0;
	else if (wb_cyc_i & wb_stb_i & wb_we_i) begin
		if (wb_adr_i == 4'b000) begin
			if (wb_sel_i[0] == 1)
				gpio_o[7:0] <= wb_dat_i[7:0];
			if (wb_sel_i[1] == 1)
				gpio_o[15:8] <= wb_dat_i[15:8];
			if (wb_sel_i[2] == 1)
				gpio_o[23:16] <= wb_dat_i[23:16];
			if (wb_sel_i[3] == 1)
				gpio_o[31:24] <= wb_dat_i[31:24];
		end
	end


// Register the gpio in signal
always @(posedge wb_clk or posedge wb_rst)
	if (wb_rst)
		wb_dat_o <= 0;
	else begin
		// Data regs
		if (wb_adr_i == 4'b0000)
			wb_dat_o <= (gpio_i & ~gpio_dir_o) | (gpio_o & gpio_dir_o);
		
		// Direction reg
		if (wb_adr_i == 4'b1000)
			wb_dat_o <= gpio_dir_o;
	end

// Ack generation
always @(posedge wb_clk or posedge wb_rst)
	if (wb_rst)
		wb_ack_o <= 0;
	else if (wb_ack_o)
		wb_ack_o <= 0;
	else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
		wb_ack_o <= 1;

assign wb_err_o = 0;
assign wb_rty_o = 0;

endmodule
