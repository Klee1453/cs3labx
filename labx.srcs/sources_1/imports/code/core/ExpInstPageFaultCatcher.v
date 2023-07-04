`timescale 1ns / 1ps

module ExpInstPageFaultCatcher(
                                            // [IF]
        input inst_access_fault,
        input [63:0] final_PC,
        output[63:0] ultimate_final_PC
);

MUX2T1_64 mux_PC_inst_page_fault(.I0(final_PC),.I1(64'd4),.s(inst_access_fault),.o(ultimate_final_PC));

endmodule