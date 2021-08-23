module ReorderBuffer #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 1,
			    parameter ROB_SIZE = 16,
			    parameter TAG_WIDTH = 4,
			    parameter EXEC_WIDTH = 4)//IPC:Instructions returned by the IM for every fetch.
			    
			   (input clk,
		  	    input rst,
		  	    input halt,
		  	    
		//From Decode (This needs to be pipelined as it will directly reach ROB before tag and data are read from the RF)
			 //RType Bus
		  	 input [IPC - 1 : 0] RType_valid,
			 //IType Bus
			 input [IPC - 1 : 0] IType_valid,
			 input [IPC * DATA_WIDTH - 1 : 0]imm,
			 //SType Bus
			 input [IPC - 1 : 0] SType_valid,
			 
			 //RType Bus
		  	 input [IPC - 1 : 0] forwarded_RType_valid,
			 //IType Bus
			 input [IPC - 1 : 0] forwarded_IType_valid,
			 //SType Bus
			 input [IPC - 1 : 0] forwarded_SType_valid,
			 
			 input [IPC * EXEC_WIDTH - 1 : 0] executionID_Decode,//Which execution unit to perform operation in
			 
		//From RF
			input [IPC * TAG_WIDTH - 1 : 0] rs2_tag,
		  	input [IPC - 1 : 0] rs2_dataValid,//If tag is valid, this means that data is invalid. If Tag is invalid, then data is valid
		 	input [IPC * DATA_WIDTH - 1 : 0] rs2_data,
		 	
		 	input [IPC * TAG_WIDTH - 1 : 0] rs1_tag,
		  	input [IPC - 1 : 0] rs1_dataValid,//If tag is valid, this means that data is invalid. If Tag is invalid, then data is valid
		 	input [IPC * DATA_WIDTH - 1 : 0] rs1_data,
		  	   
		//To RF
		  	    output reg [IPC * TAG_WIDTH - 1 : 0] destinationTag = 0,//It will be sent every time an instruction is allocated. It is the duty of 
		  	    							    //Receiver to decide if this tag is even needed
		//To Decode
                output reg full = 0,
                
        //To Dispatch:
                output reg dispatch = 0,
                output  [DATA_WIDTH - 1 : 0] op1,    //rs1 for most of the instructions
                output  [DATA_WIDTH - 1 : 0] op2,    //rs2/imm for most instructions
                output reg [EXEC_WIDTH - 1 : 0] executionID_DU = 0,
                output reg [IPC * TAG_WIDTH - 1 : 0] executionTag = 0, //Destination Tag associated with this execution. Execution unit will broadcast it
                                                                        //as soon as it finishes this instruction's execution
        //From Dispatch
                input [2 ** EXEC_WIDTH - 1 : 0] availableFunctionalUnits,
                
                //Broadcast Receiver
                input broadcastDataAvailable,
                input [IPC * TAG_WIDTH - 1 : 0] broadcastDestinationTag,
                input [IPC * DATA_WIDTH - 1 : 0] broadcastDestinationData,
                
        //From Arbitration Unit
                input allowDecode,  //Allows data from decode to be written to ROB
                input allowBroadcast,    //Allows data from Dispatch's Broadcast to be written to ROB
        //To Arbitration Unit
                output ongoingBroadcast //Tells the arbitration unit to keep the decode unit stalled as the broadcast is happening to multiple entries
		  	   );
	//Every ROB Entry will have the following format:
	//<entry_valid> <S-Type> <I-Type> <R-Type> <source2_valid> <source2_tag> <source2_data> <source1_valid> <source1_tag> <source1_data> <immediate_data> <destination_valid> <destination_data> <opcode>
	//   1-bit            1-bit         7-bit          32-bit         1-bit          7-bit         32-bit            1-bit               32-bit       7-bit 
	//ROB Starts
	
	//When ROB received all the data there is about an instruction, we start the dispatch of that instruction.
	
	reg [ROB_SIZE - 1 : 0] ROB_entryValid = 0;
	
	reg [ROB_SIZE - 1 : 0] ROB_SType = 0;
	reg [ROB_SIZE - 1 : 0] ROB_IType = 0;
	reg [ROB_SIZE - 1 : 0] ROB_RType = 0;
	
	reg [ROB_SIZE - 1 : 0] ROB_source2Valid = 0;
	reg [ROB_SIZE - 1 : 0] ROB_source1Valid = 0;
	reg [ROB_SIZE - 1 : 0] ROB_destinationValid = 0;//to be made 1 After Broadcast
	
	(* ram_style =  "register" *)reg [TAG_WIDTH - 1 : 0] ROB_source2Tag [ROB_SIZE - 1 : 0];
	(* ram_style =  "register" *)reg [TAG_WIDTH - 1 : 0] ROB_source1Tag [ROB_SIZE - 1 : 0];
	
	(* ram_style =  "BRAM" *)reg [DATA_WIDTH - 1 : 0] ROB_source2Data [ROB_SIZE - 1 : 0];
	(* ram_style =  "BRAM" *)reg [DATA_WIDTH - 1 : 0] ROB_source1Data [ROB_SIZE - 1 : 0];
	(* ram_style =  "BRAM" *)reg [DATA_WIDTH - 1 : 0] ROB_destinationData [ROB_SIZE - 1 : 0];
	
	(* ram_style =  "BRAM" *)reg [DATA_WIDTH - 1 : 0] ROB_immediateData [ROB_SIZE - 1 : 0];//Might work without this
	
	(* ram_style =  "register" *)reg [EXEC_WIDTH - 1 : 0] ROB_executionID [ROB_SIZE - 1 : 0];
	
	reg [ROB_SIZE - 1 : 0] ROB_dispatched = 0;
	
	reg [$clog2(ROB_SIZE) - 1 : 0] dispatchAddress = 0, dispatchAddress_reg = 0;
	reg dispatchDecision = 0;
	//ROB Ends
	
	reg [TAG_WIDTH - 1 : 0] robPointer = 0;
	reg [TAG_WIDTH - 1 : 0] broadcastMatchSource1 = 0;//Stores the address of the ROB entry whose source1 tag matches the Broadcasted Tag
	reg [TAG_WIDTH - 1 : 0] broadcastMatchSource2 = 0;//Stores the address of the ROB entry whose source2 tag matches the Broadcasted Tag
	
	reg ongoingBroadcastSource1 = 0, ongoingBroadcastSource2 = 0;
	
	reg [DATA_WIDTH - 1 : 0] source2DispatchData = 0;
	reg [DATA_WIDTH - 1 : 0] source1DispatchData = 0;
	reg [DATA_WIDTH - 1 : 0] immediateDispatchData = 0;
	
	wire instructionValid, instructionValid_forwarded;
	
	assign instructionValid = RType_valid | IType_valid | SType_valid;
	assign instructionValid_forwarded = forwarded_RType_valid | forwarded_IType_valid | forwarded_SType_valid;
	
	integer i;
	initial begin
		for(i = 0; i < ROB_SIZE; i = i + 1)begin
			ROB_source2Tag[i] = 0;
			ROB_source1Tag[i] = 0;
			ROB_source2Data[i] = 0;
			ROB_source1Data[i] = 0;
			ROB_destinationData[i] = 0;
			ROB_immediateData[i] = 0;
			ROB_executionID[i] = 0;
		end
	end
	
	//Updating ROB Pointer(Allocation)
	always @(posedge clk) begin
		if(rst)begin
			robPointer <= 0;
		end
		
		else if(~halt & instructionValid & ~full & allowDecode) begin //pointer updated only when there is a new Decode data allowed
			robPointer <= robPointer + IPC;
		end
	end
	
	always @(posedge clk) begin
		if(rst)begin
			destinationTag <= 0;
		end
		//Forwarded instruction needs to be checked because destination tag is provided to the RF as soon as it
		//is detected that the coming instruction is valid.
		//TODO : Is this even critical unless there is an instructiont that can produce output
		//as soon it is dispatched?
		else if(~halt & instructionValid_forwarded & ~full & allowDecode) begin//DestinationTag is updated and sent to RF only when ROB is storing Decode data
			destinationTag <= destinationTag + 1;
		end
	end
	
	//Indicating that the ROB is full and no new entries should be brought until some space is available
	always @(posedge clk) begin
		if(rst)begin
			full <= 0;
		end
		
		else if(~halt) begin
			full <= robPointer == ROB_SIZE - 2;
		end
	end
	
	//ROB Data:
	//Entry Valid
	always @(posedge clk) begin
		if(rst)begin
			ROB_entryValid[robPointer] <= 0;
		end
		
		else if(~halt) begin
	       if(allowDecode)begin
               if(instructionValid)
                   ROB_entryValid[robPointer] <= 1;
           end		
		end
	end
	
	//RType
	always @(posedge clk) begin
		if(rst)begin
			ROB_RType[robPointer] <= 0;
		end
		
		else if(~halt) begin
	       if(allowDecode)begin
               if(instructionValid)
                   ROB_RType[robPointer] <= RType_valid;
           end		
		end
	end
	
	//IType
	always @(posedge clk) begin
		if(rst)begin
			ROB_IType[robPointer] <= 0;
		end
		
		else if(~halt) begin
	       if(allowDecode)begin
               if(instructionValid)
                   ROB_IType[robPointer] <= IType_valid;
           end		
		end
	end
	
	//SType
	always @(posedge clk) begin
		if(rst)begin
			ROB_SType[robPointer] <= 0;
		end
		
		else if(~halt) begin
	       if(allowDecode)begin
               if(instructionValid)
                   ROB_SType[robPointer] <= SType_valid;
           end		
		end
	end
	
	
	//Source 2
	always @(posedge clk) begin
		if(rst)begin
			ROB_source2Valid[robPointer] <= 0;
		end
		
		else if(~halt) begin
            if(allowDecode)begin
                if(instructionValid)begin
                    ROB_source2Valid[robPointer] <= rs2_dataValid;
                    ROB_source2Tag[robPointer] <= rs2_tag;
                    ROB_source2Data[robPointer] <= rs2_data;
                end
            end
            
            else if(allowBroadcast)begin
                if(ongoingBroadcastSource2)
                    ROB_source2Valid[robPointer] <= 1;  //Data becomes valid after broadcast
                    ROB_source2Data[robPointer] <= broadcastDestinationData;
            end
		end
	end
	
	//Source 1
	always @(posedge clk) begin
		if(rst)begin
			ROB_source1Valid[robPointer] <= 0;
		end
		
		else if(~halt) begin
            if(allowDecode)begin
                if(instructionValid)begin
                    ROB_source1Valid[robPointer] <= rs1_dataValid;
                    ROB_source1Tag[robPointer] <= rs1_tag;
                    ROB_source1Data[robPointer] <= rs1_data;
                end
            end
            
            else if(allowBroadcast)begin
                if(ongoingBroadcastSource1)
                    ROB_source1Valid[robPointer] <= 1;  //Data becomes valid after broadcast
                    ROB_source1Data[robPointer] <= broadcastDestinationData;
            end
		end
	end
	
	//Immediate
	always @(posedge clk) begin
	   if(~halt) begin
	       if(allowDecode)begin
               if(instructionValid)
                   ROB_immediateData[robPointer] <= imm;
           end		
		end
	end
	
	//Execution ID
	always @(posedge clk) begin
	   if(~halt) begin
	       if(allowDecode)begin
               if(instructionValid)
                   ROB_executionID[robPointer] <= executionID_Decode;
           end		
		end
	end
	
	//To Dispatch Unit:
	//TODO: decide on in what order instruction checking for valid operands is to be done
	//to avoid dead lock situation
	
	integer j;
	always @(*)begin
	   dispatchAddress = 0;
	   dispatchDecision = 0;
	   for(j = ROB_SIZE - 1; j >= 0; j = j - 1)begin//Available functional units bus will be queried for each ready ROB entry and if the FU is idle, the instruction will be dispatched
	       if((~ROB_dispatched[j]) & ROB_entryValid[j] & ROB_RType[j] & ROB_source2Valid[j] & ROB_source1Valid[j] & availableFunctionalUnits[ROB_executionID[j]] )begin
	           dispatchAddress = j;
	           dispatchDecision = 1;
	       end 
	       
	       if((~ROB_dispatched[j]) & ROB_entryValid[j] & ROB_IType[j] & ROB_source1Valid[j] & availableFunctionalUnits[ROB_executionID[j]])begin//Immediate data will always be valid as it has no dependency
	           dispatchAddress = j;
	           dispatchDecision = 1;
	       end
	       //Store instruction to be added
	       
	   end
	end
	
	always @(posedge clk)begin
	   dispatch <= 0;
	   if(rst)begin
	       dispatch <= 0;
	       executionID_DU <= 0;
	       ROB_dispatched <= 0;
	       source1DispatchData <= 0;
	       source1DispatchData <= 0;
	       immediateDispatchData <= 0;
	   end
	   
	   else if(~halt & dispatchDecision) begin
	           dispatch <= 1;
               source1DispatchData <= ROB_source1Data[dispatchAddress];
               source2DispatchData <= ROB_source2Data[dispatchAddress];
               immediateDispatchData <= ROB_immediateData[dispatchAddress];
               executionID_DU <= ROB_executionID[dispatchAddress];
               ROB_dispatched[dispatchAddress] <= 1;
               dispatchAddress_reg <= dispatchAddress;
        end
	end
	
	//op1 and op2 assignments:
	assign op1 = source1DispatchData; //op1 usually contains only rs1
	//dispatchAddress_reg is used because dispatchAddress changes when DispatchData is produced.
	assign op2 = ROB_RType[dispatchAddress_reg] ? source2DispatchData : immediateDispatchData; //Add more conditions for other types of instructions
	
	
	//Broadcast Tag Matching(comparison intensive)
	
	integer k;
	//Matching Source1 Tag
	always @(*)begin
	   broadcastMatchSource1 = 0;
	   ongoingBroadcastSource1 = 0;
	   for(k = 0; k < ROB_SIZE; k = k + 1)begin
	       if(ROB_entryValid[k] & ~ROB_source1Valid[k] & broadcastDataAvailable & (ROB_source1Tag[k] == broadcastDestinationTag))begin
	           broadcastMatchSource1 = k;
	           ongoingBroadcastSource1 = 1;
	       end
	   end
	end
	
	//Matching Source2 Tag
	always @(*)begin
	   broadcastMatchSource2 = 0;
	   ongoingBroadcastSource2 = 0;
	   for(k = 0; k < ROB_SIZE; k = k + 1)begin
	       if(ROB_entryValid[k] & ~ROB_source2Valid[k] & broadcastDataAvailable & (ROB_source2Tag[k] == broadcastDestinationTag))begin
	           broadcastMatchSource2 = k;
	           ongoingBroadcastSource2 = 1;
	       end
	   end
	end
	
	assign ongoingBroadcast = ongoingBroadcastSource1 | ongoingBroadcastSource2;
		  	   
endmodule
