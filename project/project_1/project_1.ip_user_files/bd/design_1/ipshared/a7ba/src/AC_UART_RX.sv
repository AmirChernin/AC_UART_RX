`timescale 1ns / 1ps

module AC_UART_RX
#(
    parameter   Input_Clock = 100_000_000, // multiple of 1MHz
    parameter   Baud_Rate = 115200,   // 9600-5MHz
    parameter   Bits = 8,             // 5-32
    parameter   Buffer_Size = 128,    // powers of two 16/32/64/128/...
    localparam  DC_Width = $clog2(Buffer_Size)+1 // data count width
)
(
    input                   clk,
    input                   hw_resetn,
    input                   sof_resetn,
    
    output [Bits-1:0]       fifo_dout,
    input                   fifo_read, // pulse at least one clock cycle
    
    output                  fifo_full,
    output                  fifo_empty,
    output [DC_Width-1:0]   fifo_data_count,
    
    output reg              uart_busy=0,
    
    input                   rx

 );
 
localparam BR_divider_max = Input_Clock / Baud_Rate - 1;
localparam fifo_latency = 4; // to avoid timing issues 
 
reg                 system_resetn = 0;

//----------------UART----------------//
integer             BR_divider = 0;    
reg [Bits-1:0]      current_uart_data=0;
reg [10:0]          index =0;  // lsb fist

//----------------FIFO----------------//
reg [Bits-1:0]      fifo_din=0;
reg                 fifo_wr_en =0;

reg                 fifo_read_d=0;
reg                 fifo_rd_en =0;
 
typedef enum logic [2:0] {
    IDLE,
    START,
    DATA,
    STOP
} rx_state_t;
rx_state_t rx_state = IDLE; 

always_comb begin
    system_resetn <= hw_resetn && sof_resetn;
end

always @(posedge clk or negedge system_resetn) begin
    if(!system_resetn) begin
        uart_busy <= 1;
        BR_divider <= 0;
        current_uart_data <= 0;
        index <= 0;
        fifo_din <= 0;
        fifo_wr_en <= 0;
        fifo_read_d <= 0;
        fifo_rd_en <= 0;
        rx_state <= IDLE;
    end else begin
        fifo_wr_en <= 0;
        fifo_rd_en <= 0;
        fifo_read_d <= fifo_read;
        
        if(!fifo_read_d && fifo_read && !fifo_empty) fifo_rd_en <= 1;
        
        BR_divider <= BR_divider+1;
        if(BR_divider == BR_divider_max) BR_divider <= 0;
    
        case (rx_state)
            IDLE: begin
                uart_busy <= 0;
                if(!rx) begin 
                    BR_divider <= 0;
                    rx_state <= START;
                    uart_busy <= 1;
                end
            end 
            START: begin
                if(BR_divider == BR_divider_max / 2 && rx) begin //line should be low
                    rx_state <= IDLE;
                end
                if(BR_divider == BR_divider_max) begin
                    rx_state <= DATA;
                    current_uart_data <= 0;
                end
            end
            DATA: begin
                if(BR_divider == BR_divider_max / 2) begin
                    current_uart_data[index] = rx;
                    index <= index+1;
                end
                if(BR_divider == BR_divider_max && index == Bits) begin
                    index <= 0;
                    rx_state <= STOP;
                end
            end
            STOP: begin
                if(BR_divider == BR_divider_max /2) begin
                    if(rx && !fifo_full) begin // line should be high
                        fifo_wr_en <= 1;
                        fifo_din <= current_uart_data;
                    end
                    rx_state <= IDLE;
                end
            end
        
        endcase
    end

end
 
xFIFO 
#(
    .Depth(Buffer_Size),
    .Write_Width(Bits),
    .Read_Width(Bits),
    .Latency(fifo_latency)
)
xFIFO 
(
    .clk,
    .srst(!system_resetn),
    
    .din(fifo_din),
    .wr_en(fifo_wr_en),
    .full(fifo_full),
    
    .dout(fifo_dout),
    .rd_en(fifo_rd_en),
    .empty(fifo_empty),
    
    .wr_data_count(),
    .rd_data_count(fifo_data_count)
); 


AC_UART_RX_ILA AC_UART_RX_ILA (
    .clk,
    
    
    .probe0({
//----------INPUTS-----------//	   
        hw_resetn,
        sof_resetn,
        
        fifo_dout,
        fifo_read, 
        
        fifo_full,
        fifo_empty,
        fifo_data_count,
        
        uart_busy,
        rx,
       
//----------REGISTERS-----------//	   
        current_uart_data,
        index,
        fifo_din,
        fifo_wr_en,
        fifo_read_d,
        fifo_rd_en,
        rx_state,
        BR_divider
	}) 
);


 
endmodule
