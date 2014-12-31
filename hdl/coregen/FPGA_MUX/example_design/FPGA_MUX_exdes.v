// file: FPGA_MUX_exdes.v
// (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

//----------------------------------------------------------------------------
// SelectIO wizard example design
//----------------------------------------------------------------------------
// This example design instantiates the IO circuitry
//----------------------------------------------------------------------------

`timescale 1ps/1ps

module FPGA_MUX_exdes
   // Clock -> q modeling delay
 #(
   // width of the data for the system
   parameter sys_w = 1,
   // width of the data for the device
   parameter dev_w = 8)
  (
   output     [1:0]       PATTERN_COMPLETED_OUT,
   // From the system into the device
   input      [sys_w-1:0] DATA_IN_FROM_PINS_P,
   input      [sys_w-1:0] DATA_IN_FROM_PINS_N,
   output [sys_w-1:0] DATA_OUT_TO_PINS_P,
   output [sys_w-1:0] DATA_OUT_TO_PINS_N,
   output  CLK_TO_PINS_P,
   output  CLK_TO_PINS_N,
   input                  CLK_IN,
   input                  CLK_RESET,
   input                  IO_RESET);


   localparam             num_serial_bits = dev_w/sys_w;
   wire        clkin1;

   reg  [num_serial_bits-1:0]  count_out;
   reg [num_serial_bits-1:0] local_counter;
   reg  [num_serial_bits-1:0]  count_out1;
   reg  [num_serial_bits-1:0]  count_out2;
   reg  [num_serial_bits-1:0]  pat_out;

   wire [dev_w-1:0]       data_in_to_device;
   reg [dev_w-1:0]       data_in_to_device_int2;
   reg [dev_w-1:0]       data_in_to_device_int3;

   wire  [dev_w-1:0]       data_out_from_device;
   wire [sys_w-1:0]  oserdes_d[0:7];   
   wire [sys_w-1:0]  iserdes_q[0:7];   // fills in starting with 0
   wire   [sys_w-1:0] data_out_to_pins_predelay;
   wire        clock_enable = 1'b1;
   wire   [sys_w-1:0] data_in_from_pins_int;
   wire   [sys_w-1:0] data_in_from_pins_delay;
   wire   [sys_w-1:0] tristate_predelay;

   wire                   clkfbout;
   wire                   clk_in_pll;
   wire                   clk_in_pll1;
   wire                   clkfbout_buf;
   wire                   locked_in;
   wire                   locked_out;
   (* KEEP = "TRUE" *) wire        clk_div_in_int;
   wire                   clk_div_in;

   reg rst_sync;
   reg rst_sync_int;
   reg rst_sync_int1;
   reg rst_sync_int2;
   reg rst_sync_int3;
   reg rst_sync_int4;
   reg rst_sync_int5;
   reg rst_sync_int6;
   reg [1:0] pattern_completed = 2'b00;
   reg        bitslip = 1'b0;
   reg        bitslip_int = 1'b0;
   reg        equal = 1'b0;
   reg        equal1 = 1'b0;
   reg  [2:0] count_out3;
   reg        start_count = 1'b0;
   reg [num_serial_bits-1:0] data_delay_int1[sys_w -1 :0];
   wire [num_serial_bits-1:0] data_delay[sys_w -1 :0];
   reg [num_serial_bits-1:0] data_delay_int2[sys_w -1 :0];
   reg start_check;

  
  IBUFG clkin_in_buf
   (.O (clkin1),
    .I (CLK_IN)
     );



   // set up the fabric PLL_BASE to drive the BUFPLL
   PLL_BASE
   #(.BANDWIDTH             ("OPTIMIZED"),
     .CLK_FEEDBACK          ("CLKFBOUT"),
     .COMPENSATION          ("SYSTEM_SYNCHRONOUS"),
     .DIVCLK_DIVIDE         (1),
     .CLKFBOUT_MULT         (4),
     .CLKFBOUT_PHASE        (0.000),
     .CLKOUT0_DIVIDE        (4),
     .CLKOUT0_PHASE         (0.000),
     .CLKOUT0_DUTY_CYCLE    (0.500),
     .CLKOUT2_DIVIDE        (4*num_serial_bits),
     .CLKOUT2_PHASE         (0.000),
     .CLKOUT2_DUTY_CYCLE    (0.500),
    .CLKIN_PERIOD          (10.0),
     .REF_JITTER            (0.010))
   pll_base_inst
     // Output clocks
    (.CLKFBOUT              (clkfbout),
     .CLKOUT0               (clk_in_pll1),
     .CLKOUT1               (),
     .CLKOUT2               (clk_div_in_int),
     .CLKOUT3               (),
     .CLKOUT4               (),
     .CLKOUT5               (),
     // Status and control signals
     .LOCKED                (locked_in),
     .RST                   (CLK_RESET),
      // Input clock control
     .CLKFBIN               (clkfbout_buf),
     .CLKIN                 (clkin1));

    BUFG clkfb_buf
    (.O (clkfbout_buf),
     .I (clkfbout));

    BUFG clkf_buf
    (.O (clk_div_in),
     .I (clk_div_in_int));

    BUFG clko_buf
    (.O (clk_in_pll),
     .I (clk_in_pll1));



   always @(posedge clk_div_in or posedge IO_RESET) begin
   if (IO_RESET) begin
       rst_sync <= 1'b1;
       rst_sync_int <= 1'b1;
       rst_sync_int1 <= 1'b1;
       rst_sync_int2 <= 1'b1;
       rst_sync_int3 <= 1'b1;
       rst_sync_int4 <= 1'b1;
       rst_sync_int5 <= 1'b1;
       rst_sync_int6 <= 1'b1;
    end
   else begin
       rst_sync <= 1'b0;
       rst_sync_int <= rst_sync;
       rst_sync_int1 <= rst_sync_int;
       rst_sync_int2 <= rst_sync_int1;
       rst_sync_int3 <= rst_sync_int2;
       rst_sync_int4 <= rst_sync_int3;
       rst_sync_int5 <= rst_sync_int4;
       rst_sync_int6 <= rst_sync_int5;
   end
   end




   always @(posedge clk_div_in) begin
   if (rst_sync_int6) 
     count_out3 <= 3'b000;
   else begin
     if (equal == 1'b1 && count_out3 < 3'b100) begin
       count_out3 <= count_out3 + 1'b1;
     end
     else begin
       count_out3 <= 3'b000; 
     end
   end
 end

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) begin
     equal1 <= 1'b0;
   end
   else if (count_out3 == 3'b100) begin
     equal1 <= equal;
   end
 end

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) begin
 
    count_out1 <= 0;
     pat_out <= 8'b10011011;
     end
   else if (locked_in) begin
     if (equal1 == 1'b0) begin
       count_out1 <= 0;
     pat_out <= 8'b10011011;
     end
     else begin
     count_out1 <= count_out1 + 1'b1;
     end
     end
   end

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) begin
     count_out2 <= 0;
   end
   else  begin
    if (equal1)
     count_out2 <= count_out1;
    else
     count_out2 <= pat_out;
   end
   end

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) begin
     count_out <= 0;
   end
   else  begin
     count_out <= count_out2;
   end
end

   genvar assg;
   genvar pinsss;
   for (assg = 0 ; assg < num_serial_bits ; assg = assg + 1) begin
   for (pinsss = 0 ; pinsss < sys_w ; pinsss = pinsss + 1)
     begin
       assign data_out_from_device[pinsss+sys_w*assg] = count_out[assg];
   end
   end

  assign data_delay[0] = {  
                         data_in_to_device[7],
 
                         data_in_to_device[6],
 
                         data_in_to_device[5],
 
                         data_in_to_device[4],
 
                         data_in_to_device[3],
 
                         data_in_to_device[2],
 
                         data_in_to_device[1],
 
   data_in_to_device[0]};

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) 
     start_check <= 1'b0;
   else
     begin
     if (data_delay[0] != 8'b00000000)
       start_check <= 1'b1;
     end 
   end 

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) 
     start_count <= 1'b0;
   else
     begin
     if (data_delay[0] == 8'b00000001 && equal == 1'b1)
       start_count <= 1'b1;
     end 
   end 

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) 
 
     local_counter <= 8'b00000000;
   else
     begin
   if (start_count) 
     local_counter <= local_counter + 1'b1;
   else
     local_counter <= 8'b00000000;
   end
   end

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) begin
     data_delay_int1[0] <= 8'b00000000;
     data_delay_int2[0] <= 8'b00000000;
     end
   else
     begin
     data_delay_int1[0] <= data_delay[0];
     data_delay_int2[0] <= data_delay_int1[0];

   end
   end

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) begin
     bitslip_int <= 1'b0;
     equal <= 1'b0;
     end
   else
     begin
   if (equal == 1'b0 && locked_in == 1'b1 && start_check == 1'b1) begin
       if ( (data_delay[0] == pat_out))
         begin
           bitslip_int <= 1'b0;
           equal <= 1'b1;
         end
       else
         begin
           bitslip_int <= 1'b1;
           equal <= 1'b0;
         end
       end
   else begin
     bitslip_int <= 1'b0;
   end
   end
   end

   reg [2:0] bit_count;

   always @(posedge clk_div_in) begin
   if (rst_sync_int6) begin
     bitslip <= 1'b0;
     bit_count <= 3'b000;
    end
   else
     begin
     bit_count <= bit_count + 1'b1; 
   if (bit_count == 3'b111) begin
   if (bitslip_int)
     bitslip <= ~bitslip;
   else
     bitslip <= 1'b0;
   end
   else
     bitslip <= 1'b0;
   end
   end

   always @(posedge clk_div_in) begin
   if (equal) begin
       if (
          (data_delay_int2[0] == local_counter)) begin
           if (local_counter == 8'b11111111)
             pattern_completed <= 2'b11;
            // all complete
           else
             pattern_completed <= 2'b01;
       end
       else begin
           if (start_count == 1'b1)
             pattern_completed <= 2'b10;
           else
             pattern_completed <= pattern_completed;  
       end
   end
   else begin
      pattern_completed <= 2'b00;
   end
 end



  assign PATTERN_COMPLETED_OUT =  pattern_completed;



 
   // Instantiate the IO design
   FPGA_MUX io_inst
    (
     // From the system into the device
     .DATA_IN_FROM_PINS_P     (DATA_IN_FROM_PINS_P),
     .DATA_IN_FROM_PINS_N     (DATA_IN_FROM_PINS_N),
     .DATA_IN_TO_DEVICE       (data_in_to_device),
     // From the drive out to the system
     .DATA_OUT_FROM_DEVICE    (data_out_from_device),
     .DATA_OUT_TO_PINS_P      (DATA_OUT_TO_PINS_P),
     .DATA_OUT_TO_PINS_N      (DATA_OUT_TO_PINS_N),
     .CLK_TO_PINS_P       (CLK_TO_PINS_P),
     .CLK_TO_PINS_N       (CLK_TO_PINS_N),
     .BITSLIP                 (bitslip),
     .CLK_IN                  (clk_in_pll1),
     .CLK_DIV_IN              (clk_div_in),
     .LOCKED_IN               (locked_in),
     .LOCKED_OUT              (locked_out),
     .CLK_RESET               (CLK_RESET),
     .IO_RESET                (rst_sync_int));

endmodule
