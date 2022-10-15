//*****************************************************************************
//COPYRIGHT(c) South China University Of Techonology
//
//Module name  :uart_send
//File name    :uart_send.v
//
//Author       :TANG
//Email        :tangziming@whut.edu.cn
//Data         :2022.10.15
//Version      :1.0
/*Abstract

*/
/*Modify
    1.0:create the file
*/
//*****************************************************************************
module uart_send
#(
	parameter  CLK_FREQ = 50000000,
	parameter  UART_BPS = 9600
)
(
    input clk_i,                //global clock input
    input rst_n_i,              //global async reset input, active low
    
    input uart_en_i,            //uart send enable pulse signal input
    input [7 : 0] uart_din_i,   //uart send data input, sync with uart_en_i
	
	output uart_tx_busy_o,      //uart send busy flag output
    output uart_txd_o           //uart send physical output
);
localparam BPS_CNT  = CLK_FREQ/UART_BPS;

//uart_en_i rise edge detec
reg uart_en_i_d0; 
reg uart_en_i_d1;
wire en_flag;
always @(posedge clk_i or negedge rst_n_i) begin         
    if (!rst_n_i) begin
        uart_en_i_d0 <= 1'b0;                                  
        uart_en_i_d1 <= 1'b0;
    end                                                      
    else begin                                               
        uart_en_i_d0 <= uart_en_i;                               
        uart_en_i_d1 <= uart_en_i_d0;                            
    end
end
assign en_flag = (~uart_en_i_d1) & uart_en_i_d0;

//uart send start and stop
reg tx_flag;
reg [7 : 0] tx_data;
reg [3 : 0] tx_cnt;
reg [15 : 0] clk_cnt;
always @(posedge clk_i or negedge rst_n_i) begin         
    if (!rst_n_i) begin                                  
        tx_flag <= 1'b0;
        tx_data <= 8'd0;
    end 
    else if (en_flag) begin                
            tx_flag <= 1'b1;
            tx_data <= uart_din_i;
        end
        else 
        if ((tx_cnt == 4'd9)&&(clk_cnt == BPS_CNT - 1)) begin
            tx_flag <= 1'b0;
            tx_data <= 8'd0;
        end
        else begin
            tx_flag <= tx_flag;
            tx_data <= tx_data;
        end
end
assign uart_tx_busy_o = uart_en_i| uart_en_i_d0 | tx_flag;

//uart bps and tx bit number counter
always @(posedge clk_i or negedge rst_n_i) begin         
    if (!rst_n_i) begin                             
        clk_cnt <= 16'd0;                                  
        tx_cnt  <= 4'd0;
    end                                                      
    else if (tx_flag) begin
        if (clk_cnt < BPS_CNT - 1) begin
            clk_cnt <= clk_cnt + 1'b1;
            tx_cnt  <= tx_cnt;
        end
        else begin
            clk_cnt <= 16'd0;
            tx_cnt  <= tx_cnt + 1'b1;
        end
    end
    else begin
        clk_cnt <= 16'd0;
        tx_cnt  <= 4'd0;
    end
end

//put data bits to output port
reg uart_txd_o_r;
always @(posedge clk_i or negedge rst_n_i)begin        
    if (!rst_n_i)
        uart_txd_o_r <= 1'b1;        
    else if (tx_flag)
        case(tx_cnt)
            4'd0: uart_txd_o_r <= 1'b0;         //start bit
            4'd1: uart_txd_o_r <= tx_data[0];
            4'd2: uart_txd_o_r <= tx_data[1];
            4'd3: uart_txd_o_r <= tx_data[2];
            4'd4: uart_txd_o_r <= tx_data[3];
            4'd5: uart_txd_o_r <= tx_data[4];
            4'd6: uart_txd_o_r <= tx_data[5];
            4'd7: uart_txd_o_r <= tx_data[6];
            4'd8: uart_txd_o_r <= tx_data[7];
            4'd9: uart_txd_o_r <= 1'b1;         //stop bit
            default: ;
        endcase
    else 
        uart_txd_o_r <= 1'b1;
end
assign uart_txd_o = uart_txd_o_r;

endmodule
