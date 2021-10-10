module Processor(input clk,
		  input rst,//Remove
		  input we,//Remove
		  input [5 : 0] address,//Remove
		  input [31 : 0] data,//Remove
		  output [31 : 0]broadcast_data//Remove
		  );
		  
	parameter ADDRESS_WIDTH = 10;
	parameter DATA_WIDTH = 32;
	parameter IPC = 1;
	parameter TAG_WIDTH = 4;
			    
	parameter OPCODE_WIDTH = 7;
	parameter RF_WIDTH = 5;
			    
	parameter RS2_OFFSET = 20;
	parameter RS1_OFFSET = 15;
	parameter RD_OFFSET = 7;
			    
	parameter FUNC3_OFFSET = 12;
	parameter FUNC3_WIDTH = 3;
			    
	parameter FUNC7_OFFSET = 25;
	parameter FUNC7_WIDTH = 7;
			    
	parameter IMM_OFFSET = 20;
	parameter IMM_WIDTH = 12;
	
	parameter ROB_SIZE = 16;
	
	parameter EXEC_WIDTH = 4;
	
	
	wire IF_IM_ce;
	wire [ADDRESS_WIDTH - 1 : 0] IF_IM_address;
	wire [DATA_WIDTH - 1 : 0] IM_IF_data;
	wire IM_IF_dataValid;
	
	wire [DATA_WIDTH - 1 : 0] IF_Decode_data;
	wire IF_Decode_dataValid;
	
	wire [IPC * OPCODE_WIDTH - 1 : 0] Decode_RF_opcode;
	wire [IPC - 1 : 0] Decode_RF_RType_valid;
	wire [IPC * RF_WIDTH - 1 : 0] Decode_RF_rs2;
	wire [IPC * RF_WIDTH - 1 : 0] Decode_RF_rs1;
	wire [IPC * RF_WIDTH - 1 : 0] Decode_RF_rd;
	wire [IPC * FUNC3_WIDTH - 1 : 0] Decode_RF_func3;
	wire [IPC * FUNC7_WIDTH - 1 : 0] Decode_RF_func7;
	wire [IPC - 1 : 0] Decode_RF_IType_valid;
	wire [IPC - 1 : 0] Decode_RF_LoadOperation;
	wire [IPC * DATA_WIDTH - 1 : 0] Decode_RF_imm;
	wire [IPC - 1 : 0] Decode_RF_SType_valid;
	
    wire [IPC * TAG_WIDTH - 1 : 0] RF_ROB_rs2_tag;
	wire [IPC - 1 : 0] RF_ROB_rs2_dataValid;
	wire [IPC * DATA_WIDTH - 1 : 0] RF_ROB_rs2_data;
    wire [IPC * TAG_WIDTH - 1 : 0] RF_ROB_rs1_tag;
	wire [IPC - 1 : 0] RF_ROB_rs1_dataValid;
	wire [IPC * DATA_WIDTH - 1 : 0] RF_ROB_rs1_data;
	
	wire [IPC - 1 : 0] RType_valid_ROB;
	wire [IPC - 1 : 0] IType_valid_ROB;
	wire [IPC * DATA_WIDTH - 1 : 0]imm_ROB;
	wire [IPC - 1 : 0] SType_valid_ROB;
	
	wire [IPC * TAG_WIDTH - 1 : 0] ROB_RF_destinationTag;
	wire ROB_Decode_full;
	
	wire [IPC * EXEC_WIDTH - 1 : 0] Decode_executionID;
	wire [IPC * EXEC_WIDTH - 1 : 0] ROB_executionID;
	
	wire ROB_DU_dispatch;
	wire [DATA_WIDTH - 1 : 0] ROB_DU_op1;
	wire [DATA_WIDTH - 1 : 0] ROB_DU_op2;
	wire [EXEC_WIDTH - 1 : 0] ROB_DU_executionID;
	wire [TAG_WIDTH - 1 : 0] ROB_DU_executionTag;
	
	wire [2 ** EXEC_WIDTH - 1 : 0] DU_ROB_availableFunctionalUnits;
	
	wire ongoingBroadcast;
    wire ROB_full;
    wire queueFull;
    wire queueEmpty;
    wire broadcastDataAvailable;
    wire  allowDecode;
    wire  allowBroadcast;
    wire  IF_halt;
    wire  RF_halt;
    wire  DecodeROBPipeline_halt;
    wire  ROB_halt;
    wire  Dispatch_halt;
    
    wire [TAG_WIDTH - 1 : 0] broadcastDestinationTag;
    wire [DATA_WIDTH - 1 : 0] broadcastDestinationData;
	
	assign broadcast_data = broadcastDestinationData;//Remove
	
	InstructionMemory #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC)) InstructionMemory_0 
		(.clk(clk), .rst(rst), .ce(IF_IM_ce), .address(IF_IM_address), .data(IM_IF_data), .dataValid(IM_IF_dataValid),
		.we(we), .w_address(address), .w_data(data));
		
	InstructionFetch #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC)) InstructionFetch_0
		(.clk(clk), .rst(rst), .halt(IF_halt), .isBranchTaken(0), .branchTarget(0), .IM_ce(IF_IM_ce), .IM_address(IF_IM_address), .IM_data(IM_IF_data), .IM_dataValid(IM_IF_dataValid), .IF_data(IF_Decode_data), .IF_dataValid(IF_Decode_dataValid));

	Decode #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .OPCODE_WIDTH(OPCODE_WIDTH), .RF_WIDTH(RF_WIDTH), .RS2_OFFSET(RS2_OFFSET), .RS1_OFFSET(RS1_OFFSET), .RD_OFFSET(RD_OFFSET), .FUNC3_OFFSET(FUNC3_OFFSET), .FUNC3_WIDTH(FUNC3_WIDTH), .FUNC7_OFFSET(FUNC7_OFFSET), .FUNC7_WIDTH(FUNC7_WIDTH), .IMM_OFFSET(IMM_OFFSET), .IMM_WIDTH(IMM_WIDTH), .EXEC_WIDTH(EXEC_WIDTH)) Decode_1
		(.clk(clk), .rst(rst), .DEC_data(IF_Decode_data), .DEC_dataValid(IF_Decode_dataValid), .opcode(Decode_RF_opcode), .RType_valid(Decode_RF_RType_valid), .rs2(Decode_RF_rs2), .rs1(Decode_RF_rs1), .rd(Decode_RF_rd), .func3(Decode_RF_func3), .func7(Decode_RF_func7), .IType_valid(Decode_RF_IType_valid), .LoadOperation(Decode_RF_LoadOperation), .imm(Decode_RF_imm), .SType_valid(Decode_RF_SType_valid), .executionID(Decode_executionID));
    
    FutureRegisterFile #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .OPCODE_WIDTH(OPCODE_WIDTH), .RF_WIDTH(RF_WIDTH)) FutureRegisterFile_0
        (.clk(clk), .rst(rst), .halt(RF_halt), .RType_valid(Decode_RF_RType_valid), .IType_valid(Decode_RF_IType_valid), .SType_valid(Decode_RF_SType_valid), .rs2(Decode_RF_rs2), .rs2_tag(RF_ROB_rs2_tag), .rs2_dataValid(RF_ROB_rs2_dataValid), .rs2_data(RF_ROB_rs2_data), .rs1(Decode_RF_rs1), .rs1_tag(RF_ROB_rs1_tag), .rs1_dataValid(RF_ROB_rs1_dataValid), .rs1_data(RF_ROB_rs1_data), .destinationTag(ROB_RF_destinationTag), .rd(Decode_RF_rd),
        .allowDecode(allowDecode), .allowBroadcast(allowBroadcast), .broadcastDataAvailable(broadcastDataAvailable), .broadcastDestinationTag(broadcastDestinationTag), .broadcastDestinationData(broadcastDestinationData));

    DecodeROBPipeline #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .OPCODE_WIDTH(OPCODE_WIDTH), .RF_WIDTH(RF_WIDTH), .EXEC_WIDTH(EXEC_WIDTH)) DecodeROBPipeline_0
        (.clk(clk), .rst(rst), .halt(DecodeROBPipeline_halt), .flush(0), .RType_valid_Decode(Decode_RF_RType_valid), .IType_valid_Decode(Decode_RF_IType_valid), .SType_valid_Decode(Decode_RF_SType_valid), .imm_Decode(Decode_RF_imm), .executionID_Decode(Decode_executionID), .RType_valid_ROB(RType_valid_ROB), .IType_valid_ROB(IType_valid_ROB), .SType_valid_ROB(SType_valid_ROB), .imm_ROB(imm_ROB), .executionID_ROB(ROB_executionID));

    ReorderBuffer #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .ROB_SIZE(ROB_SIZE), .EXEC_WIDTH(EXEC_WIDTH)) ReorderBuffer_0
        (.clk(clk), .rst(rst), .halt(ROB_halt), .full(ROB_full), .RType_valid(RType_valid_ROB), .IType_valid(IType_valid_ROB), .SType_valid(SType_valid_ROB), .imm(imm_ROB), .forwarded_RType_valid(Decode_RF_RType_valid), .forwarded_IType_valid(Decode_RF_IType_valid), .forwarded_SType_valid(Decode_RF_SType_valid), .rs2_tag(RF_ROB_rs2_tag), .rs2_dataValid(RF_ROB_rs2_dataValid), .rs2_data(RF_ROB_rs2_data), .rs1_tag(RF_ROB_rs1_tag), .rs1_dataValid(RF_ROB_rs1_dataValid), .rs1_data(RF_ROB_rs1_data), .destinationTag(ROB_RF_destinationTag), .executionID_Decode(ROB_executionID), 
        .dispatch(ROB_DU_dispatch), .op1(ROB_DU_op1), .op2(ROB_DU_op2), .executionID_DU(ROB_DU_executionID), .executionTag(ROB_DU_executionTag), .availableFunctionalUnits(DU_ROB_availableFunctionalUnits),
        .broadcastDataAvailable(broadcastDataAvailable), .broadcastDestinationTag(broadcastDestinationTag), .broadcastDestinationData(broadcastDestinationData),
        .allowDecode(allowDecode), .allowBroadcast(allowBroadcast), .ongoingBroadcast(ongoingBroadcast));

    Dispatch #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .IPC(IPC), .TAG_WIDTH(TAG_WIDTH), .EXEC_WIDTH(EXEC_WIDTH)) dispatchUnit
        (.clk(clk), .rst(rst), .halt(Dispatch_halt), .dispatch(ROB_DU_dispatch), .op1(ROB_DU_op1), .op2(ROB_DU_op2), .executionID(ROB_DU_executionID), .executionTag(ROB_DU_executionTag), .availableFunctionalUnits(DU_ROB_availableFunctionalUnits),
         .broadcastDataAvailable(broadcastDataAvailable), .broadcastDestinationTag(broadcastDestinationTag), .broadcastDestinationData(broadcastDestinationData),
         .queueFull(queueFull), .queueEmpty(queueEmpty));

    ArbitrationUnit arbitrationUnit (.clk(clk), .rst(rst), 
                                     .ongoingBroadcast(ongoingBroadcast), .ROB_full(ROB_full),
                                     .queueFull(queueFull), .queueEmpty(queueEmpty), .broadcastDataAvailable(broadcastDataAvailable),
                                     .allowDecode(allowDecode), .allowBroadcast(allowBroadcast), .IF_halt(IF_halt),
                                     .RF_halt(RF_halt), .DecodeROBPipeline_halt(DecodeROBPipeline_halt), .ROB_halt(ROB_halt), .Dispatch_halt(Dispatch_halt));

endmodule
