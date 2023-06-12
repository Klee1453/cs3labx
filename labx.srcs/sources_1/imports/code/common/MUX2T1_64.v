module MUX2T1_64(input[63:0]I0,
				 input[63:0]I1,
				 input s,
				 output[63:0]o

    );
    assign o = s ? I1 : I0;
endmodule
