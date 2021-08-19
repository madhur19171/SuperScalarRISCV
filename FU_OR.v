module FU_OR #(parameter DATA_WIDTH = 32,
		parameter LATENCY = 1)
		(input clk,
		input rst,
		input ce,
		output idle,
		input [DATA_WIDTH - 1 : 0] data_0,
		input [DATA_WIDTH - 1 : 0] data_1,
		output [DATA_WIDTH - 1 : 0] result,
		output reg done = 0
		);
		
		reg [DATA_WIDTH - 1 : 0] op0 = 0, op1 = 0;
		reg idle_reg = 1;
		reg [$clog2(LATENCY) + 1: 0] counter = 0;
		reg runCounter = 0;
		
		always @(posedge clk)begin
			if(rst)begin
				op0 <= 0;
				op1 <= 0;
			end else
				if(ce) begin
					op0 <= data_0;
					op1 <= data_1;
				end
		end
		
		always @(posedge clk)begin
			if(rst)
				counter <= 1;
			else if(ce)begin
				counter <= 1;
			end else if(runCounter)
					counter <= counter + 1;
		end
		
		always @(posedge clk)begin
			if(rst)
				runCounter <= 0;
			else if(ce)begin
				runCounter <= 1;
			end else
				if(counter == LATENCY)
					runCounter <= 0;
		end
		
		always @(posedge clk)begin
			if(counter == LATENCY)
				done <= 1;
			else done <= 0;
		end
		
		always @(posedge clk)begin
			if(rst)
				idle_reg <= 1;
			else if(ce)
				idle_reg <= 0;
			else if(done)
				idle_reg <= 1;
		end
	   assign idle = idle_reg & ~ce;
		
		
		assign result = op1 | op0;
endmodule
