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
// ע�⵽32λϵͳ��, ÿ��ָ��ռ4���ֽ�, ���ڵ�����ָ��ĵ�ַΪpc, pc+4
// �ٿ��ǵ�ϵͳ��Ҫ���еĴ���������, ��˴���PC[9:2]��Ϊ��ǰָ��ĵ�ַPC_IF
// ����BHT��BTB, Ϊ�˽�ʡ�Ĵ���������, ʹ�ù�ϣ�����ݽṹ, ��PC[9:2]ȡ��32��ģ
// �������Խ�ʡ�ܵļĴ����Ĺ�ģ, ��Ϊ��Tagʵ������Ϊ��Ѱַ�õĵ�ַ

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
    
    input [7:0]PC_Branch,       /* ʵ�����ǵ�ǰPC */
    input [6:0]opcode_IF,       /* IF�ε�(��ǰPC��Ӧ��)ָ���opcode ���opcode������תָ�� �򲻽���Ԥ�� ���޸�BHT BTB */
    output taken,               /* ��������mux_IF_predict��Ϊѡ���ź� */
    output [7:0]PC_to_take,     /* IF��Ԥ����ת�ĵ�ַ, ��������mux_IF_predict��Ϊ��ת��õ�next_pc_IF */
    
    input J,                    /* ID��ָ���Ƿ�Ϊ��תָ�� */   
    input Branch_ID,            /* ID���ж�ID��ָ���Ƿ���ת */
    input [7:0]PC_to_branch,    /* ID���жϵ���תPC */
    output refetch              /* ��������HazzardDectectionUnit�Լ�mux_IF, ����ȡָ */
    );

    wire isJB_IF;   //IF��ָ���Ƿ�����תָ��(J-type or B-type)
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
     // �����Ƿ�ȷʵ��Ҫ��ת���ж��ź���ID�׶β�������, 
     // ��˶�BHT/BTB�ĸ���λ����һʱ������(��һ��λ�ô�, �����ܾ����ܼ���taken�ź����ɵ����±��ʱ���)
    reg [1:0]BHT_predictBit [31:0];
    reg [7:0]BTB_predictedPC [31:0];
    reg [7:0]BTB_PCindex [31:0];        // ����Ԥ����Ϣ֮ǰ, �ȶ�BTB�е���ת��ַ��ӦPC�Ƿ���ĿǰPCһ��
                                        // ע��, ����ж�������ĳЩ��ı�ָ���ĳ�������Ч��
    wire [4:0]PC_IF_hash = PC_Branch[4:0];

//    ��taken�Ļ������
//    reg [1:0]predictBit_buffer;     // Ԥ��λ�Ļ�����, ����������һ���ڵ�predictBit
//    reg [1:0]prev_predictBit;       // ��һ���ڵ�predictBit
    reg prev_taken;             // ����taken�ź�
    reg [7:0]PC_IF_buffer;      // PC_IF_hash������, ����������һ����PC_IFֵ
    reg [7:0]prev_PC_IF;        // ��һ����PC_IF_hashֵ
    reg prev_refetch;           // ����refetch�ź�
    wire [4:0]prev_PC_hash = prev_PC_IF[4:0];
    
    reg [7:0]prev_PC_to_take;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
//            prev_predictBit <= 2'b0;
            PC_IF_buffer <= 8'b0;
            prev_PC_IF <= 8'b0;
            prev_taken <= 1'b0;
            prev_refetch <= 1'b0;
            prev_PC_to_take <= 8'b0;
        end
        else begin
            prev_refetch <= refetch;                // ��һ�п�ʼ֮ǰ, ���滹û�б��ı����(�ϸ�ʱ���������ʱ�̵�)refetch�ź�
            prev_taken <= taken;                    // ��һ�п�ʼ֮ǰ�� ���滹û�б��ı����(�ϸ�ʱ���������ʱ�̵�)taken
