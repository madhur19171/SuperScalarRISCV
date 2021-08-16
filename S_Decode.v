
module S_Decode #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 4,
			    parameter TAG_WIDTH = 7,
			    
			    parameter OPCODE_WIDTH = 7,
			    parameter RF_WIDTH = 5,
			    
			    parameter RS2_OFFSET = 20,
			    parameter RS1_OFFSET = 15,
			    parameter RD_OFFSET = 7,
			    
			    parameter FUNC3_OFFSET = 12,
			    parameter FUNC3_WIDTH = 12,
			    parameter FUNC7_OFFSET = 25,
			    parameter FUNC7_WIDTH = 7,
			    
			    parameter EXEC_WIDTH = 4
			    )    
		(input clk,
		 input rst,
		  	    
		 input [DATA_WIDTH - 1 : 0] DEC_data,//Sending fetched instructions to next unit
		 input DEC_dataValid,
		  	    
		 output SType_valid,
		 
		 output [RF_WIDTH - 1 : 0] rs2,
		 output [RF_WIDTH - 1 : 0] rs1,
		 output [FUNC3_WIDTH - 1 : 0]func3,
		 output [DATA_WIDTH - 1 : 0]imm
		);
		
	wire [OPCODE_WIDTH - 1 : 0] opcode;
	
	wire [RF_WIDTH - 1 : 0] imm_temp0;
	wire [FUNC7_WIDTH - 1 : 0] imm_temp1;
		
	assign opcode = DEC_data[OPCODE_WIDTH - 1 : 0];
	assign SType_valid = opcode == 7'b0100011 ? DEC_dataValid : 0;
	
	assign rs2 = DEC_data[RS2_OFFSET +: RF_WIDTH];
	assign rs1 = DEC_data[RS1_OFFSET +: RF_WIDTH];
	assign func3 = DEC_data[FUNC3_OFFSET +: FUNC3_WIDTH];
	
	assign imm_temp0 = DEC_data[RD_OFFSET +: RF_WIDTH];
	assign imm_temp1 = DEC_data[FUNC7_OFFSET +: FUNC7_WIDTH];
	
	assign imm = {{(DATA_WIDTH - (FUNC7_WIDTH + RF_WIDTH)){imm_temp1[FUNC7_WIDTH - 1]}}, imm_temp1, imm_temp0};
endmodule

