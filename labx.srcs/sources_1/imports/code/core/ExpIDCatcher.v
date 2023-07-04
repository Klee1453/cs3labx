`timescale 1ns / 1ps

module ExpIDCatcher(
                                            // [ID]
        input  sret,
        input  ecall,
        input  illegal_inst,                // TODO: handle illegal_inst
        output PC_EN_IF, reg_FD_stall, reg_DE_flush, reg_FD_flush
);

reg PC_EN_IF_, reg_FD_stall_, reg_DE_flush_, reg_FD_flush_;

// 捕捉到异常的时刻只需要做stall流水线的操作即可，异常处理需要等到该指令流入WB段
// 与load-use hazzard的处理不同，这里需要同时flush掉IF和ID的阶段间寄存器，因为我们不希望第二次取指令的异常指令执行两次
always @ (*)
begin
    if (sret | ecall | illegal_inst)
    begin
        PC_EN_IF_ <= 0;
        reg_FD_stall_ <= 0;
        reg_DE_flush_ <= 0;
        reg_FD_flush_ <= 1;
    end
    else
    begin
        PC_EN_IF_ <= 1;
        reg_FD_stall_ <= 0;
        reg_DE_flush_ <= 0;
        reg_FD_flush_ <= 0;
    end
end

assign PC_EN_IF = PC_EN_IF_;
assign reg_FD_stall = reg_FD_stall_;
assign reg_DE_flush = reg_DE_flush_;
assign reg_FD_flush = reg_FD_flush_;

endmodule