module InstructionFetch #(parameter ADDRESS_WIDTH = 3,
			    parameter DATA_WIDTH = 8,
			    parameter IPC = 1)//IPC:Instructions returned by the IM for every fetch.
			    
			   (input clk,
		  	    input rst,
		  	    input halt,
		  	    
		  	    output IF_ready,
		  	    
		  	    //Branch Signals
		  	    input isBranchTaken,
		  	    input [DATA_WIDTH - 1 : 0] branchTarget,
		  	    //Instruction Memory Interface
		  	    output IM_ce,
		  	    output [ADDRESS_WIDTH - 1 : 0] IM_address,
		  	    input [DATA_WIDTH - 1 : 0] IM_data,//Data Bus is as wide as the number of instructions issued
		  	    input IM_dataValid,
		  	    
		  	    //Output to next unit (Decode for now)
		  	    output [DATA_WIDTH - 1 : 0] IF_data,//Sending fetched instructions to next unit
		  	    output IF_dataValid,
		  	    
		  	    //Previous instruction buffers
		  	    output reg [DATA_WIDTH - 1 : 0] prev_IF_data = 0,//Sending fetched instructions to next unit
		  	    output reg prev_IF_dataValid = 0
		  	   );
		  	    
	//Every ROB Entry will have the following format:
	//<entry_valid> <source2_valid> <source2_tag> <source2_data> <source1_valid> <source1_tag> <source1_data> <destination_valid> <destination_data> <opcode>
	//   1-bit            1-bit          7-bit          32-bit         1-bit          7-bit         32-bit            1-bit               32-bit       7-bit 
		  	    
	reg [DATA_WIDTH - 1 : 0] programCounter = 0;
	
	always @(posedge clk, posedge rst)begin
		if(rst)
			programCounter <= 0;
		else if(~halt)
			if(isBranchTaken)
				programCounter <= branchTarget;
			else programCounter <= programCounter + IPC;
		else 
			programCounter <= programCounter;
	end
	
	always @(posedge clk, posedge rst)begin
		if(rst)begin
			prev_IF_data <= 0;
			prev_IF_dataValid <= 0;
		end
		else if(~halt)begin
			prev_IF_data <= IM_data;
			prev_IF_dataValid <= IM_dataValid;
		end
	end
	
	
	assign IM_address = programCounter;
	assign IM_ce = ~halt;//If the InstructionFetch is not halted, continue to read from IM
	
	assign IF_data = IM_data;
	assign IF_dataValid = IM_dataValid;
endmodule
