module I_Decode #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 4,
			    parameter TAG_WIDTH = 7,
			    
			    parameter OPCODE_WIDTH = 7,
			    parameter RF_WIDTH = 5,
			    
			    parameter RS1_OFFSET = 15,
			    parameter RD_OFFSET = 7,
			    
			    parameter FUNC3_OFFSET = 12,
			    parameter FUNC3_WIDTH = 12,
			    
			    parameter IMM_OFFSET = 20,
			    parameter IMM_WIDTH = 12,
			    
			    parameter EXEC_WIDTH = 4
			    )    
		(input clk,
		 input rst,
		  	    
		 input [DATA_WIDTH - 1 : 0] DEC_data,//Sending fetched instructions to next unit
		 input DEC_dataValid,
		  	    
		 output IType_valid,
		 
		 output LoadOperation,//The operation is a load operation if this is 1
		 
		 output [RF_WIDTH - 1 : 0] rs1,
		 output [RF_WIDTH - 1 : 0] rd,
		 output [FUNC3_WIDTH - 1 : 0]func3,
		 output [DATA_WIDTH - 1 : 0]imm
		);
		
	wire [OPCODE_WIDTH - 1 : 0] opcode;
	wire [IMM_WIDTH - 1 : 0] imm_temp;
		
	assign opcode = DEC_data[OPCODE_WIDTH - 1 : 0];
	assign IType_valid = (opcode == 7'b0010011 || opcode == 7'b0000011) ? DEC_dataValid : 0;//Load operations also use the same format
	
	assign LoadOperation = opcode == 'b0000011;
	
	assign rs1 = DEC_data[RS1_OFFSET +: RF_WIDTH];
	assign rd = DEC_data[RD_OFFSET +: RF_WIDTH];
	assign func3 = DEC_data[FUNC3_OFFSET +: FUNC3_WIDTH];
	assign imm_temp = DEC_data[IMM_OFFSET +: IMM_WIDTH];
	assign imm = {{(DATA_WIDTH - IMM_WIDTH){imm_temp[IMM_WIDTH - 1]}}, imm_temp};
endmodule

