`timescale 1ns / 1ps


// for detailed explanation go to:
// Language Templates (bulb) -> verilog -> xpm -> xpm -> xpm_fifo -> sync

module xFIFO
#(
    parameter   Depth = 128, // must be powers of two 16/32/64/128/...
    parameter   Write_Width = 8,
    parameter   Read_Width = 8,
    
    parameter   Latency = 1,
    parameter   Empty_Thresh = 10,
    parameter   Full_Thresh = 10,
    
    localparam  DC_Width = $clog2(Depth)+1
    
)
(
    input                   clk,
    input                   srst,

    input [Write_Width-1:0] din,
    input                   wr_en,
    output                  full,

    output [Read_Width-1:0] dout,
    input                   rd_en,
    output                  empty,
    
    output [DC_Width-1:0]   wr_data_count,
    output [DC_Width-1:0]   rd_data_count
);



xpm_fifo_sync #(
    .CASCADE_HEIGHT(0),        
    .DOUT_RESET_VALUE("0"),    
    .ECC_MODE("no_ecc"),       
    .FIFO_MEMORY_TYPE("auto"), 
    .FIFO_READ_LATENCY(Latency),     
    .FIFO_WRITE_DEPTH(Depth),  
    .FULL_RESET_VALUE(0),      
    .PROG_EMPTY_THRESH(Empty_Thresh),    
    .PROG_FULL_THRESH(Full_Thresh),     
    .RD_DATA_COUNT_WIDTH(DC_Width),  
    .READ_DATA_WIDTH(Read_Width),      
    .READ_MODE("std"),         
    .SIM_ASSERT_CHK(1),        
    // 0001 0111 001 0111 flags:
    // overflow, prog_full, wr_data_count, wr_ack flag, 
    // underflow, prog_empty, rd_data_count, data_valid
    .USE_ADV_FEATURES("1717"), 
    .WAKEUP_TIME(0),           
    .WRITE_DATA_WIDTH(Write_Width),     
    .WR_DATA_COUNT_WIDTH(DC_Width)  
)
xpm_fifo_sync_inst (
    .wr_clk(clk),   
    .rst(srst),             // synchronous active high    

//----------------WRITE-------------//
    .din, 
    .wr_en,
    .full, 
    .wr_data_count,

    .wr_ack(),              // write request acknowledged
    .overflow(),            // previous wren rejected because full 

//----------------READ--------------//
    .rd_en, 
    .dout,                  
    .empty,    
    .rd_data_count,

    .data_valid(),          // dout is valid 
    .underflow(),           // previous rd_en rejected because empty



//--------------UNUSED-------------//    
    // not used
    .almost_empty(), 
    .almost_full(), 
    .dbiterr(),   
    .rd_rst_busy(),
    .wr_rst_busy(),
    .injectdbiterr(),
    .injectsbiterr(),
    .sbiterr(),  
    .sleep(),
    // need to disable on USE_ADV_FEATURES
    .prog_empty(), 
    .prog_full()

);
   
endmodule
