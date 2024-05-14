`timescale 1ns / 1ps

module Top
#(
    parameter   Input_Clock = 100_000_000, // multiple of 1MHz
    parameter   Baud_Rate = 115200,   // 9600-5MHz
    parameter   Bits = 8,             // 5-32
    parameter   Buffer_Size = 128,    // powers of two 16/32/64/128/...
    localparam  DC_Width = $clog2(Buffer_Size)+1 // data count width
)
(
    input sys_clock,
    input rx
);

wire clk;

clk_wiz clk_wiz
(
    .clk_out1(clk),     
    .clk_in1(sys_clock)
);     

wire                hw_resetn;
wire                sof_resetn;
wire                fifo_read;

wire [DC_Width-1:0] fifo_data_count;
wire [Bits-1:0]     fifo_dout;

vio_0 vio_0 
(
  .clk,                
  .probe_in0(fifo_data_count),    
  .probe_in1(fifo_dout),    
  
  .probe_out0(hw_resetn), 
  .probe_out1(sof_resetn),
  .probe_out2(fifo_read)  
);



AC_UART_RX
#(
    .Input_Clock(Input_Clock),
    .Baud_Rate(Baud_Rate),
    .Bits(Bits),
    .Buffer_Size(Buffer_Size)
)
AC_UART_RX
(
    .clk,
    .hw_resetn,
    .sof_resetn,
    
    .fifo_dout,
    .fifo_read, // pulse at least one clock cycle
    
    .fifo_full(),
    .fifo_empty(),
    .fifo_data_count,
    
    .uart_busy(),
    
    .rx

 );




endmodule
