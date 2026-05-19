`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.05.2026 15:45:32
// Design Name: 
// Module Name: uart_top
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

module uart_top #(
    parameter DATA_WIDTH = 8,
    parameter CLK_VALUE  = 100_000_000,
    parameter BAUD       = 9600
)(
    input                   clk,
    input                   rst,
    input                   start,
    input  [DATA_WIDTH-1:0] tx_data,
    output                  tx,
    output                  tx_done,
    output                  tx_busy,
    input                   rx,
    output [DATA_WIDTH-1:0] rx_data,
    output                  rx_ready,
    output                  rx_busy
);

wire os_tick;

uart_baud #(
    .CLK_VALUE (CLK_VALUE),
    .BAUD      (BAUD)
) baud_inst (
    .clk     (clk),
    .rst     (rst),
    .os_tick (os_tick)
);

uart_tx #(
    .DATA_WIDTH (DATA_WIDTH)
) tx_inst (
    .clk     (clk),
    .rst     (rst),
    .os_tick (os_tick),
    .start   (start),
    .tx_data (tx_data),
    .tx      (tx),
    .tx_done (tx_done),
    .tx_busy (tx_busy)
);

uart_rx #(
    .DATA_WIDTH (DATA_WIDTH)
) rx_inst (
    .clk      (clk),
    .rst      (rst),
    .os_tick  (os_tick),
    .rx       (rx),
    .rx_data  (rx_data),
    .rx_ready (rx_ready),
    .rx_busy  (rx_busy)
);

endmodule
