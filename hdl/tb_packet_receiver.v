`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:56:53 12/08/2011
// Design Name:   packet_receiver
// Module Name:   C:/Users/Administrator/Desktop/Xilinx/atlys_ethernet_test_v1/atlys_ethernet_test_v1/tb_packet_receiver.v
// Project Name:  atlys_ethernet_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: packet_receiver
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_packet_receiver;

	// Inputs
	reg clk;
	reg reset;
	reg [3:0] rd_flags_i;
	reg [31:0] rd_data_i;
	reg rd_src_rdy_i;

	// Outputs
	wire rd_dst_rdy_o;
	wire data_out_en;
	wire [7:0] data_out;

	// Instantiate the Unit Under Test (UUT)
	packet_receiver uut (
		.clk(clk), 
		.reset(reset), 
		.rd_flags_i(rd_flags_i), 
		.rd_data_i(rd_data_i), 
		.rd_src_rdy_i(rd_src_rdy_i), 
		.rd_dst_rdy_o(rd_dst_rdy_o), 
		.data_out_en(data_out_en), 
		.data_out(data_out)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		rd_flags_i = 0;
		rd_data_i = 0;
		rd_src_rdy_i = 0;

		#100;
		reset <= 0;
		
		#100;
        
		 
		$display("%d: Sending a garbage packet", $time);
		start_packet(32'hffff_ffff);
		send_packet(32'heeee_eeee, 100);
		end_packet(32'hdddd_dddd, 2'b00);
		#200;
		
		$display("%d: Sending a non-UDP packet", $time);
		start_packet(32'hffff_ffff);
		send_packet(32'heeee_eeee, 1);
		send_packet(32'hdddd_dddd, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'heeee_eeee, 100);
		end_packet(32'hdddd_dddd, 2'b00);
		#200;
		
		
		$display("%d: Sending a UDP packet with no payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h001c_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_0000, 1); // data (2 bytes)
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		
		#200;
		
		$display("%d: Sending a UDP packet with one byte payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h001d_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_4100, 1); // data (1 bytes)
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		
		#200;
		
		$display("%d: Sending a UDP packet with two byte payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h001e_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_410a, 1); // data (2 bytes)
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		
		#200;
		
		$display("%d: Sending a UDP packet with three byte payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h001f_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_4142, 1); // data (2 bytes)
		send_packet(32'h4300_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		#200;
		
		$display("%d: Sending a UDP packet with four byte payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h0020_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_4142, 1); // data (2 bytes)
		send_packet(32'h4344_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		#200; 
		
		$display("%d: Sending a UDP packet with five byte payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h0021_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_4142, 1); // data (2 bytes)
		send_packet(32'h4344_4500, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		#200; 
				
		$display("%d: Sending a UDP packet with six byte payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h0022_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_4142, 1); // data (2 bytes)
		send_packet(32'h4344_4546, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		#200; 
						
		$display("%d: Sending a UDP packet with seven byte payload and padding", $time);
		start_packet(32'h0037_ffff);
		send_packet(32'h3737_0023, 1);
		send_packet(32'hdfff_3311, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h0023_032b, 1); // length (4)
		send_packet(32'h0000_ff11, 1); // UDP
		send_packet(32'hda82_a9fe, 1);
		send_packet(32'h8915_a9fe, 1);
		send_packet(32'h010f_ebf4, 1);
		send_packet(32'h3039_000a, 1);
		send_packet(32'hc480_4142, 1); // data (2 bytes)
		send_packet(32'h4344_4546, 1); // padding
		send_packet(32'h4700_0000, 1); // padding
		send_packet(32'h0000_0000, 1); // padding
		end_packet(32'h0000_0000, 2'b00); // padding
		#200; 
						
		$display("%d: Sending a long UDP packet", $time);
		start_packet(32'hffff_ffff);
		send_packet(32'heeee_eeee, 1);
		send_packet(32'hdddd_dddd, 1);
		send_packet(32'h0800_4500, 1); // IP
		send_packet(32'h03ea_ffff, 1);
		send_packet(32'h0000_4011, 1); // UDP
		send_packet(32'h0000_1111, 1);
		send_packet(32'h2222_3333, 1);
		send_packet(32'h4444_3333, 1);
		send_packet(32'h5555_6666, 1);
		send_packet(32'h0000_4142, 1);
		send_packet(32'h4344_4546, 242);
		end_packet(32'h4344_4546, 2'b01);
		#200;
		
		
		
		
		
		
		
		$stop;
	end

	
	// Display output data whenever it is valid
	always @(posedge clk)
		if(data_out_en) $display("Received: %d", data_out);
				
	
	always begin
		#10; clk = ~clk;
	end


	
	// Tasks
	task start_packet;
		input [31:0] word;
	begin
		rd_src_rdy_i <= 1;
		while (~rd_dst_rdy_o)
			@(posedge clk);
			
		@(posedge clk);
		rd_src_rdy_i <= 1;
		rd_flags_i <= 4'b0001;
		rd_data_i <= word;
		@(posedge clk);
	end
	endtask
	
	task end_packet;
		input [31:0] word;
		input [1:0] length;
	begin
		while(~rd_dst_rdy_o)
			@(posedge clk);
			
		rd_data_i <= word;
		rd_flags_i <= {length, 2'b10};
		@(posedge clk);
		rd_src_rdy_i <= 0;
	end
	endtask
	
	// Send a word any number of times
	task send_packet;
		input [31:0] word;
		input [31:0] repeat_times;
	begin
	
		// Stall until the receiver is ready
		while (~rd_dst_rdy_o)
			@(posedge clk);
		
		rd_flags_i <= 0;
		rd_data_i <= word;
		repeat(repeat_times) begin
			while(~rd_dst_rdy_o)
				@(posedge clk);
				
			@(posedge clk);
		end
		
	end
	endtask
	
endmodule

