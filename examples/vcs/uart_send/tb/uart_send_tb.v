//*****************************************************************************
//COPYRIGHT(c) South China University Of Techonology
//
//Module name  :uart_send_tb
//File name    :uart_send_tb.v
//
//Author       :TANG
//Email        :tangziming@whut.edu.cn
//Date         :2022/10/15

//Version      :1.0
/*Abstract

*/
//*****************************************************************************

`timescale  1ns / 1ps

module uart_send_tb;

// uart_send Parameters
parameter PERIOD    = 20      ;
parameter CLK_FREQ  = 50000000;
parameter UART_BPS  = 115200  ;

// uart_send Inputs
reg   clk_i                                = 0 ;
reg   rst_n_i                              = 0 ;
reg   uart_en_i                            = 0 ;
reg   [7 : 0]  uart_din_i                  = 0 ;

// uart_send Outputs
wire  uart_tx_busy_o                       ;
wire  uart_txd_o                           ;

//dump vcd file
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0,uart_send_tb.uart_en_i,
                uart_send_tb.uart_tx_busy_o,
                uart_send_tb.uart_txd_o
                );
end

//dump fsbl
initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars(0);
end

//Clock generate
initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

//Reset generate
initial
begin
    #(PERIOD*2) rst_n_i  =  1;
end

//operations
reg [7:0] send_byte_cnt = 0;
always@(posedge clk_i or negedge rst_n_i)begin
    if(!rst_n_i)begin
        uart_en_i <= 1'b0;
        uart_din_i <= 8'h00;
    end
    else if(uart_tx_busy_o == 1'b0)begin
        case(send_byte_cnt)
            0:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "H";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            1:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "e";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            2:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "l";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            3:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "l";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            4:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "o";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            5:begin
                uart_en_i <= 1'b1;
                uart_din_i <= " ";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            6:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "W";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            7:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "o";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            8:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "r";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            9:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "l";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            10:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "d";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            11:begin
                uart_en_i <= 1'b1;
                uart_din_i <= "!";
                send_byte_cnt <= send_byte_cnt + 8'd1;
            end
            12:begin
                $finish;
            end

        endcase
    end
    else begin
        uart_en_i <= 1'b0;
    end
end

//Test top module
uart_send 
#(
    .CLK_FREQ ( CLK_FREQ ),
    .UART_BPS ( UART_BPS )
)
u_uart_send
(
    .clk_i                   ( clk_i                   ),
    .rst_n_i                 ( rst_n_i                 ),
    .uart_en_i               ( uart_en_i               ),
    .uart_din_i              ( uart_din_i      [7 : 0] ),

    .uart_tx_busy_o          ( uart_tx_busy_o          ),
    .uart_txd_o              ( uart_txd_o              )
);

endmodule
