`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:32:21 04/01/2011 
// Design Name: 
// Module Name:    edge_detect 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Generic clock sync
// Note that this doesn't debounce pushbuttons completely as the window
// is far too small. This doesn't matter in this example because the
// main FSM has a large delay after sending a packet during which the
// switch is not read.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module edge_detect (input async_sig,
                    input clk,
                    output reg rise,
                    output reg fall);

  reg [2:0] resync;

  always @(posedge clk)
  begin
    // detect rising and falling edges.
    rise <= resync[1] & !resync[2];
    fall <= resync[2] & !resync[1];
    // update history shifter.
    resync <= {resync[1:0], async_sig};
  end

endmodule

