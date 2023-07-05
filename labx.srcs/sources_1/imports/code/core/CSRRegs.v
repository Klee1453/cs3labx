`timescale 1ns / 1ps

module CSRRegs(
        input clk, rst,
        input[11:0] raddr, waddr,   // CSR r/w addr
        input[63:0] wdata,          // genernal registers or zimm used in CSR write-after-read inst, NOT the final write data
        input csr_w,                // CSR write enable
        input[1:0] csr_wsc_mode,    // csrrw(i), csrrs(i), csrrc(i) funct3[1:0]
        output[63:0] rdata,         // CSR read value
        output[63:0] sstatus,       // read value of sstatus

        input is_trap,              // is interrupt or exception (and SIE is 1, todo)
        input is_sret,
        input[63:0] sepc,
        input[63:0] scause,
        input[63:0] stval,
        output[63:0] stvec,
        output[63:0] sepc_o,
        output[63:0] satp_o
       );

reg[63:0] CSR [0:7];
reg[63:0] CSR_old [0:7];

// The standard RISC-V ISA sets aside a 12-bit encoding space (csr[11:0]) for CSRs.
// In order to run our system, the following Supervisor-level CSRs need to be implemented:
// - sstatus(0x100)   supervisor status register                        -> used for configuring                   [0]
// - stvec(0x105)     supervisor trap handler base address              -> used for all trap                      [1]
// - sscratch(0x140)  scratch register for supervisor trap handler      -> used for U-mode and S-mode switching   [2]
// - sepc(0x141)      supervisor exception program counter              -> used for all trap                      [3]
// - scause(0x142)    supervisor trap cause                             -> used for all trap                      [4]
// - stval(0x143)     supervisor bad address or instruction             -> used for demand paging                 [5]
// - satp(0x180)      supervisor address translation and protection     -> used for virtual address translation   [6]
// - ...

// Do address mapping
wire[2:0] raddr_map   = (raddr == 12'h100) ? 3'h0 :
                        (raddr == 12'h105) ? 3'h1 :
                        (raddr == 12'h140) ? 3'h2 :
                        (raddr == 12'h141) ? 3'h3 :
                        (raddr == 12'h142) ? 3'h4 :
                        (raddr == 12'h143) ? 3'h5 :
                        (raddr == 12'h180) ? 3'h6 : 3'h7;
wire raddr_valid = (raddr_map != 3'h7);
wire[2:0] waddr_map   = (waddr == 12'h100) ? 3'h0 :
                        (waddr == 12'h105) ? 3'h1 :
                        (waddr == 12'h140) ? 3'h2 :
                        (waddr == 12'h141) ? 3'h3 :
                        (waddr == 12'h142) ? 3'h4 :
                        (waddr == 12'h143) ? 3'h5 :
                        (waddr == 12'h180) ? 3'h6 : 3'h7;
wire waddr_valid = (waddr_map != 3'h7);

// TODO:
// The SIE(sstatus[1]) bit enables or disables all interrupts in supervisor mode. 
// When SIE is clear, interrupts are not taken while in supervisor mode. 
// When the hart is running in user-mode, the value in SIE is ignored, and supervisor-level interrupts are enabled. 
//
// The SPIE(sstatus[5]) bit indicates whether supervisor interrupts were enabled prior to trapping into supervisor mode. 
// When a trap is taken into supervisor mode, SPIE is set to SIE, and SIE is set to 0. 
// When an SRET instruction is executed, SIE is set to SPIE, then SPIE is set to 1.
// 
// The SPP(sstatus[8]) bit indicates the privilege level at which a hart was executing before entering supervisor mode. 
// When a trap is taken, SPP is set to 0 if the trap originated from user mode, or 1 otherwise. 
// When an SRET instruction is executed to return from the trap handler, 
// the privilege level is set to user mode if the SPP bit is 0, or supervisor mode if the SPP bit is 1; SPP is then set to 0.
assign sstatus = CSR_old[0];

assign stvec  = CSR_old[1];
assign sepc_o = CSR_old[3];
assign satp_o = CSR_old[6];

always@(posedge clk) begin              // 在每个时钟周期开始时，备份所有CSR寄存器作为旧值
    CSR_old[0] <= CSR[0];
    CSR_old[1] <= CSR[1];
    CSR_old[2] <= CSR[2];
    CSR_old[3] <= CSR[3];
    CSR_old[4] <= CSR[4];
    CSR_old[5] <= CSR[5];
    CSR_old[6] <= CSR[6];
    CSR_old[7] <= CSR[7];
end

assign rdata = CSR_old[waddr_map];      // CSRR[W/S/C](i) should read the ORIGINAL CSR value, not the modified one

always@(negedge clk or posedge rst)
  begin
    if (rst)
      begin
        CSR[0] <= 0;
        CSR[1] <= 0;
        CSR[2] <= 0;
        CSR[3] <= 0;
        CSR[4] <= 0;
        CSR[5] <= 0;
        CSR[6] <= 0;
        CSR[7] <= 0;
      end
    else if (csr_w)
      begin
        case(csr_wsc_mode)
          2'b01:
            CSR[waddr_map] <= wdata;
          2'b10:
            CSR[waddr_map] <= CSR[waddr_map] | wdata;
          2'b11:
            CSR[waddr_map] <= CSR[waddr_map] & ~wdata;
          default:
            CSR[waddr_map] <= wdata;
        endcase
      end
    else if (is_trap)
      begin
        CSR[3] <= sepc;
        CSR[4] <= scause;
        CSR[5] <= stval;
        // TODO: set SIE, SPP, SPIE of sstatus
      end
    else if (is_sret)
      begin
        CSR[3] <= sepc;
        CSR[4] <= scause;
        CSR[5] <= stval;
        // TODO: set SIE, SPP, SPIE of sstatus
      end
  end
endmodule