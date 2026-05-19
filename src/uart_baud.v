`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.05.2026 15:40:44
// Design Name: 
// Module Name: uart_baud
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


module uart_baud #(
    parameter CLK_VALUE = 100_000_000,
    parameter BAUD      = 9600
)(
    input  clk,
    input  rst,           // active low reset
    output reg os_tick    // 16x baud tick output
);
 
// how many clock cycles between each os_tick
parameter OS_COUNT = CLK_VALUE / (BAUD * 16);
 
integer os_cnt = 0;
 
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        os_cnt  <= 0;
        os_tick <= 0;
    end else begin
        if (os_cnt == OS_COUNT) begin
            os_tick <= 1'b1;   // pulse HIGH for one cycle
            os_cnt  <= 0;
        end else begin
            os_cnt  <= os_cnt + 1;
            os_tick <= 1'b0;
        end
    end
end
 
endmodule
