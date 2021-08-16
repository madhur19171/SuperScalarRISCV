module Processor_tb;
	reg clk;
	reg rst;
	
	Processor DUT (.clk(clk), .rst(rst));
	
	always #5 clk = ~clk;
	
	initial begin
		clk = 0;
		rst = 1;
	end
	
	initial begin
		$dumpfile("Processor.vcd");
		$dumpvars(0, Processor_tb);
		#20 rst = 0;
		
		#1000 $finish;
	end
endmodule
