`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.05.2026 15:44:06
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst,
    input                   os_tick,
    input                   rx,
    output [DATA_WIDTH-1:0] rx_data,
    output                  rx_ready,
    output                  rx_busy
);

parameter FRAME_WIDTH = DATA_WIDTH + 2;
parameter CENTER      = 8;

parameter ridle  = 2'd0;
parameter rstart = 2'd1;
parameter recv   = 2'd2;
parameter rdone  = 2'd3;

reg [1:0] rstate = ridle;

reg rx_ff1  = 1'b1;
reg rx_sync = 1'b1;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        rx_ff1  <= 1'b1;
        rx_sync <= 1'b1;
    end else begin
        rx_ff1  <= rx;
        rx_sync <= rx_ff1;
    end
end

integer               rindex     = 0;
reg [3:0]             sample_cnt = 0;
reg [FRAME_WIDTH-1:0] rxdata     = 0;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        rxdata     <= 0;
        rindex     <= 0;
        sample_cnt <= 0;
        rstate     <= ridle;
    end else begin
        case (rstate)

            ridle : begin
                rindex <= 0;
                if (rx_sync == 1'b0) begin
                    sample_cnt <= 0;
                    rstate     <= rstart;
                end
            end

            rstart : begin
                if (os_tick) begin
                    if (sample_cnt == CENTER) begin
                        sample_cnt <= 0;
                        if (rx_sync == 1'b0)
                            rstate <= recv;
                        else
                            rstate <= ridle;
                    end else begin
                        sample_cnt <= sample_cnt + 1;
                    end
                end
            end

            recv : begin
                if (os_tick) begin
                    if (sample_cnt == CENTER) begin
                        rxdata <= {rx_sync, rxdata[FRAME_WIDTH-1:1]};
                        rindex <= rindex + 1;
                    end
                    if (sample_cnt == 15) begin
                        sample_cnt <= 0;
                        if (rindex == FRAME_WIDTH - 1)
                            rstate <= rdone;
                    end else begin
                        sample_cnt <= sample_cnt + 1;
                    end
                end
            end

            rdone : begin
                rstate <= ridle;
                rindex <= 0;
                if (rxdata[FRAME_WIDTH-1] != 1'b1)
                    rxdata <= 0;
            end

            default : rstate <= ridle;
        endcase
    end
end

assign rx_data  = rxdata[FRAME_WIDTH-2:1];
assign rx_ready = (rstate == ridle) ? 1'b1 : 1'b0;
assign rx_busy  = (rstate != ridle) ? 1'b1 : 1'b0;

endmodule
