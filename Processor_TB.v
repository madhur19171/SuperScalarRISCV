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
		
		#500 $finish;
	end
endmodule

/*
!!Motivation!! - opportunity for researcher and opensource
Supervisor name.
Page number, date
sell better
Macro Steps:
    what happens in the extension of the Dynamatic:
        Recode, Generate the component, Add support to verifier,generate 
        How the designing was done, once rough code is made, compare it with VHDL netlist
May be remove dot2vhdl vs dot2verilog
Sell floating point better
Remove Report Generation. Mention it in advantage
Remove wave dump image
*/