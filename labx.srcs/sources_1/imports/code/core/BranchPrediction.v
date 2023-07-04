`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/26 16:20:18
// Design Name: 
// Module Name: BranchPrediction
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 注意到32位系统中, 每条指令占4个字节, 相邻的两条指令的地址为pc, pc+4
// 再考虑到系统需要运行的代码量有限, 因此传入PC[9:2]作为当前指令的地址PC_IF
// 对于BHT与BTB, 为了节省寄存器的数量, 使用哈希表数据结构, 对PC[9:2]取对32的模
// 这样可以节省总的寄存器的规模, 因为域Tag实际上作为了寻址用的地址

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Branch_Prediction branch_prediction(
//         .clk(debug_clk),
//         .rst(rst),
 
//         .PC_Branch(PC_IF[9:2]),
//         .taken(taken),
//         .PC_to_take(pc_to_take),
 
//         .J(j),
//         .Branch_ID(Branch_ctrl),
//         .PC_to_branch(jump_PC_ID[9:2]),
//         .refetch(refetch)
//        );


module Branch_Prediction(
    input clk,
    input rst,
    
    input [7:0]PC_Branch,       /* 实际上是当前PC */
    input [6:0]opcode_IF,       /* IF段的(当前PC对应的)指令的opcode 如果opcode不是跳转指令 则不进行预测 不修改BHT BTB */
    output taken,               /* 数据流向mux_IF_predict作为选择信号 */
    output [7:0]PC_to_take,     /* IF段预测跳转的地址, 数据流向mux_IF_predict作为跳转后得到next_pc_IF */
    
    input J,                    /* ID段指令是否为跳转指令 */   
    input Branch_ID,            /* ID段判断ID段指令是否跳转 */
    input [7:0]PC_to_branch,    /* ID段判断的跳转PC */
    output refetch              /* 数据流向HazzardDectectionUnit以及mux_IF, 重新取指 */
    );

    wire isJB_IF;   //IF段指令是否是跳转指令(J-type or B-type)
    assign isJB_IF = (opcode_IF == 7'b1100011) ? 1'b1 : 
                     (opcode_IF == 7'b1101111) ? 1'b1 :
                     (opcode_IF == 7'b1100111) ? 1'b1 : 1'b0;

     // BHT::predictBits
     // 00 -(taken)->       01  (00 predict not taken)
     // 00 -(not taken)->   00  (00 predict not taken)
     // 01 -(taken)->       11  (01 predict not taken)
     // 01 -(not taken)->   00  (01 predict not taken)
     // 11 -(taken)->       11  (11 predict taken)
     // 11 -(not taken)->   10  (11 predict taken)
     // 10 -(taken)->       11  (10 predict taken)
     // 10 -(not taken)->   00  (10 predict taken)
     // 对于是否确实需要跳转的判断信号在ID阶段才能生成, 
     // 因此对BHT/BTB的更新位于下一时钟周期(的一半位置处, 这样能尽可能减少taken信号生成到更新表的时间差)
    reg [1:0]BHT_predictBit [31:0];
    reg [7:0]BTB_predictedPC [31:0];
    reg [7:0]BTB_PCindex [31:0];        // 生成预测信息之前, 比对BTB中的跳转地址对应PC是否与目前PC一致
                                        // 注意, 这个判定方法对某些会改变指令本身的程序是无效的
    wire [4:0]PC_IF_hash = PC_Branch[4:0];

//  被taken的缓冲代替
//  reg [1:0]predictBit_buffer; // 预测位的缓冲区, 用于生成上一周期的predictBit
//  reg [1:0]prev_predictBit;   // 上一周期的predictBit
    reg prev_taken;             // 缓冲taken信号
    reg [7:0]PC_IF_buffer;      // PC_IF_hash缓冲区, 用于生成上一周期PC_IF值
    reg [7:0]prev_PC_IF;        // 上一周期PC_IF_hash值
    reg prev_refetch;           // 缓冲refetch信号
    wire [4:0]prev_PC_hash = prev_PC_IF[4:0];
    
    reg [7:0]prev_PC_to_take;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
//          prev_predictBit <= 2'b0;
            PC_IF_buffer <= 8'b0;
            prev_PC_IF <= 8'b0;
            prev_taken <= 1'b0;
            prev_refetch <= 1'b0;
            prev_PC_to_take <= 8'b0;
        end
        else begin
            prev_refetch <= refetch;                // 在一切开始之前, 缓存还没有被改变过的(上个时钟周期最后时刻的)refetch信号
            prev_taken <= taken;                    // 在一切开始之前， 缓存还没有被改变过的(上个时钟周期最后时刻的)taken
//          prev_predictBit <= predictBit_buffer;   // 生成上一周期的predictBit
            prev_PC_IF <= PC_IF_buffer;         // 生成上一周期的PC_IF用于更新表
            prev_PC_to_take <= PC_to_take;      // 上一周期的PC_to_take用于生成refetch
        end
    end
      
    // 组合逻辑, 读取BTB和BHT, 生成refetch
    wire [1:0]curr_predictBit = BHT_predictBit[PC_IF_hash];
    
    // 检测hash碰撞
    wire hashCollision = (prev_PC_IF != BTB_PCindex[prev_PC_hash]);
    
    // 时序逻辑, 更新BTB和BHT
    integer i;
    always @ (negedge clk or posedge rst) begin
        if (rst) begin  // reset BHT and BTB
            for(i = 0; i < 32; i = i + 1) begin
                BHT_predictBit[i] <= 2'b0;
                BTB_predictedPC[i] <= 8'b0;
                BTB_PCindex[i] <= 8'b0;
            end
        end
        else begin
            PC_IF_buffer <= PC_Branch;    // 1. 在clk下降沿保存PC_IF到buffer
            // 2. 如果上一条指令是跳转指令(ID阶段生成的J信号) 用上一轮流入的PC_IF更新BHT)
            // 如果PC_IF发生变化(hash碰撞发生), 先重置预测位
            if (hashCollision) begin BHT_predictBit[prev_PC_hash] <= 2'b00; end
            if (J) begin
                case (BHT_predictBit[prev_PC_hash])
                    2'b00: begin
                        if (Branch_ID) BHT_predictBit[prev_PC_hash] <= 2'b01;
                        else BHT_predictBit[prev_PC_hash] <= 2'b00;
                    end
                    2'b01: begin
                        if (Branch_ID) BHT_predictBit[prev_PC_hash] <= 2'b11;
                        else BHT_predictBit[prev_PC_hash] <= 2'b00;
                    end
                    2'b10: begin
                        if (Branch_ID) BHT_predictBit[prev_PC_hash] <= 2'b11;
                        else BHT_predictBit[prev_PC_hash] <= 2'b00;
                    end
                    2'b11: begin
                        if (Branch_ID) BHT_predictBit[prev_PC_hash] <= 2'b11;
                        else BHT_predictBit[prev_PC_hash] <= 2'b10;
                    end
                    default: BHT_predictBit[prev_PC_hash] <= 2'b00;
                endcase
                // 3.在所有情况下, 只要发生跳转, 更新BTB
                if (Branch_ID) begin
                    BTB_predictedPC[prev_PC_hash] <= PC_to_branch;
                    BTB_PCindex[prev_PC_hash] <= prev_PC_IF;
                end
            end
//            // 4.取本周期的predictBit保存到buffer
//            predictBit_buffer <= curr_predictBit;
        end
    end

    // 组合逻辑, 读取BTB和BHT, 生成refetch
    assign taken = isJB_IF ? (hashCollision ? 1'b0 : curr_predictBit[1]) : 1'b0;
    assign PC_to_take = isJB_IF ? (hashCollision ? 1'b0 : BTB_predictedPC[PC_IF_hash]) : 8'b0;    
    
    // 如果当前处于IF段的指令需要refetch，那么下一周期中需要清除这条指令在这个模块中（缓冲区）的影响
    // 当前ID段为J/B指令, 并且上一周期预测的跳转地址与这一周期ID段算出的不一致, 也需要refeth 主要是为了覆盖jalr预测跳转实际跳转而跳转地址由于寄存器变化而错误的情况

    wire jalr_err = ((prev_PC_to_take != PC_to_branch) && J && prev_taken);
    wire predict_err = prev_taken ^ Branch_ID;
    assign refetch = prev_refetch ? 1'b0 : (jalr_err || predict_err);    

    // 数据竞争的等待并没有考虑在内, 但是由于数据竞争的判定与refetch信号无关, 不考虑也并不会产生死锁, 与控制竞争(依赖refetch信号)不同.
    // 也就是说, 所有的数据竞争需要被stall的指令的refetch会正常生成并产生对应影响
    // 这似乎会导致use指令为跳转指令时, 跳转不正确, 然而可以证明它并不会导致非预期的错误
    // 因为假设紧随load指令后的use指令为跳转指令 需要stall的信号在跳转指令位于ID段时生成
    // 这时会清楚ID段的跳转指令的控制信号 Branch_ID == 0
    // 如果跳转指令在IF段时预测跳转, 那么refetch将为1
    // 下一周期中IF段的PC将为跳转指令在ID段中算出的目标指令, 跳转指令预测的目的指令(当前IF段指令)将会被无效化.
    // 另一方面， 由于数据竞争的处理, 下一周期ID段仍然为跳转指令
    // 但是, 由于refetch为1, 下一周期位于ID段(stall后的跳转指令)的指令永远不会生成predict_err = 1的信号
    // 但是, jalr_err信号仍然会正确运行, (并且由于满足prev_taken的条件)纠正stall后的跳转指令refetch信号生成被影响的错误! 真是神奇!
    // 另一方面, 假设预测不与跳转, 那么refetch将为0, 这就不会导致predict_err被强制为0的问题
    
endmodule