//            prev_predictBit <= predictBit_buffer;   // ������һ���ڵ�predictBit
            prev_PC_IF <= PC_IF_buffer;         // ������һ���ڵ�PC_IF���ڸ��±�
            prev_PC_to_take <= PC_to_take;      // ��һ���ڵ�PC_to_take��������refetch
        end
    end
      
    // ����߼�, ��ȡBTB��BHT, ����refetch
    wire [1:0]curr_predictBit = BHT_predictBit[PC_IF_hash];
    
    // ���hash��ײ
    wire hashCollision = (prev_PC_IF != BTB_PCindex[prev_PC_hash]);
    
    // ʱ���߼�, ����BTB��BHT
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
            PC_IF_buffer <= PC_Branch;    // 1. ��clk�½��ر���PC_IF��buffer
            // 2. �����һ��ָ������תָ��(ID�׶����ɵ�J�ź�) ����һ�������PC_IF����BHT)
            // ���PC_IF�����仯(hash��ײ����), ������Ԥ��λ
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
                // 3.�����������, ֻҪ������ת, ����BTB
                if (Branch_ID) begin
                    BTB_predictedPC[prev_PC_hash] <= PC_to_branch;
                    BTB_PCindex[prev_PC_hash] <= prev_PC_IF;
                end
            end
//            // 4.ȡ�����ڵ�predictBit���浽buffer
//            predictBit_buffer <= curr_predictBit;
        end
    end

    // ����߼�, ��ȡBTB��BHT, ����refetch
    assign taken = isJB_IF ? (hashCollision ? 1'b0 : curr_predictBit[1]) : 1'b0;
    assign PC_to_take = isJB_IF ? (hashCollision ? 1'b0 : BTB_predictedPC[PC_IF_hash]) : 8'b0;    
    
    // �����ǰ����IF�ε�ָ����Ҫrefetch����ô��һ��������Ҫ�������ָ�������ģ���У�����������Ӱ��
    // ��ǰID��ΪJ/Bָ��, ������һ����Ԥ�����ת��ַ����һ����ID������Ĳ�һ��, Ҳ��Ҫrefeth ��Ҫ��Ϊ�˸���jalrԤ����תʵ����ת����ת��ַ���ڼĴ����仯����������

    wire jalr_err = ((prev_PC_to_take != PC_to_branch) && J && prev_taken);
    wire predict_err = prev_taken ^ Branch_ID;
    assign refetch = prev_refetch ? 1'b0 : (jalr_err || predict_err);    

    // ���ݾ����ĵȴ���û�п�������, �����������ݾ������ж���refetch�ź��޹�, ������Ҳ�������������, ����ƾ���(����refetch�ź�)��ͬ.
    // Ҳ����˵, ���е����ݾ�����Ҫ��stall��ָ���refetch���������ɲ�������ӦӰ��
    // ���ƺ��ᵼ��useָ��Ϊ��תָ��ʱ, ��ת����ȷ, Ȼ������֤���������ᵼ�·�Ԥ�ڵĴ���
    // ��Ϊ�������loadָ����useָ��Ϊ��תָ�� ��Ҫstall���ź�����תָ��λ��ID��ʱ����
    // ��ʱ�����ID�ε���תָ��Ŀ����ź� Branch_ID == 0
    // �����תָ����IF��ʱԤ����ת, ��ôrefetch��Ϊ1
    // ��һ������IF�ε�PC��Ϊ��תָ����ID���������Ŀ��ָ��, ��תָ��Ԥ���Ŀ��ָ��(��ǰIF��ָ��)���ᱻ��Ч��.
    // ��һ���棬 �������ݾ����Ĵ���, ��һ����ID����ȻΪ��תָ��
    // ����, ����refetchΪ1, ��һ����λ��ID��(stall�����תָ��)��ָ����Զ��������predict_err = 1���ź�
    // ����, jalr_err�ź���Ȼ����ȷ����, (������������prev_taken������)����stall�����תָ��refetch�ź����ɱ�Ӱ��Ĵ���! ��������!
    // ��һ����, ����Ԥ�ⲻ����ת, ��ôrefetch��Ϊ0, ��Ͳ��ᵼ��predict_err��ǿ��Ϊ0������
    
endmodule
