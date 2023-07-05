`timescale 1ns / 1ps

module ImmGen(
            input  wire [2:0] ImmSel,
            input  wire [31:0] inst_field,
            output[63:0] Imm_out
    );
    parameter Imm_type_I = 3'b001;
    parameter Imm_type_B = 3'b010;
    parameter Imm_type_J = 3'b011;
    parameter Imm_type_S = 3'b100;
    parameter Imm_type_U = 3'b101;

    wire I = ImmSel == Imm_type_I;
    wire B = ImmSel == Imm_type_B;
    wire J = ImmSel == Imm_type_J;
    wire S = ImmSel == Imm_type_S;
    wire U = ImmSel == Imm_type_U;

    wire[63:0] Imm_I = {{52{inst_field[31]}}, inst_field[31:20]};
    wire[63:0] Imm_B = {{52{inst_field[31]}}, inst_field[7], inst_field[30:25], inst_field[11:8], 1'b0};
    wire[63:0] Imm_J = {{44{inst_field[31]}}, inst_field[19:12], inst_field[20], inst_field[30:21],1'b0};
    wire[63:0] Imm_S = {{52{inst_field[31]}}, inst_field[31:25], inst_field[11:7]};
    wire[63:0] Imm_U = {{32{inst_field[31]}} , inst_field[31:12], 12'b0};
    // NOTE: zimm is generated in the Exception Unit (MEM)
    // But some CSR instr need to use ALU to do res = rs1_EXE + 0
    assign Imm_out = {64{I}} & Imm_I |
                     {64{B}} & Imm_B |
                     {64{J}} & Imm_J |
                     {64{S}} & Imm_S |
                     {64{U}} & Imm_U ;
endmodule
