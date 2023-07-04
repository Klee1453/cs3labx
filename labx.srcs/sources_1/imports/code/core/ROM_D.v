`timescale 1ns / 1ps

module ROM_D(
    input[7:0] a,
    output[31:0] spo
);

    reg[31:0] inst_data[0:255];

    initial	begin
        $readmemh("D:\\Office\\2023.3-2023.7\\ComputingSystemsIII\\labx\\test\\exp\\exp.hex", inst_data);
    end

    assign spo = inst_data[a];

endmodule