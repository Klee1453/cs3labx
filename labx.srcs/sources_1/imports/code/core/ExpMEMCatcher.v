`timescale 1ns / 1ps

module ExpMEMCatcher(
                                            // [MEM]
        input  ram_page_fault,
        output reg_EM_flush, reg_DE_flush, reg_FD_flush
);

// reg RegWrite_cancel_, reg_MW_flush_;
reg reg_EM_flush_, reg_DE_flush_, reg_FD_flush_;

// 捕捉到访存异常的时刻flush FD DE EM，异常处理需要等到该指令流入WB段
always @ (*)
begin
    if (ram_page_fault)
    begin
        reg_FD_flush_ <= 1;
        reg_DE_flush_ <= 1;
        reg_EM_flush_ <= 1;
        // reg_MW_flush_ <= 1;
        // RegWrite_cancel_ <= 1;
    end
    else
    begin
        reg_FD_flush_ <= 0;
        reg_DE_flush_ <= 0;
        reg_EM_flush_ <= 0;
        // reg_MW_flush_ <= 0;
        // RegWrite_cancel_ <= 0;
    end
end

assign reg_FD_flush = reg_FD_flush_;
assign reg_DE_flush = reg_DE_flush_;
assign reg_EM_flush = reg_EM_flush_;

endmodule