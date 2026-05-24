`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.05.2026 10:11:24
// Design Name: 
// Module Name: uart_tb
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


module uart_tb;

parameter data_width = 8;

reg sys_clk;
reg sys_rst;
reg xmitH;
reg [data_width-1:0] xmit_dataH;
reg uart_rec_datah;

wire dut_xmit_doneH;
wire dut_xmit_active;
wire dut_uart_xmit_datah;
wire dut_rec_readyh;
wire dut_rec_busyh;
wire [data_width-1:0] dut_rec_datah;

wire ref_xmit_doneH;
wire ref_xmit_active;
wire ref_uart_xmit_datah;
wire ref_rec_readyh;
wire ref_rec_busyh;
wire [data_width-1:0] ref_rec_datah;
wire ref_uart_clk;

integer pass_count;
integer fail_count;
integer test_count;

top_tx #(
    .d    (data_width),
    .BAUD (9600)
) dut (
    .sys_clk          (sys_clk),
    .sys_rst          (sys_rst),
    .xmitH            (xmitH),
    .xmit_dataH       (xmit_dataH),
    .uart_REC_dataH   (uart_rec_datah),
    .uart_XMIT_dataH  (dut_uart_xmit_datah),
    .xmit_done        (dut_xmit_doneH),
    .xmit_active      (dut_xmit_active),
    .rec_readyH       (dut_rec_readyh),
    .rec_dataH        (dut_rec_datah),
    .rec_busy         (dut_rec_busyh)
);

uart_reference #(
    .clk_value  (100_000_000),
    .baud       (9600),
    .data_width (data_width)
) ref (
    .sys_clk         (sys_clk),
    .sys_rst_l       (sys_rst),
    .xmitH           (xmitH),
    .xmit_dataH      (xmit_dataH),
    .uart_REC_dataH  (uart_rec_datah),
    .uart_XMIT_dataH (ref_uart_xmit_datah),
    .xmit_doneH      (ref_xmit_doneH),
    .xmit_active     (ref_xmit_active),
    .rec_readyH      (ref_rec_readyh),
    .rec_busyH       (ref_rec_busyh),
    .rec_dataH       (ref_rec_datah),
    .uart_clk_out    (ref_uart_clk)
);

initial begin
    sys_clk = 0;
    forever #5 sys_clk = ~sys_clk;
end

initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);
end

function compare_tx;
    input dut_done, dut_active, dut_serial;
    input ref_done, ref_active, ref_serial;
    begin
        compare_tx = (dut_done   === ref_done)   &&
                     (dut_active === ref_active)  &&
                     (dut_serial === ref_serial);
    end
endfunction

function compare_rx;
    input dut_ready, dut_busy;
    input [data_width-1:0] dut_data;
    input ref_ready, ref_busy;
    input [data_width-1:0] ref_data;
    begin
        compare_rx = (dut_ready === ref_ready) &&
                     (dut_busy  === ref_busy)  &&
                     (dut_data  === ref_data);
    end
endfunction

task display_tx_mismatch;
    begin
        $display("DUT TX : done=%b active=%b serial=%b",
                  dut_xmit_doneH, dut_xmit_active, dut_uart_xmit_datah);
        $display("REF TX : done=%b active=%b serial=%b",
                  ref_xmit_doneH, ref_xmit_active, ref_uart_xmit_datah);
    end
endtask

task display_rx_mismatch;
    begin
        $display("DUT RX : ready=%b busy=%b data=0x%02X",
                  dut_rec_readyh, dut_rec_busyh, dut_rec_datah);
        $display("REF RX : ready=%b busy=%b data=0x%02X",
                  ref_rec_readyh, ref_rec_busyh, ref_rec_datah);
    end
endtask

task wait_tx_complete;
    begin
        wait (dut_xmit_active == 0);
        wait (ref_xmit_active == 0);
        repeat(4) @(posedge ref_uart_clk);
    end
endtask

task wait_rx_ready;
    integer timeout;
    begin
        timeout = 0;
        while (dut_rec_readyh != 1'b1) begin
            @(posedge sys_clk);
            timeout = timeout + 1;
            if (timeout > 200_000) begin
                $display("ERROR: DUT RX timeout");
                disable wait_rx_ready;
            end
        end
        timeout = 0;
        while (ref_rec_readyh != 1'b1) begin
            @(posedge ref_uart_clk);
            timeout = timeout + 1;
            if (timeout > 5000) begin
                $display("ERROR: REF RX timeout");
                disable wait_rx_ready;
            end
        end
    end
endtask

task apply_test_tx;
    input [data_width-1:0] data;
    input [200:1] test_name;
    begin
        wait (dut_xmit_active == 0);
        wait (ref_xmit_active == 0);

        @(posedge ref_uart_clk);
        xmit_dataH = data;
        xmitH      = 1'b1;

        @(posedge ref_uart_clk);
        xmitH = 1'b0;

        wait_tx_complete;

        test_count = test_count + 1;

        if (compare_tx(
                dut_xmit_doneH, dut_xmit_active, dut_uart_xmit_datah,
                ref_xmit_doneH, ref_xmit_active, ref_uart_xmit_datah))
        begin
            $display("[PASS] %s data=0x%02X", test_name, data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s data=0x%02X", test_name, data);
            display_tx_mismatch;
            fail_count = fail_count + 1;
        end
    end
endtask

task send_frame;
    input [data_width-1:0] data;
    integer i;
    reg [data_width-1:0] temp;
    begin
        temp = data;

        uart_rec_datah = 1'b0;
        repeat(10416) @(posedge sys_clk);

        for (i = 0; i < data_width; i = i + 1) begin
            uart_rec_datah = temp[0];
            temp = temp >> 1;
            repeat(10416) @(posedge sys_clk);
        end

        uart_rec_datah = 1'b1;
        repeat(10416) @(posedge sys_clk);
    end
endtask

task apply_test_rx;
    input [data_width-1:0] data;
    input [200:1] test_name;
    begin
        send_frame(data);

        wait_rx_ready;

        repeat(4) @(posedge ref_uart_clk);

        test_count = test_count + 1;

        if (compare_rx(
                dut_rec_readyh, dut_rec_busyh, dut_rec_datah,
                ref_rec_readyh, ref_rec_busyh, ref_rec_datah))
        begin
            $display("[PASS] %s data=0x%02X", test_name, data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s data=0x%02X", test_name, data);
            display_rx_mismatch;
            fail_count = fail_count + 1;
        end
    end
endtask

task test_transmitter;
    begin
        apply_test_tx(8'hCD, "TX Normal");
        apply_test_tx(8'h00, "TX All Zeros");
        apply_test_tx(8'hFF, "TX All Ones");
        apply_test_tx(8'h77, "TX Pattern 0x77");
        apply_test_tx(8'h10, "TX Pattern 0x10");

        test_count = test_count + 1;
        if (dut_uart_xmit_datah == 1'b1) begin
            $display("[PASS] TX Idle Line = 1");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] TX Idle Line != 1");
            fail_count = fail_count + 1;
        end

        xmitH = 0;
        xmit_dataH = 8'hDE;
        repeat(10) @(posedge ref_uart_clk);
        test_count = test_count + 1;
        if (dut_xmit_active == 0) begin
            $display("[PASS] xmitH=0 does not start TX");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] xmitH=0 started TX");
            fail_count = fail_count + 1;
        end

        wait (dut_xmit_active == 0);
        @(posedge ref_uart_clk);

        xmitH = 1;
        xmit_dataH = 8'hAA;
        @(posedge ref_uart_clk);
        xmitH = 0;

        repeat(50) @(posedge ref_uart_clk);
        xmit_dataH = 8'hFF;

        wait_tx_complete;

        test_count = test_count + 1;
        if (dut_uart_xmit_datah == ref_uart_xmit_datah) begin
            $display("[PASS] Mid TX data change ignored");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Mid TX data change affected transfer");
            display_tx_mismatch;
            fail_count = fail_count + 1;
        end
    end
endtask

task test_receiver;
    integer b;
    reg [7:0] fdata;
    begin
        apply_test_rx(8'hCD, "RX Normal 0xCD");
        apply_test_rx(8'h00, "RX All Zeros");
        apply_test_rx(8'hFF, "RX All Ones");
        apply_test_rx(8'hA5, "RX Pattern 0xA5");

        uart_rec_datah = 1'b1;
        repeat(200) @(posedge sys_clk);
        test_count = test_count + 1;
        if (dut_rec_readyh == 1'b1 && dut_rec_busyh == 1'b0) begin
            $display("[PASS] RX Idle State");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] RX Idle State");
            display_rx_mismatch;
            fail_count = fail_count + 1;
        end

        fdata = 8'h55;
        uart_rec_datah = 1'b0;
        repeat(10416) @(posedge sys_clk);

        for (b = 0; b < data_width; b = b + 1) begin
            uart_rec_datah = fdata[0];
            fdata = fdata >> 1;
            repeat(10416) @(posedge sys_clk);
        end

        uart_rec_datah = 1'b0;
        repeat(10416) @(posedge sys_clk);
        uart_rec_datah = 1'b1;
        repeat(10416 * 3) @(posedge sys_clk);

        test_count = test_count + 1;
        if (dut_rec_readyh == 1'b1   &&
            dut_rec_busyh  == 1'b0   &&
            dut_rec_datah  == 8'h00)
        begin
            $display("[PASS] Framing Error Test");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Framing Error Test");
            $display("  DUT RX : ready=%b busy=%b data=0x%02X",
                      dut_rec_readyh, dut_rec_busyh, dut_rec_datah);
            $display("  Expected: ready=1 busy=0 data=0x00");
            fail_count = fail_count + 1;
        end
    end
endtask

task test_tx_back_to_back;
    begin
        wait (dut_xmit_active == 0);
        wait (ref_xmit_active == 0);

        @(posedge ref_uart_clk);
        xmit_dataH = 8'h3C;
        xmitH = 1'b1;
        @(posedge ref_uart_clk);
        xmitH = 1'b0;

        wait_tx_complete;

        @(posedge ref_uart_clk);
        xmit_dataH = 8'hC3;
        xmitH = 1'b1;
        @(posedge ref_uart_clk);
        xmitH = 1'b0;

        wait_tx_complete;

        test_count = test_count + 1;
        if (compare_tx(
                dut_xmit_doneH, dut_xmit_active, dut_uart_xmit_datah,
                ref_xmit_doneH, ref_xmit_active, ref_uart_xmit_datah))
        begin
            $display("[PASS] TC-16 Back-to-Back TX (0x3C then 0xC3)");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] TC-16 Back-to-Back TX");
            display_tx_mismatch;
            fail_count = fail_count + 1;
        end
    end
endtask

task test_tx_alternating;
    begin
        apply_test_tx(8'h55, "TC-17 TX Alternating 0x55");
    end
endtask

task test_rx_bit5_set;
    begin
        apply_test_rx(8'h20, "TC-18 RX Bit5 Set 0x20");
    end
endtask

task test_rx_glitch_short;
    integer t;
    begin
        uart_rec_datah = 1'b1;
        repeat(10) @(posedge ref_uart_clk);

        uart_rec_datah = 1'b0;
        repeat(5) @(posedge sys_clk);
        uart_rec_datah = 1'b1;

        repeat(30) @(posedge ref_uart_clk);

        test_count = test_count + 1;
        if (dut_rec_busyh == 1'b0 && dut_rec_readyh == 1'b1) begin
            $display("[PASS] TC-19 RX Short Glitch Rejected");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] TC-19 RX Short Glitch Not Rejected");
            $display("  DUT RX : ready=%b busy=%b data=0x%02X",
                      dut_rec_readyh, dut_rec_busyh, dut_rec_datah);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    pass_count     = 0;
    fail_count     = 0;
    test_count     = 0;

    sys_rst        = 1'b0;
    xmitH          = 1'b0;
    xmit_dataH     = 8'h00;
    uart_rec_datah = 1'b1;

    #200;
    sys_rst = 1'b1;

    repeat(10) @(posedge ref_uart_clk);

    $display("--------------------------------");
    $display("UART TRANSMITTER TESTS");
    $display("--------------------------------");
    test_transmitter;

    $display("--------------------------------");
    $display("UART RECEIVER TESTS");
    $display("--------------------------------");
    uart_rec_datah = 1'b1;
    test_receiver;

    $display("--------------------------------");
    $display("NEW COVERAGE IMPROVEMENT TESTS");
    $display("--------------------------------");

    test_tx_back_to_back;
    test_tx_alternating;

    uart_rec_datah = 1'b1;
    repeat(5) @(posedge ref_uart_clk);

    test_rx_bit5_set;
    test_rx_glitch_short;

    $display("--------------------------------");
    $display("TOTAL TESTS : %0d", test_count);
    $display("PASS        : %0d", pass_count);
    $display("FAIL        : %0d", fail_count);
    if (fail_count == 0)
        $display("ALL TESTS PASSED");
    else
        $display("SOME TESTS FAILED");
    $display("--------------------------------");

    #100;
    $finish;
end

initial begin
    #100_000_000;
    $display("[WATCHDOG] Simulation Timeout");
    $finish;
end

endmodule