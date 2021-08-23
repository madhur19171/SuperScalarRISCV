module Instruction_Decode #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 4,
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
		  	    
		  	    input [IPC * DATA_WIDTH - 1 : 0] DEC_data,//Sending fetched instructions to next unit
		  	    input DEC_dataValid,
		  	    
		  	    output reg [IPC * OPCODE_WIDTH - 1 : 0] opcode,
		  	    
		  	 //All the instructions in an Instruction Group will whare the 
		  	 //Instruction Bus. Because an instruction can be only one of the 4 types
		  	 //of instructions at any given time.
		  	 
		  	 //RType Bus
		  	 output [IPC - 1 : 0] RType_valid,
			 output reg [IPC * RF_WIDTH - 1 : 0] rs2,
			 output reg [IPC * RF_WIDTH - 1 : 0] rs1,
			 output reg [IPC * RF_WIDTH - 1 : 0] rd,
			 output reg [IPC * FUNC3_WIDTH - 1 : 0]func3,
			 output reg [IPC * FUNC7_WIDTH - 1 : 0]func7,
			 
			 //IType Bus
			 output [IPC - 1 : 0] IType_valid,
			 output [IPC - 1 : 0] LoadOperation,//The operation is a load operation if this is 1
			 output reg [IPC * DATA_WIDTH - 1 : 0]imm,
			 
			 //SType Bus
			 output [IPC - 1 : 0] SType_valid,
			 
			 //Execution ID
			 output reg [IPC * EXEC_WIDTH - 1 : 0] executionID
		  	 );
		  	   
	//The Instruction buses will be organized as follows:
	//Eg. rs2 :-> [rs2_3][rs2_2][rs2_1][rs2_0] and so on all the other outputs are organized
	//The valid ports for each type of instruction is IPC width wide and if the index 3 of RType_valid is 1, this means that 
	//index 3 of rs2, rs1, rd belong to Rtype.
		  	   
	//Every ROB Entry will have the following format:
	//<entry_valid> <source2_valid> <source2_tag> <source2_data> <source1_valid> <source1_tag> <source1_data> <destination_valid> <destination_data> <opcode>
	//   1-bit            1-bit          7-bit          32-bit         1-bit          7-bit         32-bit            1-bit               32-bit       7-bit 
	
	wire [IPC * RF_WIDTH - 1 : 0] R_rs2;
	wire [IPC * RF_WIDTH - 1 : 0] R_rs1;
	wire [IPC * RF_WIDTH - 1 : 0] R_rd;
	wire [IPC * FUNC3_WIDTH - 1 : 0] R_func3;
	wire [IPC * FUNC7_WIDTH - 1 : 0] R_func7;
	
	wire [IPC * RF_WIDTH - 1 : 0] I_rs1;
	wire [IPC * RF_WIDTH - 1 : 0] I_rd;
	wire [IPC * FUNC3_WIDTH - 1 : 0] I_func3;
	wire [IPC * DATA_WIDTH - 1 : 0] I_imm;
	
	wire [IPC * RF_WIDTH - 1 : 0] S_rs2;
	wire [IPC * RF_WIDTH - 1 : 0] S_rs1;
	wire [IPC * FUNC3_WIDTH - 1 : 0] S_func3;
	wire [IPC * DATA_WIDTH - 1 : 0] S_imm;
        
    parameter NOP = 15  ;
    parameter AND = 0   ;
    parameter OR = 1    ;
    parameter SRA = 2   ;
    parameter SRL = 3   ;
    parameter XOR = 4   ;
    parameter SLTU = 5  ;
    parameter SLT = 6   ;
    parameter SLL = 7   ;
    parameter SUB = 8   ;
    parameter ADD = 9   ;
    parameter E_NOP = 15;
    parameter E_AND = 0 ;
    parameter E_OR = 1  ;
    parameter E_SRA = 2 ;
    parameter E_SRL = 3 ;
    parameter E_XOR = 4 ;
    parameter E_SLTU = 5;
    parameter E_SLT = 6 ;
    parameter E_SLL = 7 ;
    parameter E_SUB = 8 ;
    parameter E_ADD = 9 ;
	
	genvar i;
	generate
		for(i = IPC - 1; i >= 0; i = i - 1)begin
			R_Decode #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .OPCODE_WIDTH(OPCODE_WIDTH), .RF_WIDTH(RF_WIDTH), .RS2_OFFSET(RS2_OFFSET), .RS1_OFFSET(RS1_OFFSET), .RD_OFFSET(RD_OFFSET), .FUNC3_OFFSET(FUNC3_OFFSET), .FUNC3_WIDTH(FUNC3_WIDTH), .FUNC7_OFFSET(FUNC7_OFFSET), .FUNC7_WIDTH(FUNC7_WIDTH)) rdecode
			(.clk(clk), .rst(rst), .DEC_data(DEC_data[i * DATA_WIDTH +: DATA_WIDTH]), .DEC_dataValid(DEC_dataValid), .RType_valid(RType_valid[i]), .rs2(R_rs2[i * RF_WIDTH +: RF_WIDTH]), .rs1(R_rs1[i * RF_WIDTH +: RF_WIDTH]), .rd(R_rd[i * RF_WIDTH +: RF_WIDTH]), .func3(R_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH]), .func7(R_func7[i * FUNC7_WIDTH +: FUNC7_WIDTH]));
			
			I_Decode #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .OPCODE_WIDTH(OPCODE_WIDTH), .RF_WIDTH(RF_WIDTH), .RS1_OFFSET(RS1_OFFSET), .RD_OFFSET(RD_OFFSET), .FUNC3_OFFSET(FUNC3_OFFSET), .FUNC3_WIDTH(FUNC3_WIDTH), .IMM_OFFSET(IMM_OFFSET), .IMM_WIDTH(IMM_WIDTH)) idecode
			(.clk(clk), .rst(rst), .DEC_data(DEC_data[i * DATA_WIDTH +: DATA_WIDTH]), .DEC_dataValid(DEC_dataValid), .IType_valid(IType_valid[i]), .LoadOperation(LoadOperation[i]),  .rs1(I_rs1[i * RF_WIDTH +: RF_WIDTH]), .rd(I_rd[i * RF_WIDTH +: RF_WIDTH]), .func3(I_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH]), .imm(I_imm[i * DATA_WIDTH +: DATA_WIDTH]));
			
			S_Decode #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .OPCODE_WIDTH(OPCODE_WIDTH), .RF_WIDTH(RF_WIDTH), .RS2_OFFSET(RS2_OFFSET), .RS1_OFFSET(RS1_OFFSET), .RD_OFFSET(RD_OFFSET), .FUNC3_OFFSET(FUNC3_OFFSET), .FUNC3_WIDTH(FUNC3_WIDTH), .FUNC7_OFFSET(FUNC7_OFFSET), .FUNC7_WIDTH(FUNC7_WIDTH)) sdecode
			(.clk(clk), .rst(rst), .DEC_data(DEC_data[i * DATA_WIDTH +: DATA_WIDTH]), .DEC_dataValid(DEC_dataValid), .SType_valid(SType_valid[i]), .rs2(S_rs2[i * RF_WIDTH +: RF_WIDTH]), .rs1(S_rs1[i * RF_WIDTH +: RF_WIDTH]), .func3(S_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH]), .imm(S_imm[i * DATA_WIDTH +: DATA_WIDTH]));
			
			
			
			//TODO Try to reduce mux count somehow.
			always @(*)begin
				if(RType_valid[i])begin
					rs2[i * RF_WIDTH +: RF_WIDTH] = R_rs2[i * RF_WIDTH +: RF_WIDTH];
					rs1[i * RF_WIDTH +: RF_WIDTH] = R_rs1[i * RF_WIDTH +: RF_WIDTH];
					rd[i * RF_WIDTH +: RF_WIDTH] = R_rd[i * RF_WIDTH +: RF_WIDTH];
					func3[i * FUNC3_WIDTH +: FUNC3_WIDTH] = R_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH];
					func7[i * FUNC7_WIDTH +: FUNC7_WIDTH] = R_func7[i * FUNC7_WIDTH +: FUNC7_WIDTH];
					
					imm[i * DATA_WIDTH +: DATA_WIDTH] = 0;
					
					case(R_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH])
                       3'b111 : executionID = E_AND;
                       3'b110 : executionID = E_OR;
                       3'b101 : executionID = R_func7[i * FUNC7_WIDTH +: FUNC7_WIDTH] == 7'b0100000 ? E_SRA : E_SRL;
                       3'b100 : executionID = E_XOR;
                       3'b011 : executionID = E_SLTU;
                       3'b010 : executionID = E_SLT;
                       3'b001 : executionID = E_SLL;
                       3'b000 : executionID = R_func7[i * FUNC7_WIDTH +: FUNC7_WIDTH] == 7'b0100000 ? E_SUB : E_ADD;
                       default : executionID = E_NOP;
                   endcase
				end
				
				else if(IType_valid[i]) begin
					rs1[i * RF_WIDTH +: RF_WIDTH] = I_rs1[i * RF_WIDTH +: RF_WIDTH];
					rd[i * RF_WIDTH +: RF_WIDTH] = I_rd[i * RF_WIDTH +: RF_WIDTH];
					func3[i * FUNC3_WIDTH +: FUNC3_WIDTH] = I_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH];
					imm[i * DATA_WIDTH +: DATA_WIDTH] = I_imm[i * DATA_WIDTH +: DATA_WIDTH];
					
					rs2[i * RF_WIDTH +: RF_WIDTH] = 0;
					func7[i * FUNC7_WIDTH +: FUNC7_WIDTH] = 0;
					
				    case(I_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH])
                       3'b111 : executionID = E_AND;
                       3'b110 : executionID = E_OR;
                       3'b100 : executionID = E_XOR;
                       3'b011 : executionID = E_SLTU;
                       3'b010 : executionID = E_SLT;
                       3'b000 : executionID = R_func7[i * FUNC7_WIDTH +: FUNC7_WIDTH] == 7'b0100000 ? E_SUB : E_ADD;
                       default : executionID = E_NOP;
                   endcase
				end
				
				else if(SType_valid[i]) begin
					rs2[i * RF_WIDTH +: RF_WIDTH] = S_rs2[i * RF_WIDTH +: RF_WIDTH];
					rs1[i * RF_WIDTH +: RF_WIDTH] = S_rs1[i * RF_WIDTH +: RF_WIDTH];
					func3[i * FUNC3_WIDTH +: FUNC3_WIDTH] = S_func3[i * FUNC3_WIDTH +: FUNC3_WIDTH];
					imm[i * DATA_WIDTH +: DATA_WIDTH] = S_imm[i * DATA_WIDTH +: DATA_WIDTH];
					
					rd[i * RF_WIDTH +: RF_WIDTH] = 0;
					func7[i * FUNC7_WIDTH +: FUNC7_WIDTH] = 0;
					
					executionID = E_ADD;
					
				end else begin
					rs2[i * RF_WIDTH +: RF_WIDTH] = 0;
					rs1[i * RF_WIDTH +: RF_WIDTH] = 0;
					rd[i * RF_WIDTH +: RF_WIDTH] = 0;
					func3[i * FUNC3_WIDTH +: FUNC3_WIDTH] = 0;
					func7[i * FUNC7_WIDTH +: FUNC7_WIDTH] = 0;
					imm[i * DATA_WIDTH +: DATA_WIDTH] = 0;
					
					executionID[i * EXEC_WIDTH +: EXEC_WIDTH] = E_NOP;
				end
				
				opcode[i *OPCODE_WIDTH +: OPCODE_WIDTH] = DEC_data[i * DATA_WIDTH +: OPCODE_WIDTH];
			end
		end
	endgenerate
		
	  	   
endmodule

