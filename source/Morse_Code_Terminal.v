`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2021 10:39:17 AM
// Design Name: 
// Module Name: Morse_Code_Terminal
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Morse_Code_Terminal(
    input b, reset_n, read, clk,
    output DP,
    output [6:0] SEG,
    output [7:0] AN
    );
    
    wire bDeb, readDeb, dot, dash, lg, wg, wg_delayed, full, tx;
    wire [4:0] symbol;
    wire [2:0] symbol_count;
    wire [7:0] ROMaddress, ROMdata;
 
    
    button B (
        .clk(clk),
        .reset_n(reset_n),
        .noisy(b),
        .debounced(bDeb)
    );
    
    button Read (
        .clk(clk),
        .reset_n(reset_n),
        .noisy(read),
        .p_edge(readDeb)
    );
    
    morse_decoder_2 #(.TIMER_FINAL_VALUE(10_999_999)) MD (
        .clk(clk),
        .reset_n(reset_n),
        .b(bDeb),
        .dot(dot),
        .dash(dash),
        .lg(lg),
        .wg(wg)
    );
    
    Shift_Register_nbit #(.N(5)) Shift (
        .clk(clk),
        .reset_n(~(lg | wg) & reset_n),
        .SI(dash),
        .shift(dot ^ dash),
        .Q(symbol)
    );
    
    udl_counter #(.BITS(3)) Counter (
        .clk(clk),
        .reset_n(~(lg | wg) & reset_n),
        .enable(dot ^ dash),
        .up(1'b1),
        .load(symbol_count == 3'd5),
        .D('b0),
        .Q(symbol_count)
    );
    
    D_FF FF0 (
        .clk(clk),
        .reset_n(reset_n),
        .D(wg),
        .Q(wg_delayed)
    );
    
    mux_2x1_nbit #(.N(8)) MUX (
        .w0({symbol_count,symbol}),
        .w1(8'b1110_0000),
        .s(wg),
        .f(ROMaddress)
    );
    
    synch_rom ROM (
        .clk(clk),
        .addr(ROMaddress),
        .data(ROMdata)
    );
    
    uart #(.DBIT(8),.SB_TICK(16)) UART (
        .clk(clk),
        .reset_n(reset_n),
        .rd_uart('b0),
        .w_data(ROMdata),
        .wr_uart(~full & (lg | wg | wg_delayed)),
        .tx(tx),
        .TIMER_FINAL_VALUE(10'b1010001010)
    );
        
    sseg_driver Display (
        .I7(6'b0),
        .I6(6'b0),
        .I5(6'b0),
        .I4({symbol_count == 3'd5,3'b000,symbol[4],1'b0}),
        .I3({symbol_count >=3'd4,3'b000,symbol[3],1'b0}),
        .I2({symbol_count >=3'd3,3'b000,symbol[2],1'b0}),
        .I1({symbol_count >=3'd2,3'b000,symbol[1],1'b0}),
        .I0({symbol_count >=3'd1,3'b000,symbol[0],1'b0}),
        .CLK100MHZ(clk),
        .SSEG(SEG),
        .AN(AN),
        .DP(DP)
    );
endmodule
