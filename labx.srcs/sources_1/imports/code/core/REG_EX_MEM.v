`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    21:34:44 03/12/2012
// Design Name:
// Module Name:    REGS EX/MEM Latch
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

module   REG_EX_MEM(input clk,                                      //EX/MEM Latch
                    input rst,
                    input EN,                                       //流水寄存器使�?
                    input flush,                                    //异常时清除异常指令并等待中断处理(保留)�?
                    input [31:0] IR_EX,                             //当前执行指令(测试)
                    input [63:0] PCurrent_EX,                       //当前执行指令存储器指�?
                    input [63:0] ALUO_EX,                           //当前ALU执行输出：有效地�?或ALU操作
                    input [63:0] A_EX,                              //ID段读出的rs1数据：在MEM段做csr写指令的时候会使用到
                    input [63:0] B_EX,                              //ID级读出寄存器B数据：CPU输出数据
                    input [4:0]  rd_EX,                             //传�?�当前指令写目的寄存器地�?
                    input DatatoReg_EX,                             //传�?�当前指令REG写数据�?�道选择
                    input RegWrite_EX,                              //传�?�当前指令寄存器写信�?
                    input WR_EX,                                    //传�?�当前指令存储器读写信号
                    input [2:0] u_b_h_w_EX,
                    input MIO_EX,
                    input csr_rw_EX,                                //传�?�当前指令是否是csr读写指令
                    input csr_w_imm_mux_EX,                         //传�?�当前指令csr写选择信号
                    input mret_EX,                                  //不知道干什么的
                    input [3:0] exp_vector_EX,                      //传�?�当前指令的异常类型向量[illegal inst | SRET | ECALL | inst page fault]

                    output reg[63:0] PCurrent_MEM,                  //锁存传�?�当前指令地�?
                    output reg[31:0] IR_MEM,                        //锁存传�?�当前指�?(测试)
                    output reg[63:0] ALUO_MEM,                      //锁存ALU操作结果：有效地�?或ALU操作
                    output reg[63:0] Datao_MEM,                     //锁存传�?�当前指令输出MIO数据
                    output reg[63:0] A_MEM,                         //锁存ID段读出的rs1数据
                    output reg[4:0]  rd_MEM,                        //锁存传�?�当前指令写目的寄存器地�?
                    output reg       DatatoReg_MEM,                 //锁存传�?�当前指令REG写数据�?�道选择
                    output reg       RegWrite_MEM,                  //锁存传�?�当前指令寄存器写信�?
                    output reg       WR_MEM,                        //锁存传�?�当前指令存储器读写信号
                    output reg[2:0]  u_b_h_w_MEM,
                    output reg       MIO_MEM,
                    output reg       isFlushed,                     //锁存EX_MEM阶段间寄存器的flush状态
                    output reg       csr_rw_MEM,                    //锁存当前指令是否是csr读写指令
                    output reg       csr_w_imm_mux_MEM,             //所存当前指令csr写选择信号
                    output reg       mret_MEM,                      //目前还不知道干什么的
                    output reg[3:0]  exp_vector_MEM                 //锁存当前指令的异常类型向量
                );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            IR_MEM       <= 0;
            PCurrent_MEM <= 0;
            rd_MEM       <= 0;
            RegWrite_MEM <= 0;
            WR_MEM       <= 0;
            MIO_MEM      <= 0;
            isFlushed    <= 0;
            csr_rw_MEM          <= 0;
            csr_w_imm_mux_MEM   <= 0;
            mret_MEM            <= 0;
            exp_vector_MEM      <= 4'b000;
        end
        else if (EN) begin                                          //EX级正常传输到MEM�?
            isFlushed       <= flush;
            if (flush) begin
                IR_MEM          <= 32'h00000013;
                PCurrent_MEM    <= 0;
                ALUO_MEM        <= 0;
                Datao_MEM       <= 0;
                A_MEM           <= 0;
                DatatoReg_MEM   <= 0;
                RegWrite_MEM    <= 0;
                WR_MEM          <= 0;
                rd_MEM          <= 0;
                u_b_h_w_MEM     <= 0;
                MIO_MEM         <= 0;
                csr_rw_MEM          <= 0;
                csr_w_imm_mux_MEM   <= 0;
                mret_MEM            <= 0;
                exp_vector_MEM      <= 0;
            end
            else begin
                IR_MEM          <= IR_EX;
                PCurrent_MEM    <= PCurrent_EX;                     //传�?�锁存当前指令地�?
                ALUO_MEM        <= ALUO_EX;                         //锁存有效地址或ALU操作
                Datao_MEM       <= B_EX;                            //传�?�锁存CPU输出数据
                A_MEM           <= A_EX;                            //
                DatatoReg_MEM   <= DatatoReg_EX;                    //传�?�锁存REG写数据�?�道选择
                RegWrite_MEM    <= RegWrite_EX;                     //传�?�锁存目的寄存器写信�?
                WR_MEM          <= WR_EX;                           //传�?�锁存存储器读写信号
                rd_MEM          <= rd_EX;                           //传�?�锁存写目的寄存器地�?
                u_b_h_w_MEM     <= u_b_h_w_EX;
                MIO_MEM         <= MIO_EX;
                csr_rw_MEM          <= csr_rw_EX;
                csr_w_imm_mux_MEM   <= csr_w_imm_mux_EX;
                mret_MEM            <= mret_EX;
                exp_vector_MEM      <= exp_vector_EX;
            end
        end
    end

endmodule