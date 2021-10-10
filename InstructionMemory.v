module InstructionMemory #(parameter ADDRESS_WIDTH = 10,
			    parameter DATA_WIDTH = 32,
			    parameter IPC = 1)//IPC:Instructions returned by the IM for every fetch.
			    
			   (input clk,
		  	    input rst,
		  	    input ce,
		  	    input [ADDRESS_WIDTH - 1 : 0] address,
		  	    output [DATA_WIDTH - 1 : 0] data,//Data Bus is as wide as the number of instructions issued
		  	    output dataValid,
		  	    
		  	    input we,
		  	    input [5 : 0] w_address,
		  	    input [31 : 0] w_data
		  	   );
		  	    
		  	    
	reg [DATA_WIDTH - 1 : 0] IM [0 : (2 ** ADDRESS_WIDTH) - 1];//Instruction Memory RAM(only to store data that will be assigned to partitioned ram)
								     //This will not be synthesized


	reg [DATA_WIDTH - 1 : 0] readData = 0;
	reg dataValid_reg = 0;
	
	integer i = 0, j = 0;
	initial begin
		//Initialize all IM to 0
		for(i = 0; i < 2 ** ADDRESS_WIDTH; i = i + 1)begin
		  IM[i] = 0;
		end
		$readmemb("program.mem", IM);//Read program from the file and store in IM
	end
	
	
	always @(posedge clk, posedge rst)begin
		if(rst)
			readData <= 0;
		else if(ce)begin
			readData <= IM[address];
	   end
	end

    always @(posedge clk)begin
        if(we)
            IM[w_address] <= w_data;
    end
	
	//Data valid becomes 1 on every successful read
	always @(posedge clk, posedge rst)begin
		dataValid_reg <= 0;
		if(rst)
			dataValid_reg <= 0;
		else if(ce)
			dataValid_reg <= 1;
	end
	
	assign data = readData;
	assign dataValid = dataValid_reg;
	
endmodule
