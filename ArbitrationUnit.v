
//This is the only explicit control unit
module ArbitrationUnit (input clk,
                        input rst,
                        
                        input ongoingBroadcast,
                        input ROB_full,
                        input queueFull,
                        input queueEmpty,
                        input broadcastDataAvailable,
                        
                        output reg allowDecode = 1,
                        output reg allowBroadcast = 0,
                        
                        output reg IF_halt = 0,
                        output reg RF_halt = 0,
                        output reg DecodeROBPipeline_halt = 0,
                        output reg ROB_halt = 0,
                        output reg Dispatch_halt = 0);
                       
               always @(*)begin
                    if(broadcastDataAvailable | ongoingBroadcast)begin//Broadcast has the highest priority as even if ROB is full, it won't affect broadcast
                        allowDecode = 0;
                        allowBroadcast = 1;
                        
                        IF_halt = 1;
                        RF_halt = 1;
                        DecodeROBPipeline_halt = 1;
                        ROB_halt = 0;
                        Dispatch_halt = 1;//Halt any other dispatch till the ongoing broadcast is over
                    end
                    
                    else if(ROB_full)begin
                        allowDecode = 0;//However decoding can not be allowed
                        allowBroadcast = 1;//Even if ROB is full, broadcast can be absorbed
                        
                        IF_halt = 1;
                        RF_halt = 1;
                        DecodeROBPipeline_halt = 1;
                        ROB_halt = 0;//To allow broadcast
                        Dispatch_halt = 0;
                    end
                    
                    else if(queueFull)begin
                        allowDecode = 0;//However decoding can not be allowed
                        allowBroadcast = 1;//Even if ROB is full, broadcast can be absorbed
                        
                        IF_halt = 1;
                        RF_halt = 1;
                        DecodeROBPipeline_halt = 1;
                        ROB_halt = 0;//To allow broadcast
                        Dispatch_halt = 0;//Allow Broadcast
                    end
                    
                    else if(queueEmpty)begin
                        allowDecode = 1;//Allow decoding to fill queue
                        allowBroadcast = 0;//Broadcast is impossible with empty queue
                        
                        IF_halt = 0;
                        RF_halt = 0;
                        DecodeROBPipeline_halt = 0;
                        ROB_halt = 0;//To allow broadcast
                        Dispatch_halt = 0;//Allow Broadcast
                    end
                    
                    else begin
                        allowDecode = 1;//Allow decoding normally
                        allowBroadcast = 0;
                        
                        IF_halt = 0;
                        RF_halt = 0;
                        DecodeROBPipeline_halt = 0;
                        ROB_halt = 0;//To allow broadcast
                        Dispatch_halt = 0;//Allow Broadcast
                    end
               end
                        
endmodule