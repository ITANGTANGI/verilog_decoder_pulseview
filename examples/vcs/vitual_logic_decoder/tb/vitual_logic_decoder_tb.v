//*****************************************************************************
//COPYRIGHT(c) South China University Of Techonology
//
//Module name  :vitual_logic_decoder_tb
//File name    :vitual_logic_decoder_tb.v
//
//Author       :TANG
//Email        :tangziming@whut.edu.cn
//Date         :2022/10/15

//Version      :1.0
/*Abstract

*/
//*****************************************************************************

`timescale  1ns / 1ps

module vitual_logic_decoder_tb;

// vitual_logic_analyzer Parameters
parameter PERIOD         = 10        ;
parameter SAMP_CLK_FREQ  = 100_000_000;
parameter SAMP_CHANNELS  = 8         ;

// vitual_logic_analyzer Inputs
reg   clk_i                                = 0 ;
reg   [SAMP_CHANNELS-1 : 0]  data_i        = 0 ;

// vitual_logic_analyzer Outputs

initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, vitual_logic_decoder_tb.clk_i, vitual_logic_decoder_tb.data_i);
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

always@(posedge clk_i)begin
    data_i <= data_i + 8'd1;
end

//operations
initial
begin
    #6000
    $finish;
end

endmodule
