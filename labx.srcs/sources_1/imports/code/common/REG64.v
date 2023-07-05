`timescale 1ns / 1ps

module REG64(
                    input clk,
					input rst,
					input CE,
					input [63:0]D,
					output reg[63:0]Q
					);
					
	always @(posedge clk or posedge rst)
		if (rst)  Q <= 64'h0000000000000000;
		else if (CE) Q <= D;

endmodule


module REG64_PC(
                    input clk,
					input rst,
					input CE,
					input [63:0]D,
					output reg[63:0]Q
					);
					
	always @(posedge clk or posedge rst)
		if (rst)  Q <= 64'h80200000;
		else if (CE) Q <= D;

endmodule