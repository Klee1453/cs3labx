`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    21:34:44 03/12/2012
// Design Name:
// Module Name:    REGS ID/EX Latch
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

module    REG_ID_EX(input clk,                                          //ID/EX Latch
                    input rst,
                    input EN,                                           //流水寄存器使�?
                    input flush,                                        //数据竞争清除并等待：DStall
                    input [31:0] IR_ID,                                 //当前译码指令(测试)
                    input [63:0] PCurrent_ID,                           //当前译码指令存储器指�?
                    input [4:0] rs1_addr,                               //当前指令读出寄存器A地址
                    input [4:0] rs2_addr,                               //当前指令读出寄存器B地址
                    input [63:0] rs1_data,                              //当前指令读出寄存器A数据
                    input [63:0] rs2_data,                              //当前指令读出寄存器A数据
                    input [63:0] Imm32,                                 //当前指令读出并扩�?64位立即数�?
                    input [4:0]  rd_addr,                               //当前指令读出目的操作数地�?
                    input ALUSrc_A,                                     //当前指令译码：ALU A通道控制
                    input ALUSrc_B,                                     //当前指令译码：ALU B通道控制
                    input [4:0]  ALUC,                                  //当前指令译码：ALU操作控制
                    input DatatoReg,                                    //当前指令译码：REG写数据�?�道选择
                    input RegWrite,                                     //当前指令译码：寄存器写信�?
                    input WR,                                           //当前指令译码：存储器读写信号
                    input [2:0] u_b_h_w,
                    input MIO,
                    input csr_rw,                                       //当前译码指令是否是csr读写指令
                    input csr_w_imm_mux,                                //用于选择向csr写入的是zimm还是寄存器值
                    input mret,                                         //目前还不知道是什么
                    input [3:0]exp_vector,                              //用于判断中断类型[illegal inst | SRET | ECALL | inst page fault]
                    output reg[63:0] PCurrent_EX,                       //锁存当前译码指令地址
                    output reg[31:0] IR_EX,                             //锁存当前译码指令(测试)
                    output reg[4:0]  rs1_EX,
                    output reg[4:0]  rs2_EX,
                    output reg[63:0] A_EX,                              //锁存当前译码指令读出寄存器A数据
                    output reg[63:0] B_EX,                              //锁存当前译码指令读出寄存器B数据
                    output reg[63:0] Imm32_EX,                          //锁存当前译码指令64位立即数
                    output reg[4:0]  rd_EX,                             //锁存当前译码指令写目的寄存器地址
                    output reg       ALUSrc_A_EX,                       //锁存当前译码指令ALU A通道控制
                    output reg       ALUSrc_B_EX,                       //锁存当前译码指令ALU B通道控制(保留)
                    output reg[4:0]  ALUC_EX,                           //锁存当前译码指令ALU操作功能控制
                    output reg       DatatoReg_EX,                      //锁存当前译码指令REG写数据�?�道选择
                    output reg       RegWrite_EX,                       //锁存当前译码指令寄存器写信号
                    output reg       WR_EX,                             //锁存当前译码指令存储器读写信�?
                    output reg[2:0]  u_b_h_w_EX,
                    output reg       MIO_EX,
                    output reg       isFlushed,                         //锁存当前ID_EX阶段寄存器是否被flush信号控制
                    output reg       csr_rw_EX,                         //锁存当前译码指令是否是csr读写指令
                    output reg       csr_w_imm_mux_EX,                  //锁存当前译码指令是否是csr读写指令向csr写入值的选择控制
                    output reg       mret_EX,                           //锁存mret，目前还不知道干什么
                    output reg[3:0]  exp_vector_EX                      //所存当前译码指令的中断类型向量
                );

    always @(posedge clk or posedge rst) begin                           //ID/EX Latch
        if (rst) begin
            rd_EX               <= 0;
            RegWrite_EX         <= 0;
            WR_EX               <= 0;
            IR_EX               <= 32'h00000000;
            PCurrent_EX         <= 64'h00000000 ;
            rs1_EX              <= 0;
            rs2_EX              <= 0;
            MIO_EX              <= 0;
            isFlushed           <= 0;
            csr_rw_EX           <= 0;
            csr_w_imm_mux_EX    <= 0;
            mret_EX             <= 0;
            exp_vector_EX       <= 4'b000;
        end
        else if (EN) begin
            isFlushed <= flush;
            if (flush) begin                             //数据冲突时冲刷流水线禁止改变CPU状�??
                IR_EX       <= 32'h00000013;             //nop,废弃当前取脂 : 插入32'h00000013
                rd_EX       <= 0;                        //cancel Instruction write address
                RegWrite_EX <= 0;                        //寄存器写信号：禁止寄存器�?
                WR_EX       <= 0;                        //cancel write memory
                PCurrent_EX <= PCurrent_ID;              //传�?�PC(测试)
                MIO_EX      <= 0;
            end
            else begin                                   //无数据冲突正常传输到EX�?
                PCurrent_EX <= PCurrent_ID;              //传�?�当前指令地�?
                IR_EX       <= IR_ID;                    //传�?�当前指令地�?(测试)
                A_EX        <= rs1_data;                 //传�?�寄存器A读出数据
                B_EX        <= rs2_data;                 //传�?�寄存器B读出数据
                Imm32_EX    <= Imm32;                    //传�?�扩展后立即�?
                rd_EX       <= rd_addr;                  //传�?�写目的寄存器地�?
                rs1_EX      <= rs1_addr;
                rs2_EX      <= rs2_addr;
                ALUSrc_A_EX <= ALUSrc_A;                 //传�?�ALU A通道控制信号
                ALUSrc_B_EX <= ALUSrc_B;                 //传�?�ALU B通道控制信号
                ALUC_EX     <= ALUC;                     //传�?�ALU操作功能控制信号
                DatatoReg_EX<= DatatoReg;                //传�?�REG写数据�?�道选择
                RegWrite_EX <= RegWrite;                 //传�?�寄存器写信�?
                WR_EX       <= WR;                       //传�?�存储器读写信号
                u_b_h_w_EX  <= u_b_h_w;
                MIO_EX      <= MIO;
                csr_rw_EX           <= csr_rw;
                csr_w_imm_mux_EX    <= csr_w_imm_mux;
                mret_EX             <= mret;
                exp_vector_EX       <= exp_vector;
            end
        end
    end

endmodule