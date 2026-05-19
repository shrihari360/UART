`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.05.2026 15:42:38
// Design Name: 
// Module Name: uart_tx
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

module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst,
    input                   os_tick,
    input                   start,
    input  [DATA_WIDTH-1:0] tx_data,
    output reg              tx,
    output                  tx_done,
    output                  tx_busy
);

parameter FRAME_WIDTH = DATA_WIDTH + 2;

parameter idle  = 2'd0;
parameter send  = 2'd1;
parameter check = 2'd2;

reg [1:0] state = idle;

reg [FRAME_WIDTH-1:0] txData    = 0;
integer               bitIndex  = 0;
reg [3:0]             tick_cnt  = 0;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        tx       <= 1'b1;
        txData   <= 0;
        bitIndex <= 0;
        tick_cnt <= 0;
        state    <= idle;
    end else begin
        case (state)

            idle : begin
                tx       <= 1'b1;
                txData   <= 0;
                bitIndex <= 0;
                tick_cnt <= 0;
                if (start == 1'b1) begin
                    txData <= {1'b1, tx_data, 1'b0};
                    state  <= send;
                end
            end

            send : begin
                tx    <= txData[bitIndex];
                state <= check;
            end

            check : begin
                if (os_tick) begin
                    if (tick_cnt == 15) begin
                        tick_cnt <= 0;
                        if (bitIndex == FRAME_WIDTH-1) begin
                            state    <= idle;
                            bitIndex <= 0;
                        end else begin
                            bitIndex <= bitIndex + 1;
                            state    <= send;
                        end
                    end else begin
                        tick_cnt <= tick_cnt + 1;
                    end
                end
            end

            default: state <= idle;
        endcase
    end
end

assign tx_done = (state == idle) ? 1'b1 : 1'b0;
assign tx_busy = (state != idle) ? 1'b1 : 1'b0;

endmodule
