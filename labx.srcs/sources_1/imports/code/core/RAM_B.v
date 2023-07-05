`timescale 1ns / 1ps

/* module MMU
Now we need to add mmu module into ram(in this way mmu is a blackbox is easy to implement va->pa)
what we need:
input  [63:0]   va_addr             virtual address
input  [63:0]   va_data
input  [63:0]   satp                satp's value

output [63:0]   pa_addr
output [63:0]   pa_data             physical address
output          page_fault_addr     whether pa is found(0) or nor(1)
output          page_fault_data
*/

/*module RAM_B
in this module we need to talk about the size of RAM 
    - RAM doesn't need to initial or (initial to 0)
    - RAM is small, that is, only the kalloc()'s page use RAM, we need to find how many page is use(once one page is still 4KB bytes)
one page 0x4000 -> 0x1000 insts
                -> 0x800  PTE
the kalloc() is allocate start at 0x0088 0000 and once 0x0000 1000 size             
    - setup_vm --> 1 page       2   1   0
    - setup_vm_final -------->  1   2    
*/

module MMU(
    input           rst,                                    //reset
    input           clka,                                   //normal clock clock
                                                            //[MEM]
    input           wea,                                    //enable
    input    [63:0] addra,                                  //address change to 64
    input    [63:0] dina,                                   //data change to 64
    input    [2:0]  mem_u_b_h_w,                            //flag to show    u   b   h   w   d    
    input    [63:0] satp,                                   //satp
                                                            //[MEM]
    output          ram_page_fault,                         //load/store page fault
    output   [63:0] douta,                                  //change to 64  output
                                                            //[MEM]
    output   [7:0]  sim_uart_char_out,                      //serial
    output          sim_uart_char_valid,                    //for serial usage
                                                            //[IF]
    input    [63:0] PC_va,                                  //input  pc(va)
    output   [63:0] PC_pa,                                  //output pc(pa)
    output          inst_page_fault                         //inst page fault
);

    localparam SIZE = 21'h100000;                           //Set Total Size
    localparam ADDR_LINE = 20;                              //need to change        with SIZE   具体意义即为addra中的低line位，代表真正的地址  因为size有限，只有低line位的地址有效
    localparam SIM_UART_ADDR = 32'h10000000;                //need to change with line 

    reg[7:0] data[0:SIZE-1];                                //the real data stored in Ram

    initial	begin
        $readmemh("D:\\Office\\2023.3-2023.7\\ComputingSystemsIII\\labx\\test\\kernel\\kernel15.hex_output.hex", data);
    end

    wire [63:0]addr_pa,m_final_pa,p_final_pa;
    wire m_final_page_fault,p_final_page_fault;
    wire [56:0]pgtbl2;
    wire [3:0]mode;
    wire [11:0]m_vpn2,m_vpn1,m_vpn0;
    wire [63:0]PC_va_t;
    assign PC_va_t = PC_va;
    
    wire [63:0]m_va_t;
    assign m_va_t = addra;
    assign pgtbl2 = {satp[43:0],12'b0};
    assign mode = satp[63:60];
    assign m_vpn2 = {3'b0,(m_va_t[38:30]) * 8},
           m_vpn1 = {3'b0,m_va_t[29:21] * 8},
           m_vpn0 = {3'b0,m_va_t[20:12] * 8};
    
    wire [11:0]p_vpn2,p_vpn1,p_vpn0;
    assign p_vpn2 = {3'b0,(PC_va_t[38:30]) * 8},
           p_vpn1 = {3'b0,PC_va_t[29:21] * 8},
           p_vpn0 = {3'b0,PC_va_t[20:12] * 8};
    //this part is used to get pa
    wire [63:0]p_pg;
    wire [56:0]p_pgtbl1,p_pgtbl0;
    wire [1:0]p_value2,p_value1,p_value0;           //where R|W|X and V
    wire [63:0]p_pte2,p_pte1,p_pte0;
    //
    assign p_pte2 = {data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+7],data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+6],data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+5],data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+4],data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+3],data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+2],data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+1],data[{pgtbl2[ADDR_LINE-1:12],p_vpn2}+0]};
    assign p_value2 = {(p_pte2[1:1] | p_pte2[2:2] | p_pte2[3:3]),p_pte2[0:0]};
    assign p_pgtbl1 = {p_pte2[53:10] , 12'b0};
    //
    assign p_pte1 = {data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+7],data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+6],data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+5],data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+4],data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+3],data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+2],data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+1],data[{p_pgtbl1[ADDR_LINE-1:12],p_vpn1}+0]};
    assign p_value1 = {(p_pte1[1:1] | p_pte1[2:2] | p_pte1[3:3]),p_pte1[0:0]};
    assign p_pgtbl0 = {p_pte1[53:10] , 12'b0};
    //
    assign p_pte0 = {data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+7],data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+6],data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+5],data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+4],data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+3],data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+2],data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+1],data[{p_pgtbl0[ADDR_LINE-1:12],p_vpn0}+0]};
    assign p_value0 = {(p_pte0[1:1] | p_pte0[2:2] | p_pte0[3:3]),p_pte0[0:0]};
    assign p_pg = {p_pte0[53:10] , 12'b0};
    //
    assign p_final_page_fault = (!p_value2[0:0]) | ((!p_value2[1:1])&(p_value2[0:0])&(!p_value1[0:0])) | ((!p_value2[1:1])&(p_value2[0:0])&(!p_value1[1:1])&(p_value1[0:0])&(!p_value0[0:0]));
    //                          根无效          根非页且有效且当前无效                                   根非页且有效 1非页且有效 0无效
    assign p_final_pa =  (p_value2[0:0]&(p_value2[1:1]))?({8'b0,p_pte2[53:28],PC_va_t[29:0]}):                                                     //根页表有效且根页表为叶子
                    ((p_value2[0:0])&(!p_value2[1:1])&(p_value1[1:1])&(p_value1[0:0]))?({8'b0,p_pte1[53:19],PC_va_t[20:0]}):                  //根节点有效 �? 根节点不为叶�? �? 1有效 �? 1叶子
                    ((p_value2[0:0])&(!p_value2[1:1])&(!p_value1[1:1])&(p_value1[0:0])&(p_value0[0:0]))?{8'b00,p_pte0[53:0],PC_va_t[11:0]}:   //根节点有效 �? 根节点不为叶�? �? 1有效 �? 1不为叶子 �? 0有效
                    64'b0;          //否则就是无效访问，直接设置为0即可�?
                        
    assign PC_pa = (mode == 4'b0)? PC_va : (p_final_pa);
    assign inst_page_fault = (mode == 4'b0)? 0 : p_final_page_fault;

    wire [63:0]m_pg;
    wire [56:0]m_pgtbl1,m_pgtbl0;
    wire [1:0]m_value2,m_value1,m_value0;           //where R|W|X and V
    wire [63:0]m_pte2,m_pte1,m_pte0;
    //
    assign m_pte2 = {data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+7],data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+6],data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+5],data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+4],data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+3],data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+2],data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+1],data[{pgtbl2[ADDR_LINE-1:12],m_vpn2}+0]};
    assign m_value2 = {(m_pte2[1:1] | m_pte2[2:2] | m_pte2[3:3]),m_pte2[0:0]};
    assign m_pgtbl1 = {m_pte2[53:10] , 12'b0};
    //
    assign m_pte1 = {data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+7],data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+6],data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+5],data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+4],data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+3],data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+2],data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+1],data[{m_pgtbl1[ADDR_LINE-1:12],m_vpn1}+0]};
    assign m_value1 = {(m_pte1[1:1] | m_pte1[2:2] | m_pte1[3:3]),m_pte1[0:0]};
    assign m_pgtbl0 = {m_pte1[53:10] , 12'b0};
    //
    assign m_pte0 = {data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+7],data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+6],data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+5],data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+4],data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+3],data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+2],data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+1],data[{m_pgtbl0[ADDR_LINE-1:12],m_vpn0}+0]};
    assign m_value0 = {(m_pte0[1:1] | m_pte0[2:2] | m_pte0[3:3]),m_pte0[0:0]};
    assign m_pg = {m_pte0[53:10] , 12'b0};
    //
    assign m_final_page_fault = (!m_value2[0:0]) | ((!m_value2[1:1])&(m_value2[0:0])&(!m_value1[0:0])) | ((!m_value2[1:1])&(m_value2[0:0])&(!m_value1[1:1])&(m_value1[0:0])&(!m_value0[0:0]));
    //                          根无效          根非页且有效且当前无效                                   根非页且有效 1非页且有效 0无效
    assign m_final_pa =  (m_value2[0:0]&(m_value2[1:1]))?({8'b0,m_pte2[53:28],m_va_t[29:0]}):                                                     //根页表有效且根页表为叶子
                    ((m_value2[0:0])&(!m_value2[1:1])&(m_value1[1:1])&(m_value1[0:0]))?({8'b0,m_pte1[53:19],m_va_t[20:0]}):                  //根节点有效 �? 根节点不为叶�? �? 1有效 �? 1叶子
                    ((m_value2[0:0])&(!m_value2[1:1])&(!m_value1[1:1])&(m_value1[0:0])&(m_value0[0:0]))?{8'b0 , m_pte0[53:0] , m_va_t[11:0]}:   //根节点有效 �? 根节点不为叶�? �? 1有效 �? 1不为叶子 �? 0有效
                    64'b0;          //否则就是无效访问，直接设置为0即可�?
    //              

    assign addr_pa = (mode == 4'b0)? addra : (m_final_pa);
    assign ram_page_fault = (mode == 4'b0)? 0 : m_final_page_fault;

    wire   new_clk;
    assign new_clk = ! clka;
    integer i;
    always @ (posedge new_clk or posedge rst) begin
        if(rst) begin
            for (i = 21'd9000; i< 21'h100000; i = i + 1) data[i] <= 0;
        end        
        else begin
            if (wea & (addr_pa != SIM_UART_ADDR)) begin
                //first byte
                data[addr_pa[ADDR_LINE-1:0]] <= dina[7:0];
                //then half word 2 - 1
                if(mem_u_b_h_w[0] | mem_u_b_h_w[1])
                    data[addr_pa[ADDR_LINE-1:0] + 1] <= dina[15:8];
                //then word 4 - 2 
                if(mem_u_b_h_w[1]) begin
                    data[addr_pa[ADDR_LINE-1:0] + 2] <= dina[23:16];
                    data[addr_pa[ADDR_LINE-1:0] + 3] <= dina[31:24];
                end
                //then double word 8 - 4
                if(mem_u_b_h_w[0] & mem_u_b_h_w[1]) begin
                    data[addr_pa[ADDR_LINE-1:0] + 4] <= dina[39:32];
                    data[addr_pa[ADDR_LINE-1:0] + 5] <= dina[47:40];
                    data[addr_pa[ADDR_LINE-1:0] + 6] <= dina[55:48];
                    data[addr_pa[ADDR_LINE-1:0] + 7] <= dina[63:56];
                end
            end
        end
    end
    
    //load -> u_b_h_w need to talk again
    //      
    assign douta = addr_pa == SIM_UART_ADDR ? 64'b0 :
        //ld  don't need to think about sign        64'b data
        mem_u_b_h_w[1:0] == 2'b11 ? {data[addr_pa[ADDR_LINE-1:0] + 7], data[addr_pa[ADDR_LINE-1:0] + 6], data[addr_pa[ADDR_LINE-1:0] + 5], data[addr_pa[ADDR_LINE-1:0] +4], data[addr_pa[ADDR_LINE-1:0] + 3], data[addr_pa[ADDR_LINE-1:0] + 2], data[addr_pa[ADDR_LINE-1:0] + 1], data[addr_pa[ADDR_LINE-1:0]]}:
        //lw    need to think about sign            32'b(1/0) + 32'b data
        mem_u_b_h_w[1:0] == 2'b10 ? {mem_u_b_h_w[2] ? 32'b0 : {32{data[addr_pa[ADDR_LINE-1:0] + 3][7]}}, data[addr_pa[ADDR_LINE-1:0] + 3], data[addr_pa[ADDR_LINE-1:0] + 2], data[addr_pa[ADDR_LINE-1:0] + 1], data[addr_pa[ADDR_LINE-1:0]]} :
        //lh
        mem_u_b_h_w[1:0] == 2'b01 ? {mem_u_b_h_w[2] ? 48'b0 : {48{data[addr_pa[ADDR_LINE-1:0] + 1][7]}}, data[addr_pa[ADDR_LINE-1:0] + 1], data[addr_pa[ADDR_LINE-1:0]]} :
        //lb
        mem_u_b_h_w[1:0] == 2'b00 ? {(mem_u_b_h_w[2] ? 56'b0: {56{data[addr_pa[ADDR_LINE-1:0]][7]}}), data[addr_pa[ADDR_LINE-1:0]]} : 64'b0;

    
    //this part is used for output
    reg uart_addr_valid;
    reg [7:0] uart_char;
    initial begin
        uart_addr_valid <= 0;
    end
    assign sim_uart_char_valid = uart_addr_valid;
    assign sim_uart_char_out   = uart_char;
    always @(posedge clka) begin
        uart_addr_valid <= wea & (addr_pa == SIM_UART_ADDR | addra == SIM_UART_ADDR);
        uart_char <= dina[7:0];
        if (sim_uart_char_valid) begin
            $write("%c", sim_uart_char_out);
        end
    end
endmodule











module RAM_B(
    input [31:0] addra,
    input clka,      // normal clock
    input[31:0] dina,
    input wea, 
    output[63:0] douta,
    output [7:0] sim_uart_char_out,
    output sim_uart_char_valid,
    input[2:0] mem_u_b_h_w,
    output l_access_fault, s_access_fault
);
    localparam SIZE = 256;
    //localparam ADDR_LINE = $clog2(SIZE);
    localparam ADDR_LINE = 8;
    localparam SIM_UART_ADDR = 32'h10000000;

    reg[7:0] data[0:SIZE-1];

    initial	begin
        $readmemh("D:\\Office\\2023.3-2023.7\\ComputingSystemsIII\\Lab1\\src\\lab1\\lab1.sim\\sim_1\\behav\\xsim\\ram.hex", data);
    end

    always @ (negedge clka) begin
        if (wea & (addra != SIM_UART_ADDR)) begin
            data[addra[ADDR_LINE-1:0]] <= dina[7:0];
            if(mem_u_b_h_w[0] | mem_u_b_h_w[1])
                data[addra[ADDR_LINE-1:0] + 1] <= dina[15:8];
            if(mem_u_b_h_w[1]) begin
                data[addra[ADDR_LINE-1:0] + 2] <= dina[23:16];
                data[addra[ADDR_LINE-1:0] + 3] <= dina[31:24];
            end
        end
    end

    wire [31:0] douta_32;
    assign douta_32 = addra == SIM_UART_ADDR ? 32'b0 :
        mem_u_b_h_w[1] ? {data[addra[ADDR_LINE-1:0] + 3], data[addra[ADDR_LINE-1:0] + 2],
                    data[addra[ADDR_LINE-1:0] + 1], data[addra[ADDR_LINE-1:0]]} :
        mem_u_b_h_w[0] ? {mem_u_b_h_w[2] ? 16'b0 : {16{data[addra[ADDR_LINE-1:0] + 1][7]}},
                    data[addra[ADDR_LINE-1:0] + 1], data[addra[ADDR_LINE-1:0]]} :
        {mem_u_b_h_w[2] ? 24'b0 : {24{data[addra[ADDR_LINE-1:0]][7]}}, data[addra[ADDR_LINE-1:0]]};
    assign douta = {{32{douta_32[31]}}, douta_32};

    reg uart_addr_valid;
    reg [7:0] uart_char;
    initial begin
        uart_addr_valid <= 0;
    end
    assign sim_uart_char_valid = uart_addr_valid;
    assign sim_uart_char_out   = uart_char;
    always @(posedge clka) begin
        uart_addr_valid <= wea & (addra == SIM_UART_ADDR);
        uart_char <= dina[7:0];
        if (sim_uart_char_valid) begin
            $write("%c", sim_uart_char_out);
        end
    end

   assign l_access_fault = 0;
   assign s_access_fault = 0;
endmodule