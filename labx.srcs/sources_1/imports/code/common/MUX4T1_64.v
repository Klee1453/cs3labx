module MUX4T1_64(
    input [1:0]s,
    input [63:0]I0, I1, I2, I3,
    output [63:0]o
    );

    wire s0 = s == 2'b00;
    wire s1 = s == 2'b01;
    wire s2 = s == 2'b10;
    wire s3 = s == 2'b11;
    
    assign o =  {64{s0}} & I0 |
                {64{s1}} & I1 |
                {64{s2}} & I2 |
                {64{s3}} & I3 ;
endmodule