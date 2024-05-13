`timescale 1ns / 1ps


module AC_UART_RX_tb
#(
    parameter   Input_Clock = 100_000_000, // multiple of 1MHz
    parameter   Baud_Rate = 115200,   // 9600-5MHz
    parameter   Bits = 8,             // 5-32
    parameter   Buffer_Size = 128,    // powers of two 16/32/64/128/...
    parameter   word_delay_us = 10,   // delay between two words
    localparam  DC_Width = $clog2(Buffer_Size)+1 // data count width
)
(

);

localparam real BIT_PERIOD_NS = (1.0 / 115200) * 1e9; // Period in nanoseconds


reg             clk = 0;
always begin #5 clk = !clk; end

reg             hw_resetn =0;
reg             sof_resetn =0;

wire [Bits-1:0] fifo_dout;
reg             fifo_read =0;

reg             rx = 1;

initial begin
    #200;
    hw_resetn <= 1;
    sof_resetn <= 1;
    
    #80000;
    for(int i=0; i<3; i++) begin
        simulate_rx(i+7);
    end
    
    #10000;
    for(int i=0; i<3; i++) begin
        readData();
    end
    
    
    
end


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
    .fifo_data_count(),
    
    .uart_busy(),
    
    .rx

 );
 
task simulate_rx;
    input [Bits-1:0] word;
    begin
        // start bit
        rx <= 0;
        #BIT_PERIOD_NS;
        
        // data
        for(int i=0; i<Bits;i++) begin
            rx <= word[i];
            #BIT_PERIOD_NS;
        end
        
        // stop bit
        rx <= 1;
        #BIT_PERIOD_NS;
        #BIT_PERIOD_NS;
    end
endtask

task readData;
    begin
        fifo_read <= 1;
        #3700;
        fifo_read <= 0;
        #5200;
    end
endtask


endmodule
