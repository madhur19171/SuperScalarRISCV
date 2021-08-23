module DecodeROBPipeline #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 1,
			    parameter TAG_WIDTH = 7,
			    
			    parameter OPCODE_WIDTH = 7,
			    parameter RF_WIDTH = 5,
			    parameter EXEC_WIDTH = 4
			)
			(
				input clk,
		  		input rst,
		  		input halt,
		  		
		  		input flush,
		  		
		  		output DecodeROBPipeline_ready,
		  		
		  		//RType Bus
		  	 	input [IPC - 1 : 0] RType_valid_Decode,
				//IType Bus
				input [IPC - 1 : 0] IType_valid_Decode,
				input [IPC * DATA_WIDTH - 1 : 0]imm_Decode,
				//SType Bus
				input [IPC - 1 : 0] SType_valid_Decode,
				
				input [IPC * EXEC_WIDTH - 1 : 0] executionID_Decode,
				
				//RType Bus
		  	 	output reg [IPC - 1 : 0] RType_valid_ROB = 0,
				//IType Bus
				output reg [IPC - 1 : 0] IType_valid_ROB = 0,
				output reg [IPC * DATA_WIDTH - 1 : 0]imm_ROB = 0,
				//SType Bus
				output reg [IPC - 1 : 0] SType_valid_ROB = 0,
				
				output reg [IPC * EXEC_WIDTH - 1 : 0] executionID_ROB = 0
		  	);
		  	
		  	
		always @(posedge clk, posedge rst)begin
			if(rst | flush)begin
				RType_valid_ROB <= 0;
				IType_valid_ROB <= 0;
				SType_valid_ROB <= 0;
				
				imm_ROB <= 0;
				
				executionID_ROB <= 0;
			end else if(~halt)begin
			
				RType_valid_ROB <= RType_valid_Decode;
				IType_valid_ROB <= IType_valid_Decode;
				SType_valid_ROB <= SType_valid_Decode;
				
				imm_ROB <= imm_Decode;
				
				executionID_ROB <= executionID_Decode;
			
			end
		end
endmodule
