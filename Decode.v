module Decode #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 1,
			    parameter TAG_WIDTH = 7,
			    
			    parameter OPCODE_WIDTH = 7,
			    parameter RF_WIDTH = 5,
			    
			    parameter RS2_OFFSET = 20,
			    parameter RS1_OFFSET = 15,
			    parameter RD_OFFSET = 7,
			    
			    parameter FUNC3_OFFSET = 12,
			    parameter FUNC3_WIDTH = 3,
			    
			    parameter FUNC7_OFFSET = 25,
			    parameter FUNC7_WIDTH = 7,
			    
			    parameter IMM_OFFSET = 20,
			    parameter IMM_WIDTH = 12,
			    
			    parameter EXEC_WIDTH = 4)//IPC:Instructions returned by the IM for every fetch.
			    
			   (input clk,
		  	    input rst,
		  	    
		  	    input [IPC * DATA_WIDTH - 1 : 0] DEC_data,//Receiving instructions group from instruction fetch
		  	    input DEC_dataValid,
		  	    
		  	    output [IPC * OPCODE_WIDTH - 1 : 0] opcode,
		  	    
		  	 //All the instructions in an Instruction Group will whare the 
		  	 //Instruction Bus. Because an instruction can be only one of the 4 types
		  	 //of instructions at any given time.
		  	 
		  	 //RType Bus
		  	 output [IPC - 1 : 0] RType_valid,
			 output  [IPC * RF_WIDTH - 1 : 0] rs2,
			 output  [IPC * RF_WIDTH - 1 : 0] rs1,
			 output  [IPC * RF_WIDTH - 1 : 0] rd,
			 output  [IPC * FUNC3_WIDTH - 1 : 0]func3,
			 output  [IPC * FUNC7_WIDTH - 1 : 0]func7,
			 
			 //IType Bus
			 output [IPC - 1 : 0] IType_valid,
			 output [IPC - 1 : 0] LoadOperation,//The operation is a load operation if this is 1
			 output  [IPC * DATA_WIDTH - 1 : 0]imm,
			 
			 //SType Bus
			 output [IPC - 1 : 0] SType_valid,
			 
			 //Execution ID
			 output [IPC * EXEC_WIDTH - 1 : 0] executionID   //To  Selects the appropriate Execution Unit
		  	 );
		  	   
		  	   
		  	   
	Instruction_Decode #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .OPCODE_WIDTH(OPCODE_WIDTH), .RF_WIDTH(RF_WIDTH), .RS2_OFFSET(RS2_OFFSET), .RS1_OFFSET(RS1_OFFSET), .RD_OFFSET(RD_OFFSET), .FUNC3_OFFSET(FUNC3_OFFSET), .FUNC3_WIDTH(FUNC3_WIDTH), .FUNC7_OFFSET(FUNC7_OFFSET), .FUNC7_WIDTH(FUNC7_WIDTH), .IMM_OFFSET(IMM_OFFSET), .IMM_WIDTH(IMM_WIDTH)) currentDecode
	(.clk(clk), .rst(rst), .DEC_data(DEC_data), .DEC_dataValid(DEC_dataValid), .RType_valid(RType_valid), .opcode(opcode), .rs2(rs2), .rs1(rs1), .rd(rd), .func3(func3), .func7(func7), .IType_valid(IType_valid), .LoadOperation(LoadOperation), .imm(imm), .SType_valid(SType_valid), .executionID(executionID));
		  	   
endmodule
