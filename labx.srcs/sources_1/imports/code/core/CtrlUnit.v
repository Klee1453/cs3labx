`timescale 1ns / 1ps


module CtrlUnit(
         input[31:0] inst,
         input cmp_res,
         output Branch, ALUSrc_A, ALUSrc_B, DatatoReg, RegWrite, mem_w,
         MIO, rs1use, rs2use,
         output [1:0] hazard_optype,
         output [2:0] ImmSel, cmp_ctrl,
         output [4:0] ALUControl,
         output [2:0] exp_vector_ctrl,  // for identifying exceptions, [2|1|0] => [illegal_inst | sret | ecall], used in ExceptionUnit of stage WB
         output csr_rw,                 // is CSR write-after-read instructions, used in ExceptionUnit of stage MEM
         output csr_w_imm_mux,          // for identifying CSR write-after-read zimm or not, used in ExceptionUnit of stage MEM
         output JALR,
         output J
       );

wire[6:0] funct7 = inst[31:25];
wire[4:0] rs2    = inst[24:20];   // used only when identifying privileged instructions
wire[4:0] rs1    = inst[19:15];   // used only when identifying privileged instructions
wire[2:0] funct3 = inst[14:12];
wire[4:0] rd     = inst[11:7];    // used only when identifying privileged instructions
wire[6:0] opcode = inst[6:0];

wire Rop   = opcode == 7'b0110011;
wire Rwop  = opcode == 7'b0111011;
wire Iop   = opcode == 7'b0010011;
wire Iwop  = opcode == 7'b0011011;  // I-type word-wide (32-bit-wide)
wire Bop   = opcode == 7'b1100011;
wire Lop   = opcode == 7'b0000011;
wire Sop   = opcode == 7'b0100011;
wire CSRop = opcode == 7'b1110011;  // Privileged instructions

wire funct7_0  = funct7 == 7'h0;
wire funct7_32 = funct7 == 7'h20;  // 7'b010000

wire funct3_0 = funct3 == 3'h0;
wire funct3_1 = funct3 == 3'h1;
wire funct3_2 = funct3 == 3'h2;
wire funct3_3 = funct3 == 3'h3;
wire funct3_4 = funct3 == 3'h4;
wire funct3_5 = funct3 == 3'h5;
wire funct3_6 = funct3 == 3'h6;
wire funct3_7 = funct3 == 3'h7;

wire ADD   = Rop  & funct3_0 & funct7_0;
wire ADDW  = Rwop & funct3_0 & funct7_0;  // rv64i word-wide inst
wire SUB   = Rop  & funct3_0 & funct7_32;
wire SUBW  = Rwop & funct3_0 & funct7_32; // rv64i word-wide inst
wire SLL   = Rop  & funct3_1 & funct7_0;
wire SLLW  = Rwop & funct3_1 & funct7_0;  // rv64i word-wide inst
wire SLT   = Rop  & funct3_2 & funct7_0;
wire SLTU  = Rop  & funct3_3 & funct7_0;
wire XOR   = Rop  & funct3_4 & funct7_0;
wire SRL   = Rop  & funct3_5 & funct7_0;
wire SRLW  = Rwop & funct3_5 & funct7_0;  // rv64i word-wide inst
wire SRA   = Rop  & funct3_5 & funct7_32;
wire SRAW  = Rwop & funct3_5 & funct7_32; // rv64i word-wide inst
wire OR    = Rop  & funct3_6 & funct7_0;
wire AND   = Rop  & funct3_7 & funct7_0;

wire ADDI  = Iop  & funct3_0;
wire ADDIW = Iwop & funct3_0;             // rv64i word-wide inst
wire SLTI  = Iop  & funct3_2;
wire SLTIU = Iop  & funct3_3;
wire XORI  = Iop  & funct3_4;
wire ORI   = Iop  & funct3_6;
wire ANDI  = Iop  & funct3_7;
wire SLLI  = Iop  & funct3_1 & (funct7[6:1] == 6'b0);
wire SLLIW = Iwop & funct3_1 & (funct7[6:1] == 6'b0);          // rv64i word-wide inst
wire SRLI  = Iop  & funct3_5 & (funct7[6:1] == 6'b0);
wire SRLIW = Iwop & funct3_5 & (funct7[6:1] == 6'b0);          // rv64i word-wide inst
wire SRAI  = Iop  & funct3_5 & (funct7[6:1] == 6'b010000);
wire SRAIW = Iwop & funct3_5 & funct7_0;                       // rv64i word-wide inst

wire BEQ  = Bop & funct3_0;  // to fill sth. in
wire BNE  = Bop & funct3_1;  // to fill sth. in
wire BLT  = Bop & funct3_4;  // to fill sth. in
wire BGE  = Bop & funct3_5;  // to fill sth. in
wire BLTU = Bop & funct3_6;  // to fill sth. in
wire BGEU = Bop & funct3_7;  // to fill sth. in

wire LB  = Lop & funct3_0;  // to fill sth. in
wire LH  = Lop & funct3_1;  // to fill sth. in
wire LW  = Lop & funct3_2;  // to fill sth. in
wire LD  = Lop & funct3_3;  // rv64i, load double word
wire LBU = Lop & funct3_4;  // to fill sth. in
wire LHU = Lop & funct3_5;  // to fill sth. in
wire LWU = Lop & funct3_6;  // rv64i, load word unsigned

wire SB = Sop & funct3_0;   // to fill sth. in
wire SH = Sop & funct3_1;   // to fill sth. in
wire SW = Sop & funct3_2;   // to fill sth. in
wire SD = Sop & funct3_3;   // rv64i, save double word 

wire LUI   = (opcode == 7'b0110111);  // to fill sth. in
wire AUIPC = (opcode == 7'b0010111);  // to fill sth. in

wire JAL    = (opcode == 7'b1101111);  // to fill sth. in
assign JALR = (opcode == 7'b1100111);  // to fill sth. in

wire ECALL      = CSRop & (funct7 == 7'b0000000) & (rs2 == 5'b00000) & (rs1 == 5'b00000) & (funct3 == 3'b000) & (rd == 5'b00000);
wire CSRRW      = CSRop & funct3_1;
wire CSRRS      = CSRop & funct3_2;
wire CSRRC      = CSRop & funct3_3;
wire CSRRWI     = CSRop & funct3_5;
wire CSRRSI     = CSRop & funct3_6;
wire CSRRCI     = CSRop & funct3_7;
wire SRET       = CSRop & (funct7 == 7'b0001000) & (rs2 == 5'b00010) & (rs1 == 5'b00000) & (funct3 == 3'b000) & (rd == 5'b00000);
wire SFENCEVMA  = CSRop & (funct7 == 7'b0001001) & (funct3 == 3'b000) & (rd == 5'b00000);   // currently, it should works like a nop

wire illegal_inst = 0;  // TODO

wire R_valid  = AND | OR | ADD | XOR | SLL | SRL | SRA | SUB | SLT | SLTU;
wire Rw_valid = ADDW | SUBW | SLLW | SRLW | SRAIW;
wire I_valid  = ANDI | ORI | ADDI | XORI | SLLI | SRLI | SRAI | SLTI | SLTIU;
wire Iw_valid = ADDIW | SLLIW | SRLIW | SRAIW;
wire B_valid  = BEQ | BNE | BLT | BGE | BLTU | BGEU;
wire L_valid  = LD | LW | LH | LB | LWU | LHU | LBU;
wire S_valid  = SD | SW | SH | SB;

assign Branch = cmp_res | JAL | JALR | ECALL | SRET;  // to fill sth. in

// CSR指令的ImmSel = 0 ALU中使用的ALU_b = 0
parameter Imm_type_I = 3'b001;
parameter Imm_type_B = 3'b010;
parameter Imm_type_J = 3'b011;
parameter Imm_type_S = 3'b100;
parameter Imm_type_U = 3'b101;
assign ImmSel = {3{I_valid | Iw_valid | JALR | L_valid}} & Imm_type_I |
       {3{B_valid}}                                      & Imm_type_B |
       {3{JAL}}                                          & Imm_type_J |
       {3{S_valid}}                                      & Imm_type_S |
       {3{LUI | AUIPC}}                                  & Imm_type_U ;


parameter cmp_EQ  = 3'b001;
parameter cmp_NE  = 3'b010;
parameter cmp_LT  = 3'b011;
parameter cmp_LTU = 3'b100;
parameter cmp_GE  = 3'b101;
parameter cmp_GEU = 3'b110;
assign cmp_ctrl = {3{Bop}} &
       (({3{BEQ}} & cmp_EQ) |
        ({3{BNE}} & cmp_NE) |
        ({3{BLT}} & cmp_LT) |
        ({3{BGE}} & cmp_GE) |
        ({3{BLTU}} & cmp_LTU) |
        ({3{BGEU}} & cmp_GEU));  // to fill sth. in

assign ALUSrc_A = R_valid | Rw_valid | I_valid | Iw_valid | B_valid | L_valid | S_valid | JALR  | CSRRC | CSRRS | CSRRW; // to fill sth. in
                                                                                                // 1 -> ALU_inputA = rs1_EXE, 0 -> ALU_inputA = PC_EXE

assign ALUSrc_B = ~(R_valid | Rw_valid | B_valid);  // to fill sth. in
                                                    // 1 -> ALU_inputB = Imm_EXE, 0 -> ALU_inputB = rs2_EXE

parameter ALU_ADD  = 5'b00001;
parameter ALU_SUB  = 5'b00010;
parameter ALU_AND  = 5'b00011;
parameter ALU_OR   = 5'b00100;
parameter ALU_XOR  = 5'b00101;
parameter ALU_SLL  = 5'b00110;
parameter ALU_SRL  = 5'b00111;
parameter ALU_SLT  = 5'b01000;
parameter ALU_SLTU = 5'b01001;
parameter ALU_SRA  = 5'b01010;
parameter ALU_Ap4  = 5'b01011;
parameter ALU_Bout = 5'b01100;
parameter ALU_ADDW = 5'b10001;   // The highest bit = 1 indicates -w instruction in RV64I
parameter ALU_SUBW = 5'b10010;
parameter ALU_SLLW = 5'b10110;
parameter ALU_SRLW = 5'b10111;
parameter ALU_SRAW = 5'b11010;

assign ALUControl = {5{ADD | ADDI | L_valid | S_valid | AUIPC | CSRRC | CSRRS | CSRRW}}    & ALU_ADD  |
                    {5{SUB}}                                    & ALU_SUB  |
                    {5{AND  | ANDI}}                            & ALU_AND  |
                    {5{OR   | ORI}}                             & ALU_OR   |
                    {5{XOR  | XORI}}                            & ALU_XOR  |
                    {5{SLL  | SLLI}}                            & ALU_SLL  |
                    {5{SRL  | SRLI}}                            & ALU_SRL  |
                    {5{SLT  | SLTI}}                            & ALU_SLT  |
                    {5{SLTU | SLTIU}}                           & ALU_SLTU |
                    {5{SRA  | SRAI}}                            & ALU_SRA  |
                    {5{JAL  | JALR}}                            & ALU_Ap4  |
                    {5{LUI}}                                    & ALU_Bout |
                    {5{ADDW | ADDIW}}                           & ALU_ADDW |
                    {5{SUBW}}                                   & ALU_SUBW |
                    {5{SLLW | SLLIW}}                           & ALU_SLLW |
                    {5{SRLW | SRLIW}}                           & ALU_SRLW |
                    {5{SRAW | SRAIW}}                           & ALU_SRAW ;
// NOTE: CSR write-after-read is implemented in the Exception Unit (MEM) rather than ALU (EX), but the ALU should act as ADD 


assign csr_rw = CSRRW | CSRRS | CSRRC | CSRRWI | CSRRSI | CSRRCI;

assign csr_w_imm_mux = CSRRWI | CSRRSI | CSRRCI;

assign DatatoReg = L_valid | csr_rw;                       //在MEM阶段，最终传递给WB阶段的Datain_MEM由内存读取值和CSR读取值经过选择信号合并而来，CSR读取的指令也可以视作是load指令

assign RegWrite = R_valid | Rw_valid | I_valid | Iw_valid | JAL | JALR | L_valid | LUI | AUIPC | csr_rw | ECALL;

assign mem_w = S_valid;

assign MIO = L_valid | S_valid;

assign rs1use = ALUSrc_A;  // to fill sth. in

assign rs2use = R_valid | Rw_valid | B_valid | S_valid;  // to fill sth. in

// assign hazard_optype = ;  // to fill sth. in

assign J = JAL | JALR | B_valid | ECALL | SRET;

assign exp_vector_ctrl = {illegal_inst, SRET, ECALL};

endmodule
