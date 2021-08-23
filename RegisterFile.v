module RegisterFile #(parameter ADDRESS_WIDTH = 10,
                parameter DATA_WIDTH = 32,
			    parameter IPC = 1,
			    parameter TAG_WIDTH = 7,
			    
			    parameter OPCODE_WIDTH = 7,
			    parameter RF_WIDTH = 5)
			    
		 (input clk,
		  input rst, 
		  input halt,
		  
		  output RF_ready,
		  
		  //Current Instruction Ports
		  input [IPC - 1 : 0] RType_valid,
		  input [IPC - 1 : 0] IType_valid,
		  input [IPC - 1 : 0] SType_valid,
		  	//RS2
		  input [IPC * RF_WIDTH - 1 : 0] rs2,
		  output reg [IPC * TAG_WIDTH - 1 : 0] rs2_tag = 0,
		  output reg [IPC - 1 : 0] rs2_dataValid = 0,//If tag is valid, this means that data is invalid. If Tag is invalid, then data is valid
		  output reg [IPC * DATA_WIDTH - 1 : 0] rs2_data = 0,
		  	//RS1
		  input [IPC * RF_WIDTH - 1 : 0] rs1,
		  output reg [IPC * TAG_WIDTH - 1 : 0] rs1_tag = 0,
		  output reg [IPC - 1 : 0] rs1_dataValid = 0,
		  output reg [IPC * DATA_WIDTH - 1 : 0] rs1_data = 0,
		  
		  //From ROB
		  input [IPC * TAG_WIDTH - 1 : 0] destinationTag,
		  //From Decode
		  input [IPC * RF_WIDTH - 1 : 0] rd
		  );
		  
	//The Register File will be organized as follows:
	//32 entries.
	//Entry 0 is always valid and always set to 0
	//Each entry will have the following contents <valid>  <Tag>   <data>
	//						  1-bit  7-bit   32-bit
	//But these 3 components of the register file will be completely separate from each other
		  
	(* ram_style =  "BRAM" *) reg [DATA_WIDTH - 1 : 0] RF_DATA [0 : 2 ** RF_WIDTH - 1];	//Should be RAW type of RAM
	reg [TAG_WIDTH - 1 : 0] RF_TAG [0 : 2 ** RF_WIDTH - 1]; 
	reg [2 ** RF_WIDTH - 1 : 0] RF_VALID = 1;

	
	integer j;
	initial begin
		for(j = 0; j < 2 ** RF_WIDTH; j = j + 1)begin
		//Setting all data to 0 and validating all RF locations.
			RF_DATA[j] = 0;
			RF_VALID[j] = 1;
			RF_TAG[j] = 0;
		end
	end
	
	genvar i;
	//This block is critically dependent on IPC
	generate
		for(i = IPC - 1; i >= 0; i = i - 1)begin
			always @(posedge clk, posedge rst)begin
				if(rst)begin
					rs2_tag[i * TAG_WIDTH +: TAG_WIDTH] <= 0;
					rs2_dataValid[i] <= 0;
					rs2_data[i * DATA_WIDTH +: DATA_WIDTH] <= 0;
					
					rs1_tag[i * TAG_WIDTH +: TAG_WIDTH] <= 0;
					rs1_dataValid[i] <= 0;
					rs1_data[i * DATA_WIDTH +: DATA_WIDTH] <= 0;
				end
				
				else begin
				
					//Always Read the data. The valid bits will decide if that data is of any use
					rs2_tag[i * TAG_WIDTH +: TAG_WIDTH] <= RF_TAG[rs2[i * RF_WIDTH +: RF_WIDTH]];
					rs2_data[i * DATA_WIDTH +: DATA_WIDTH] <= RF_DATA[rs2[i * RF_WIDTH +: RF_WIDTH]];
					
					rs1_tag[i * TAG_WIDTH +: TAG_WIDTH] <= RF_TAG[rs1[i * RF_WIDTH +: RF_WIDTH]];
					rs1_data[i * DATA_WIDTH +: DATA_WIDTH] <= RF_DATA[rs1[i * RF_WIDTH +: RF_WIDTH]];
					
					if(RType_valid[i])begin
					//	i-th instruction is Register Type
						rs2_dataValid[i] <= RF_VALID[rs2[i * RF_WIDTH +: RF_WIDTH]];
						rs1_dataValid[i] <= RF_VALID[rs1[i * RF_WIDTH +: RF_WIDTH]];
					end
					
					else if(IType_valid[i])begin
					//	i-th instruction is Immediate Type
						rs2_dataValid[i] <= 0;
						rs1_dataValid[i] <= RF_VALID[rs1[i * RF_WIDTH +: RF_WIDTH]];
					end
					
					else if(SType_valid[i])begin
					//	i-th instruction is Store Type
						rs2_dataValid[i] <= RF_VALID[rs2[i * RF_WIDTH +: RF_WIDTH]];
						rs1_dataValid[i] <= RF_VALID[rs1[i * RF_WIDTH +: RF_WIDTH]];
					end
				end
			end
			
			/*
			always @(*)begin
				for(j = i; j < IPC; j = j + 1)begin
					if(prev_rd_valid[j] == 1 && prev_rd_valid[i] == 1 && prev_rd_tag[j * TAG_WIDTH  +: TAG_WIDTH] == prev_rd_tag[i * TAG_WIDTH  +: TAG_WIDTH])
					   prev_rd_tag_write[prev_rd[j * RF_WIDTH +: RF_WIDTH] * TAG_WIDTH +: TAG_WIDTH] = prev_rd_tag[i * TAG_WIDTH +: TAG_WIDTH];
				end
			end
			*/
			
			
			always @(posedge clk)begin
				if(RType_valid[i] | IType_valid[i])begin//Only R, I, U and J type instructions have rd
					RF_VALID[rd[i * RF_WIDTH +: RF_WIDTH]] <= 0;//This will be made 1 once the corresponding data has been comitted by the write back unit
					RF_TAG[rd[i * RF_WIDTH +: RF_WIDTH]] <= destinationTag;
				end
			end
		end
	endgenerate
	
		  
endmodule
