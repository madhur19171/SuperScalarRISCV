module Dispatch #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 1,
			    parameter TAG_WIDTH = 7,
			    
			    parameter EXEC_WIDTH = 4)
			    
			    (
			         input clk,
			         input rst,
			         input halt,
			         
			        //From ROB
			        input dispatch,
                    input  [DATA_WIDTH - 1 : 0] op1,    //rs1 for most of the instructions
                    input  [DATA_WIDTH - 1 : 0] op2,    //rs2/imm for most instructions
                    input [EXEC_WIDTH - 1 : 0] executionID,
                    input [IPC * TAG_WIDTH - 1 : 0] executionTag,
                    
                    //To ROB
                    output [2 ** EXEC_WIDTH - 1 : 0] availableFunctionalUnits,
                    
                    //Broadcast Sender
                    output reg broadcastDataAvailable = 0,
                    output [IPC * TAG_WIDTH - 1 : 0] broadcastDestinationTag,
                    output [IPC * DATA_WIDTH - 1 : 0] broadcastDestinationData,
                    
                    //To Arbitration Unit
                    output queueFull,
                    output queueEmpty
			    );
			    
			    localparam NUM_OF_FU = 7;
			    
			    wire [DATA_WIDTH - 1 : 0] ADD_result;
			    wire ADD_done;
			    wire [TAG_WIDTH - 1 : 0] ADD_executionTag;
			    wire ADD_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] SUB_result;
			    wire SUB_done;
			    wire [TAG_WIDTH - 1 : 0] SUB_executionTag;
			    wire SUB_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] SLL_result;
			    wire SLL_done;
			    wire [TAG_WIDTH - 1 : 0] SLL_executionTag;
			    wire SLL_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] SLT_result;
			    wire SLT_done;
			    wire [TAG_WIDTH - 1 : 0] SLT_executionTag;
			    wire SLT_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] SLTU_result;
			    wire SLTU_done;
			    wire [TAG_WIDTH - 1 : 0] SLTU_executionTag;
			    wire SLTU_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] XOR_result;
			    wire XOR_done;
			    wire [TAG_WIDTH - 1 : 0] XOR_executionTag;
			    wire XOR_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] SRL_result;
			    wire SRL_done;
			    wire [TAG_WIDTH - 1 : 0] SRL_executionTag;
			    wire SRL_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] SRA_result;
			    wire SRA_done;
			    wire [TAG_WIDTH - 1 : 0] SRA_executionTag;
			    wire SRA_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] OR_result;
			    wire OR_done;
			    wire [TAG_WIDTH - 1 : 0] OR_executionTag;
			    wire OR_queued;
			    
			    wire [DATA_WIDTH - 1 : 0] AND_result;
			    wire AND_done;
			    wire [TAG_WIDTH - 1 : 0] AND_executionTag;
			    wire AND_queued;
			    
			    
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
			    
			    
		//Execution Units
		      FU_ADD #(.DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .LATENCY(1))fu_ADD
		              (.clk(clk), .rst(rst),
		               .ce(executionID == ADD & dispatch), .idle(availableFunctionalUnits[ADD]),
		               .executionTag_in(executionTag), .data_0(op1), .data_1(op2), .result(ADD_result), .done(ADD_done), .executionTag_out(ADD_executionTag),
		               .queued(ADD_queued));
		               
		      FU_SUB #(.DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .LATENCY(1))fu_SUB
		              (.clk(clk), .rst(rst),
		               .ce(executionID == SUB & dispatch), .idle(availableFunctionalUnits[SUB]),
		               .executionTag_in(executionTag), .data_0(op1), .data_1(op2), .result(SUB_result), .done(SUB_done), .executionTag_out(SUB_executionTag),
		               .queued(SUB_queued));
		               
		      FU_XOR #(.DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .LATENCY(1))fu_XOR
		              (.clk(clk), .rst(rst),
		               .ce(executionID == XOR & dispatch), .idle(availableFunctionalUnits[XOR]),
		               .executionTag_in(executionTag), .data_0(op1), .data_1(op2), .result(XOR_result), .done(XOR_done), .executionTag_out(XOR_executionTag),
		               .queued(XOR_queued));
		               
		               
		      FU_SRL #(.DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .LATENCY(4))fu_SRL
		              (.clk(clk), .rst(rst),
		               .ce(executionID == SRL & dispatch), .idle(availableFunctionalUnits[SRL]),
		               .executionTag_in(executionTag), .data_0(op1), .data_1(op2), .result(SRL_result), .done(SRL_done), .executionTag_out(SRL_executionTag),
		               .queued(SRL_queued));
		               
		               
		      FU_SRA #(.DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .LATENCY(4))fu_SRA
		              (.clk(clk), .rst(rst),
		               .ce(executionID == SRA & dispatch), .idle(availableFunctionalUnits[SRA]),
		               .executionTag_in(executionTag), .data_0(op1), .data_1(op2), .result(SRA_result), .done(SRA_done), .executionTag_out(SRA_executionTag),
		               .queued(SRA_queued));
		               
		               
		      FU_OR #(.DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .LATENCY(1))fu_OR
		              (.clk(clk), .rst(rst),
		               .ce(executionID == OR & dispatch), .idle(availableFunctionalUnits[OR]),
		               .executionTag_in(executionTag), .data_0(op1), .data_1(op2), .result(OR_result), .done(OR_done), .executionTag_out(OR_executionTag),
		               .queued(OR_queued));
		               
		               
		      FU_AND #(.DATA_WIDTH(DATA_WIDTH), .TAG_WIDTH(TAG_WIDTH), .LATENCY(1))fu_AND
		              (.clk(clk), .rst(rst),
		               .ce(executionID == AND & dispatch), .idle(availableFunctionalUnits[AND]),
		               .executionTag_in(executionTag), .data_0(op1), .data_1(op2), .result(AND_result), .done(AND_done), .executionTag_out(AND_executionTag),
		               .queued(AND_queued));
		      
		      
		               
            //Broadcast Queue
            
            
              integer i = 0;
              
              reg [DATA_WIDTH - 1 : 0] queue_result = 0;
              reg [TAG_WIDTH - 1 : 0] queue_executionTag = 0;
              wire to_queue;//Tells if data will be queued
              reg [NUM_OF_FU - 1 : 0] FU_queued = 0;
              reg [$clog2(NUM_OF_FU) - 1 : 0] queue_id = 0;//Tells the functional unit which is being sent to the queue
              
              
              wire [NUM_OF_FU - 1 : 0] FU_done = {ADD_done, SUB_done, XOR_done, SRL_done, SRA_done, OR_done, AND_done};
              wire [DATA_WIDTH * NUM_OF_FU - 1 : 0] FU_result = {ADD_result, SUB_result, XOR_result, SRL_result, SRA_result, OR_result, AND_result};
              wire [TAG_WIDTH * NUM_OF_FU - 1 : 0] FU_executionTag = {ADD_executionTag, SUB_executionTag, XOR_executionTag, SRL_executionTag, SRA_executionTag, OR_executionTag, AND_executionTag};
              assign {ADD_queued, SUB_queued, XOR_queued, SRL_queued, SRA_queued, OR_queued, AND_queued} = FU_queued;
              
              assign to_queue = |FU_done & ~queueFull;//If a functional unit has produced a result and there is space in the queue it will be added to the queue
              
              
               FIFO #(.DATA_WIDTH(DATA_WIDTH + TAG_WIDTH), .FIFO_DEPTH(32)) broadcastQueue//Both Data and Tag are stored in the same queue
                    (
                    .clk(clk),
                    .rst(rst),
                    
                    .empty(queueEmpty),
                    .rd_en(~halt),//If the Dispatch Unit has not been halted, and there is outstanding data in the broadcast queue, then broadcast it
                    .dout({broadcastDestinationTag, broadcastDestinationData}),

                    .full(queueFull),
                    .wr_en(to_queue),
                    .din({queue_executionTag, queue_result})
                );
              
              always @(posedge clk)
                if(rst)
                    broadcastDataAvailable <= 0;
                else
                    broadcastDataAvailable <= ~queueEmpty & ~halt;  //If the queue is not empty and Dispatch is not halted, we have broadcast data available.
              
              //Priority based queuing of data and tag
              always @(*)begin
                    queue_result = 0;
                    queue_executionTag = 0;
                    queue_id = 0;
                    for(i = 0; i < NUM_OF_FU; i = i + 1)begin
                        if(FU_done[i] & ~queueFull)begin
                            queue_result = FU_result[i * DATA_WIDTH +: DATA_WIDTH];
                            queue_executionTag = FU_executionTag[i * TAG_WIDTH +: TAG_WIDTH];
                            queue_id <= i;
                        end
                    end
              end
			  
			  always @(posedge clk)begin
                    FU_queued <= 0;
                    if(to_queue)
                        FU_queued[queue_id] <= 1;
              end
              
              /*The Design is internally controlled without a heavy global FSM or control unit.
              If the Queue is empty, then broadcastDataAvailable is 0 meaning that the broadcasting has stopped.
              While broadcasting has stopped, the other units in the pipeline like IF, Decode, Renaming can execute and 
              Dispatch their operation in the dispatch unit.
              This way, the Dispatch unit can start to fill the Broadcast queue.
              Once the broadcast queue is full, it will make the to_queue signal 0, 
              consequently the no new data will be written to the broadcast queue.
              With to_queue 0, FU_queued[queue_id] will also become 0 for the instruction that was just going to be
              broadcasted. So the idle signal of that functional unit will not go high and that functional unit will continue to
              to be occupied by the previous instruction. This way unless the Broadcast Queue has some empty space, bothDispatch unit and ROB 
              will be stalled. halt signal will halt the broadcast. broadcastDataAvailable will tell other units that a valid broadcast is available.
              */
endmodule