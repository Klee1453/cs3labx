`timescale 1ns / 1ps

module ALU(
    input[63:0] A, B,
    input[4:0] Control,
    output[63:0] res,
    output zero, overflow
);

    localparam ALU_ADD  = 5'b00001;
    localparam ALU_SUB  = 5'b00010;
    localparam ALU_AND  = 5'b00011;
    localparam ALU_OR   = 5'b00100;
    localparam ALU_XOR  = 5'b00101;
    localparam ALU_SLL  = 5'b00110;
    localparam ALU_SRL  = 5'b00111;
    localparam ALU_SLT  = 5'b01000;
    localparam ALU_SLTU = 5'b01001;
    localparam ALU_SRA  = 5'b01010;
    localparam ALU_Ap4  = 5'b01011;
    localparam ALU_Bout = 5'b01100;
    localparam ALU_ADDW = 5'b10001; 
    localparam ALU_SUBW = 5'b10010;
    localparam ALU_SLLW = 5'b10110;
    localparam ALU_SRLW = 5'b10111;
    localparam ALU_SRAW = 5'b11010;

    wire[5:0] shamt = B[5:0];       // shamt is located in inst[25:20]. 
                                    // and since shamt is only needed for I-type instructions, 
                                    // we can use [5:0] of ALUsrcB(imm).
                                    // See also: ImmGen.v
                                    // wire[63:0] Imm_I = {{52{inst_field[31]}}, inst_field[31:20]};
    wire[4:0] shamt32 = shamt[4:0]; // used for slliw, srliw, sraiw
                                    // HIDDEN DANGERS:
                                    // (from manual 2017) These instructions are valid iff shamt[5]=0
    wire[64:0] res_subu = {1'b0,A} - {1'b0,B};

    wire[63:0] res_ADD  = A + B;
    wire[63:0] res_SUB  = A - B;
    wire[63:0] res_AND  = A & B;
    wire[63:0] res_OR   = A | B;
    wire[63:0] res_XOR  = A ^ B;
    wire[63:0] res_SLL  = A << shamt;
    wire[63:0] res_SRL  = A >> shamt;
    wire[63:0] res_SLLW = A << shamt32;
    wire[63:0] res_SRLW = {32'b0, A[31:0]} >> shamt32;

    wire add_of = A[63] & B[63] & ~res_ADD[63] | // neg + neg = pos
                  ~A[63] & ~B[63] & res_ADD[63]; // pos + pos = neg
    wire sub_of = ~A[63] & B[63] & res_SUB[63] | // pos - neg = neg
                  A[63] & ~B[63] & ~res_SUB[63]; // neg - pos = pos
    
    wire[63:0] res_SLT  = {63'b0, res_SUB[63] ^ sub_of};
    wire[63:0] res_SLTU = {63'b0, res_subu[64]};
    wire[63:0] res_SRA  = {{64{A[63]}}, A} >> shamt;
    wire[63:0] res_SRAW = {{32{A[31]}}, A[31:0]} >> shamt32;
    wire[63:0] res_Ap4  = A + 4;
    wire[63:0] res_Bout = B;

    wire ADD  = Control == ALU_ADD ;
    wire SUB  = Control == ALU_SUB ;
    wire AND  = Control == ALU_AND ;
    wire OR   = Control == ALU_OR  ;
    wire XOR  = Control == ALU_XOR ;
    wire SLL  = Control == ALU_SLL ;
    wire SRL  = Control == ALU_SRL ;
    wire SLT  = Control == ALU_SLT ;
    wire SLTU = Control == ALU_SLTU;
    wire SRA  = Control == ALU_SRA ;
    wire Ap4  = Control == ALU_Ap4 ;
    wire Bout = Control == ALU_Bout;
    wire ADDW = Control == ALU_ADDW; 
    wire SUBW = Control == ALU_SUBW;
    wire SLLW = Control == ALU_SLLW;
    wire SRLW = Control == ALU_SRLW;
    wire SRAW = Control == ALU_SRAW;
    
    assign zero = ~|res;
    
    assign overflow = (Control == ALU_ADD && add_of) | 
                    (Control == ALU_SUB && sub_of); // HIDDEN DANGERS:
                                                    // We do not consider overflows for -w instructions, 
                                                    // even though they may indeed occur (for the lower 32 bits)
                                                    // I have confirmed that in our current RV64I processor, 
                                                    // there is no utilization to the ALUoverflow_EXE (here, overflow) signal
    
    assign res =    {64{ADD }} & res_ADD  |
                    {64{SUB }} & res_SUB  |
                    {64{AND }} & res_AND  |
                    {64{OR  }} & res_OR   |
                    {64{XOR }} & res_XOR  |
                    {64{SLL }} & res_SLL  |
                    {64{SRL }} & res_SRL  |
                    {64{SLT }} & res_SLT  |
                    {64{SLTU}} & res_SLTU |
                    {64{SRA }} & res_SRA  |
                    {64{Ap4 }} & res_Ap4  |
                    {64{Bout}} & res_Bout |
                    {64{ADDW}} & {{32{res_ADD[31]}}, res_ADD[31:0]}     |
                    {64{SUBW}} & {{32{res_SUB[31]}}, res_SUB[31:0]}     |
                    {64{SLLW}} & {{32{res_SLLW[31]}}, res_SLLW[31:0]}   |
                    {64{SRLW}} & {{32{res_SRLW[31]}}, res_SRLW[31:0]}   |
                    {64{SRAW}} & {{32{res_SRAW[31]}}, res_SRAW[31:0]}   ;

endmodule