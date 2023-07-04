`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    21:34:44 03/12/2012
// Design Name:
// Module Name:    REGS IF/ID Latch
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module    REG_IF_ID(input clk,                                      //IF/ID Latch
                    input rst,
                    input EN,                                       //流水寄存器使能
                    input Data_stall,                               //数据竞争等待
                    input flush,                                    //控制竞争清除并等待
                    input [63:0] PCOUT,                             //指令存储器指针
                    input [31:0] IR,                                //指令存储器输出
                    input inst_access_fault,                        //取指令缺页异常

                    output reg[31:0] IR_ID,                         //取指锁存
                    output reg[63:0] PCurrent_ID,                   //当前存在指令地址
                    output reg inst_access_fault_ID,                //取指令缺页异常
                    output reg isFlushed                            //当前周期IF_ID是否收到flush信号
                );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            IR_ID <= 32'h00000000;                          //复位清零
            PCurrent_ID <= 64'h00000000;                    //复位清零
            inst_access_fault_ID <= 1'b0;                   //复位清零
            isFlushed <= 1'b0;                              //复位清零
        end
        else if (EN) begin
            isFlushed <= flush;
            if (Data_stall) begin
                IR_ID <= IR_ID;                         //IR waiting for Data Hazards 并暂停取指
                PCurrent_ID <= PCurrent_ID;             //保存对应PC指针
            end
            else if (flush) begin
                IR_ID <= 32'h00000013;                  //IR waiting for Control Hazards i清s除指令并暂停
                PCurrent_ID <= PCurrent_ID;             //清除指令的指针(测试)         
            end
            else begin
                IR_ID <= IR;                        //正常取指,传送下一流水级译码
                PCurrent_ID <= PCOUT;               //当前取指PC地址，Branch/Jump指令计算目标地址用(非PC+4)
                inst_access_fault_ID <= inst_access_fault;
            end
        end
        else begin
            IR_ID <= IR_ID;
            PCurrent_ID <= PCurrent_ID;
        end
    end

endmodule