`timescale 1ns / 1ps

module ExceptionUnit(
        input clk, rst,
                                            // [MEM]
        input csr_rw_in,                    // used for identifying CSR write-after-read instructions
        input[1:0] csr_wsc_mode_in,         // used for identifying CSR write-after-read mode (W, S, C), funct3[1:0]
        input csr_w_imm_mux,                // used for identifying CSR write-after-read zimm instructions
        input[11:0] csr_rw_addr_in,         // CSR registers address
        input[63:0] csr_w_data_reg,         // genernal registers used in CSRRW, CSRRS, CSRRC
        input[4:0] csr_w_data_imm,          // zimm in CSRR[W,S,C]I
        output[63:0] csr_r_data_out,        // read data of CSR write-after-read instructions
        output[63:0] satp_o,                // satp read value for MMU

                                            // [WB]
        input interrupt,                    // external interrupt source, for future use
        input illegal_inst,                 // illegal instruct, from Control Unit
        input l_access_fault,               // load  page fault, from MMU               
        input s_access_fault,               // store page fault, from MMU
        input inst_access_fault,            // inst  page fault, from MMU 
        input ecall,                        // is ECALL inst, from Control Unit
        input sret,                         // is SRET  inst, from Control Unit

        input[63:0] epc_cur,                // PC_WB, PC that triggered the exception
        input[63:0] epc_next,               // The next VALID PC of the PC that triggered the exception          
        output[63:0] PC_redirect,           // used in IF, next PC after exception triggered
        output redirect_mux,                // used in IF, for final decision on PC

        output reg_FD_flush, reg_DE_flush, reg_EM_flush, reg_MW_flush,  // flush all instructions read in after a trap
        output RegWrite_cancel                                          // fulsh all instructions read in after a trap
       );

reg[11:0] csr_raddr, csr_waddr;
reg[63:0] csr_wdata;
reg csr_w;
reg[1:0] csr_wsc;

wire[63:0] sstatus;

reg[63:0] sepc, scause, stval;
wire[63:0] stvec, sepc_o;

wire exception = illegal_inst | l_access_fault | s_access_fault | inst_access_fault | ecall;
// wire trap = sstatus[3] & (interrupt | exception);
wire trap = interrupt | exception;

CSRRegs csr(.clk(clk),.rst(rst),.csr_w(csr_w),.raddr(csr_raddr),.waddr(csr_waddr),
            .wdata(csr_wdata),.rdata(csr_r_data_out),.sstatus(sstatus),.csr_wsc_mode(csr_wsc),
            .is_trap(trap),.is_sret(sret),.sepc(sepc),.scause(scause),.stval(stval),.stvec(stvec),.sepc_o(sepc_o),.satp_o(satp_o));

//According to the diagram, design the Exception Unit

reg reg_FD_flush_, reg_DE_flush_, reg_EM_flush_, reg_MW_flush_;
reg RegWrite_cancel_;

always @ *
  begin
    if (csr_rw_in)
      begin
        csr_w <= 1;
        csr_wsc <= csr_wsc_mode_in;
        csr_wdata <= csr_w_imm_mux ? csr_w_data_imm : csr_w_data_reg;
        csr_raddr <= csr_rw_addr_in;
        csr_waddr <= csr_rw_addr_in;
      end
    else
      begin
        csr_w <= 0;
        csr_wsc <= 0;
        csr_wdata <= 0;
        csr_raddr <= 0;
        csr_waddr <= 0;
      end

    // if (interrupt & sstatus[3])
    if (interrupt)
      begin
        sepc <= epc_next;
        scause <= 64'h8000000B;  // Machine external interrupt
        stval <= 0;
      end
    // else if (illegal_inst & sstatus[3])
    else if (illegal_inst)
      begin
        sepc <= epc_cur;
        scause <= 2;
        stval <= 0;
      end
    // else if (l_access_fault & sstatus[3])
    else if (l_access_fault)
      begin
        sepc <= epc_cur;
        scause <= 5;
        stval <= 0;
      end
    // else if (s_access_fault & sstatus[3])
    else if (s_access_fault)
      begin
        sepc <= epc_cur;
        scause <= 7;
        stval <= 0;
      end
    // else if (ecall & sstatus[3])
    else if (ecall)
      begin
        sepc <= epc_cur;
        scause <= 11;
        stval <= 0;
      end
    else if (sret)
      begin
        sepc <= 0;
        scause <= 0;
        stval <= 0;
      end
    else
      begin
        sepc <= 0;
        scause <= 0;
        stval <= 0;
      end

    if (trap)
      begin
        reg_FD_flush_ = 1;
        reg_DE_flush_ = 1;
        reg_EM_flush_ = 1;
        reg_MW_flush_ = 1;
        RegWrite_cancel_ = 1;
      end
    else if (sret) 
      begin
        reg_FD_flush_ = 1;
        reg_DE_flush_ = 1;
        reg_EM_flush_ = 1;
        reg_MW_flush_ = 1;
        RegWrite_cancel_ = 1;
      end
    else
      begin
        reg_FD_flush_ = 0;
        reg_DE_flush_ = 0;
        reg_EM_flush_ = 0;
        reg_MW_flush_ = 0;
        RegWrite_cancel_ = 0;
      end
  end

assign PC_redirect = sret ? (sepc_o + 64'd4) : stvec;
assign redirect_mux = sret | trap | ecall;  // In IF, control the PC used to fetch instruction
assign reg_FD_flush = reg_FD_flush_;
assign reg_DE_flush = reg_DE_flush_;
assign reg_EM_flush = reg_EM_flush_;
assign reg_MW_flush = reg_MW_flush_;
assign RegWrite_cancel = RegWrite_cancel_;

endmodule