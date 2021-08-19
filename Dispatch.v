module Dispatch #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 1,
			    parameter TAG_WIDTH = 7,
			    
			    parameter EXEC_WIDTH = 4)
			    
			    (
			         input clk,
			         input rst,
			         
			        //From ROB
			        input dispatch,
                    input  [DATA_WIDTH - 1 : 0] op1,    //rs1 for most of the instructions
                    input  [DATA_WIDTH - 1 : 0] op2,    //rs2/imm for most instructions
                    input [EXEC_WIDTH - 1 : 0] executionID,
                    input [IPC * TAG_WIDTH - 1 : 0] executionTag,
                    
                    //To ROB
                    output [2 ** EXEC_WIDTH - 1 : 0] availableFunctionalUnits,
                    
                    //Broadcast Sender
                    output dataAvailable,
                    output [IPC * TAG_WIDTH - 1 : 0] destinationTag,
                    output [IPC * DATA_WIDTH - 1 : 0] destinationData
			    );
			    
			    wire [DATA_WIDTH - 1 : 0] ADD_result;
			    wire ADD_done;
			    wire [DATA_WIDTH - 1 : 0] SUB_result;
			    wire SUB_done;
			    wire [DATA_WIDTH - 1 : 0] SLL_result;
			    wire SLL_done;
			    wire [DATA_WIDTH - 1 : 0] SLT_result;
			    wire SLT_done;
			    wire [DATA_WIDTH - 1 : 0] SLTU_result;
			    wire SLTU_done;
			    wire [DATA_WIDTH - 1 : 0] XOR_result;
			    wire XOR_done;
			    wire [DATA_WIDTH - 1 : 0] SRL_result;
			    wire SRL_done;
			    wire [DATA_WIDTH - 1 : 0] SRA_result;
			    wire SRA_done;
			    wire [DATA_WIDTH - 1 : 0] OR_result;
			    wire OR_done;
			    wire [DATA_WIDTH - 1 : 0] AND_result;
			    wire AND_done;
			    
			    
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

			  assign availableFunctionalUnits[SLTU] = 0;
			  assign availableFunctionalUnits[SLT] = 0;
			  assign availableFunctionalUnits[SLL] = 0;
			  assign availableFunctionalUnits[NOP] = 1;
			  
			  assign availableFunctionalUnits[10] = 0;
			  assign availableFunctionalUnits[11] = 0;
			  assign availableFunctionalUnits[12] = 0;
			  assign availableFunctionalUnits[13] = 0;
			  assign availableFunctionalUnits[14] = 0;
			    
		      FU_ADD #(.DATA_WIDTH(DATA_WIDTH), .LATENCY(1))fu_ADD
		              (.clk(clk), .rst(rst),
		               .ce(executionID == ADD & dispatch), .idle(availableFunctionalUnits[ADD]),
		               .data_0(op1), .data_1(op2), .result(ADD_result), .done(ADD_done));
		               
		      FU_SUB #(.DATA_WIDTH(DATA_WIDTH), .LATENCY(1))fu_SUB
		              (.clk(clk), .rst(rst),
		               .ce(executionID == SUB & dispatch), .idle(availableFunctionalUnits[SUB]),
		               .data_0(op1), .data_1(op2), .result(SUB_result), .done(SUB_done));
		               
		      FU_XOR #(.DATA_WIDTH(DATA_WIDTH), .LATENCY(1))fu_XOR
		              (.clk(clk), .rst(rst),
		               .ce(executionID == XOR & dispatch), .idle(availableFunctionalUnits[XOR]),
		               .data_0(op1), .data_1(op2), .result(XOR_result), .done(XOR_done));
		               
		               
		      FU_SRL #(.DATA_WIDTH(DATA_WIDTH), .LATENCY(4))fu_SRL
		              (.clk(clk), .rst(rst),
		               .ce(executionID == SRL & dispatch), .idle(availableFunctionalUnits[SRL]),
		               .data_0(op1), .data_1(op2), .result(SRL_result), .done(SRL_done));
		               
		               
		      FU_SRA #(.DATA_WIDTH(DATA_WIDTH), .LATENCY(4))fu_SRA
		              (.clk(clk), .rst(rst),
		               .ce(executionID == SRA & dispatch), .idle(availableFunctionalUnits[SRA]),
		               .data_0(op1), .data_1(op2), .result(SRA_result), .done(SRA_done));
		               
		               
		      FU_OR #(.DATA_WIDTH(DATA_WIDTH), .LATENCY(1))fu_OR
		              (.clk(clk), .rst(rst),
		               .ce(executionID == OR & dispatch), .idle(availableFunctionalUnits[OR]),
		               .data_0(op1), .data_1(op2), .result(OR_result), .done(OR_done));
		               
		               
		      FU_AND #(.DATA_WIDTH(DATA_WIDTH), .LATENCY(1))fu_AND
		              (.clk(clk), .rst(rst),
		               .ce(executionID == AND & dispatch), .idle(availableFunctionalUnits[AND]),
		               .data_0(op1), .data_1(op2), .result(AND_result), .done(AND_done));
			    
endmodule