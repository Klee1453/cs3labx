`timescale 1ns / 1ps


/**
 * Top module for MIPS 5-stage pipeline CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module top (//在仿真时将这个模块设为顶层模块，即去掉模块名中的1
    input wire CLK100MHZ,
    input wire [15:0] SW,
    input wire RSTN,
    input wire BTN_C,
    input wire BTN_R,

    output wire CA,    
    output wire CB,
    output wire CC,
    output wire CD,
    output wire CE,
    output wire CF,
    output wire CG,
    output wire DP,    
    output wire [7:0] AN,
    
    output wire [15:0] LED,
    output wire [3:0]VGA_B,
    output wire [3:0]VGA_G,
    output wire [3:0]VGA_R,
    output wire HS, VS,
    output wire UART_TXD
    );
    
    // clock generator
    wire clk_cpu, clk_disp;
    wire locked;
    wire clk100MHz, led_clk;

    wire [7:0] seg_ca;
    assign {DP,CG,CF,CE,CD,CC,CB,CA} = seg_ca;
    
    my_clk_gen CLK_GEN (
        .clkin1(CLK100MHZ),
        .CLK_OUT1(clk100MHz), //100MHz
        .CLK_OUT2(),          //50MHz
        .CLK_OUT3(clk_disp),  //25MHz
        .CLK_OUT4(clk_cpu),   //10MHz
        .CLK_OUT5(led_clk)
        );

    wire [1:0] btn;  //{btn_c, btn_r}
    wire btn_step;
    wire btn_interrupt;

    btn_scan #(
        .CLK_FREQ(25)
        ) BTN_SCAN (
        .clk(clk_disp),
        .rst(1'b0),
        .btn_c(BTN_C), // TODO
        .btn_r(BTN_R),
        .result(btn)
        );
    
    assign
        btn_step = btn[0],
        btn_interrupt = btn[1];
    
    // reset
    reg rst_all;
    reg [15:0] rst_count = 16'hFFFF;
    
    always @(posedge clk_cpu) begin
        rst_all <= (rst_count != 0);
        rst_count <= {rst_count[14:0], (!RSTN)};
    end

    wire [31:0] disp_data;
    wire [15:0] led_array;
    assign led_array = {btn_interrupt, btn_step, SW[13:0]};
    assign LED = led_array;
    
    wire [6:0] debug_addr;
    wire [31:0] debug_data;

    // 0 - debug_en
    // 1~5 - debug_addr
    // 6 - debug_sel (see Test_signal in CPUTEST.v)
    assign debug_addr = SW[7:1];

    // UART
    wire uart_send, uart_ready;
    wire [7:0] uart_data;
    wire [7:0] sim_uart_char;
    wire sim_uart_char_valid;
    
    RV32core chip_inst(
        .debug_mode(SW[0]),
        .step(btn_step),
        .address(debug_addr),
        .data_out(debug_data),
        .sim_uart_char_out(sim_uart_char),
        .sim_uart_char_valid(sim_uart_char_valid),
        .clk(clk_cpu),
        .areset(rst_all)
        );

    display DISPLAY (
        .clk(led_clk),
        .rst(rst_all),
        .en(8'b11111111),
        .data(debug_data),
        .dot(8'b00000000),
        .led(led_array),
        .led_clk(),
        .led_en(),
        .led_do(),
        .seg_ca(seg_ca),
        .seg_an(AN),
        .led_clr_n()
        );

    UART_TX_CTRL uart_tx_ctrl (
        .SEND(uart_send),
        .DATA(uart_data),
        .CLK(CLK100MHZ),
        .READY(uart_ready),
        .UART_TX(UART_TXD)
    );

    uart_buffer UART_BUFF (
        .clk(clk_cpu),
        .rst(rst_all),
        .ready(uart_ready),
        .sim_uart_char_valid(sim_uart_char_valid),
        .sim_uart_char(sim_uart_char),
        .send(uart_send),
        .datao(uart_data)
    );
    
endmodule
