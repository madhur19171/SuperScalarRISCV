
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
                        
                        output IF_halt,
                        output RF_halt,
                        output DecodeROBPipeline_halt,
                        output ROB_halt,
                        output Dispatch_halt);
                       
                        
                        
endmodule