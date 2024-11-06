//增加新指令要做的事情：纳入ine，与异常有关则在ex�?后的阶段纳入exc,gr_we,mem_wet
 module id_stage(
input wire  clk,
input wire resetn,
input wire  [31:0] inst_i,
input wire  [31:0] pc_i,
input wire if_to_id_valid,
output wire id_to_ex_valid,
input wire ex_allowin,
output wire [11:0] alu_op,
output wire        res_from_mem,
output wire        gr_we,
output wire        mem_we,

output wire [4: 0] dest,

input wire         rf_we   ,
input wire [ 4:0]  rf_waddr,
input  wire [31:0] rf_wdata,
output wire [31:0] alu_src1,
output wire [31:0] alu_src2,
output wire        br_taken,
output wire [31:0] br_target,
output wire [31:0] rkd_value,
output wire [31:0] pc_o,
output wire id_allowin,

output wire none_dest,
input wire none_dest_ex,
input wire none_dest_wb,
input wire none_dest_mem,

input wire [4:0] dest_ex,
input wire [4:0] dest_mem,
input wire [4:0] dest_wb,

input wire wb_valid,
input wire ex_valid,
input wire mem_to_wb_valid,
output wire id_readygo,

input wire [31:0] ex_result,
input wire [31:0] mem_result,
input wire [31:0] wb_result,

input wire res_from_mem_ex,
input wire res_from_mem_mem,
output wire [2:0] mul_div_op,

output wire div_sign,
output wire [ 2:0] ld_type,
output wire [ 1:0] st_type,

input wire has_int,
output wire [1:0] csr_inst_type,
output wire [13 :0] csr_num,

input wire [1:0] csr_inst_type_ex,
input wire [1:0] csr_inst_type_mem,
input wire [1:0] csr_inst_type_wb,

output wire inst_ertn,
input wire inst_ertn_ex,
input wire inst_ertn_mem,
input wire inst_ertn_wb,
input wire flush,

output wire exc_sys_call,
input wire  exc_adef_i,
output wire exc_adef_o,
output wire exc_ine,
output wire exc_break,
output wire exc_int,
input wire csr_inst_judge_cf_ex,
input wire csr_inst_judge_cf_mem,
input wire csr_inst_judge_cf_wb,

output wire inst_rdcntvl_w,
output wire inst_rdcntvh_w,

output wire br_stall,
input wire mem_readygo,
input wire data_unfinished,

output wire [5:0] op_invtlb_id,//�?高位用于判别此时是否是invtlb指令
output wire [2:0] op_tlb,
//重取�?
output wire exc_refetch_o,
//renew
input wire exc_pif_i,
input wire exc_ppi_fetch_i,
input wire exc_tlbrentry_fetch_i,
output wire exc_pif_o,
output wire exc_ppi_fetch_o,
output wire exc_tlbrentry_fetch_o
    );
wire [31:0] inst;

wire        src1_is_pc;
wire        src2_is_imm;

wire        src_reg_is_rd;
wire [31:0] rj_value;
wire [31:0] imm;
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire        dst_is_r1;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;
wire [ 4:0] i5;//自己加的  

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

wire        need_ui5;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;
wire        need_si12_zero_extend;
wire        dst_is_rj;
wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

 wire        inst_add_w;
 wire        inst_sub_w;
 wire        inst_slt;
 wire        inst_sltu;
 wire        inst_nor;
 wire        inst_and;
 wire        inst_or;
 wire        inst_xor;
 wire        inst_slli_w;
 wire        inst_srli_w;
 wire        inst_srai_w;
 wire        inst_addi_w;
 wire        inst_ld_w;
 wire        inst_st_w;
 wire        inst_jirl;
 wire        inst_b;
 wire        inst_bl;
 wire        inst_beq;
 wire        inst_bne;
 wire        inst_lu12i_w;
 wire        inst_slti;
 wire        inst_sltui;
 wire        inst_andi;
 wire        inst_ori;    
 wire        inst_xori;   
 wire        inst_sll_w;   
 wire        inst_srl_w;   
 wire        inst_sra_w;   
 wire        inst_pcaddu12i;
 
 wire        inst_mul_w;
 wire        inst_mulh_w;
 wire        inst_mulh_wu;
 wire        inst_div_w;
 wire        inst_mod_w;
 wire        inst_div_wu;
 wire        inst_mod_wu;
 
 wire        inst_blt;
 wire        inst_bge;
 wire        inst_bltu;
 wire        inst_bgeu;
 wire        inst_ld_b;
 wire        inst_ld_h;
 wire        inst_ld_bu;
 wire        inst_ld_hu;
 wire        inst_st_b;
 wire        inst_st_h;
 
 wire        inst_csrrd;
 wire        inst_csrwr;
 wire        inst_csrxchg;
 wire        inst_syscall;
 wire        inst_break;
 
 wire        inst_rdcntid;
 
 wire        inst_tlbsrch;
 wire        inst_tlbrd;
 wire        inst_tlbwr;
 wire        inst_tlbfill;
 wire        inst_invtlb;
reg [31:0] inst_reg;
reg id_valid;

//exc reg
reg exc_adef_reg;
reg exc_pif_reg;
reg exc_ppi_fetch_reg;
reg exc_tlbrentry_fetch_reg;

wire none_src_reg;

wire r1_cf;          //cf==conflict
wire r2_cf;

reg delay_slot;

wire csr_cf;
//block
wire block;
assign block = !(if_to_id_valid && id_allowin);


always@(posedge clk)begin
    if(!resetn)
        delay_slot <= 1'b0;
    else if(br_taken) 
        delay_slot <= 1'b1;
    else if(if_to_id_valid & id_allowin)
        delay_slot <= 1'b0;
end
    
assign none_dest = inst_bne || inst_beq || inst_st_w || inst_b || inst_st_b || inst_st_h || inst_ertn
                    || inst_syscall || inst_break | inst_tlbsrch | inst_tlbrd | inst_tlbwr | inst_tlbfill
                    | inst_invtlb;//不写寄存器的指令
assign none_src_reg = inst_b || inst_bl || inst_lu12i_w || inst_csrrd //无源寄存器的指令
                   || inst_ertn || inst_syscall || inst_break || inst_rdcntid
                   || inst_rdcntvl_w || inst_rdcntvh_w | inst_tlbsrch | inst_tlbrd | inst_tlbwr | inst_tlbfill;
assign id_readygo =  (!(data_unfinished &  (((dest_mem == rf_raddr1)&& !none_dest_mem) |  ((dest_mem == rf_raddr2)&& !none_dest_mem))))//总线访存未取出指令的阻塞，属于下�?行的拓展
                &   ( !(res_from_mem_ex  & (ex_cf_r1 | ex_cf_r2))) //!res_from_mem_ex || res_from_mem_mem;//(!r1_cf) && (!r2_cf)__阻塞解决冲突版本; //可能关键
                &     !csr_cf       
                &     !(has_int && (csr_inst_judge_cf_ex | csr_inst_judge_cf_wb /////可以优化，实际上csr_inst_judge信号，包含了csrrd csrwr csrxchg,这里                                                                       
                             |  csr_inst_judge_cf_mem | inst_ertn_ex////只需要防止前面有wr xchg就行了（设计实战�?7.1�?
                             |  inst_ertn_wb | inst_ertn_mem));
                
wire ex_cf_r1;
wire mem_cf_r1;
wire wb_cf_r1;

wire ex_cf_r2;
wire mem_cf_r2;
wire wb_cf_r2;

wire ex_cf_csr_r1;
wire mem_cf_csr_r1;
wire wb_cf_csr_r1;

wire ex_cf_csr_r2;
wire mem_cf_csr_r2;
wire wb_cf_csr_r2;

wire r1_cf_csr;
wire r2_cf_csr;
assign r1_cf_csr = ex_cf_csr_r1  | mem_cf_csr_r1 | wb_cf_csr_r1;
assign r2_cf_csr = ex_cf_csr_r2  | mem_cf_csr_r2 | wb_cf_csr_r2;

assign ex_cf_r1 = (ex_valid &&  (dest_ex == rf_raddr1)&& !none_dest_ex);
assign mem_cf_r1 = (mem_to_wb_valid &&  (dest_mem == rf_raddr1)&& !none_dest_mem) ;
assign wb_cf_r1 = (wb_valid &&  (dest_wb == rf_raddr1)&& !none_dest_wb) ;

assign ex_cf_r2 = (ex_valid &&  (dest_ex == rf_raddr2)&& !none_dest_ex);
assign mem_cf_r2 = (mem_to_wb_valid &&  (dest_mem == rf_raddr2)&& !none_dest_mem) ;
assign wb_cf_r2 = (wb_valid &&  (dest_wb == rf_raddr2)&& !none_dest_wb) ;

assign ex_cf_csr_r1 = (ex_valid &&  (dest_ex == rf_raddr1)&& csr_inst_judge_cf_ex);
assign mem_cf_csr_r1 = (mem_to_wb_valid &&  (dest_mem == rf_raddr1)&& csr_inst_judge_cf_mem) ;
assign wb_cf_csr_r1 = (wb_valid &&  (dest_wb == rf_raddr1)&& csr_inst_judge_cf_wb) ;

assign ex_cf_csr_r2 = (ex_valid &&  (dest_ex == rf_raddr2)&& csr_inst_judge_cf_ex);
assign mem_cf_csr_r2 = (mem_to_wb_valid &&  (dest_mem == rf_raddr2)&& csr_inst_judge_cf_mem) ;
assign wb_cf_csr_r2 = (wb_valid &&  (dest_wb == rf_raddr2)&& csr_inst_judge_cf_wb) ;

assign r1_cf = !(rf_raddr1 == 5'b0                               || 
                   ( src1_is_pc &&  !inst_jirl)                                ||    //jirl指令的src1来自pc，src2来自imm，其�?要跳转的值也来自gr，因此此部分�?要设置fwd
                    none_src_reg                                ||         
                    (!ex_cf_r1 && !mem_cf_r1 && !wb_cf_r1)   )     ;

assign r2_cf = !(rf_raddr2 == 5'b0                               || 
                 (src2_is_imm & !inst_st_w & !inst_st_b & !inst_st_h & !inst_csrwr & !inst_csrxchg & !inst_invtlb)                  ||  //st指令的src1来自gr，src2来自imm，其�?�? //判定csrwr,csrxchg与st冲突行为类似
                              //调用的�?�也来自gr，因此此部分�?要设置fwd
                    none_src_reg                                ||         
                    (!ex_cf_r2 && !mem_cf_r2 && !wb_cf_r2) )      ;
assign csr_cf =// (inst_ertn && (csr_inst_type_ex[0] | csr_inst_type_mem[0] | csr_inst_type_wb[0]))
            |  ( r1_cf_csr | r2_cf_csr );
assign id_allowin = (!id_valid || id_readygo && ex_allowin ) ;
                 
assign id_to_ex_valid = id_valid && id_readygo;
always@(posedge clk or negedge resetn)begin
    if (!resetn) begin
        id_valid <= 1'b0;
    end
    else if (/*br_taken |*/ flush) begin ///////////////
        id_valid <= 1'b0;    
    end   
    else if (id_allowin) begin
        id_valid <= if_to_id_valid & !br_taken;
    end
end
        

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
reg [31:0] pc_reg;
always@ (posedge clk)begin
    if (!resetn) begin
        pc_reg <= 32'h1bfffffc;
        exc_adef_reg <= 1'b0;
        exc_pif_reg <= 1'b0;
        exc_ppi_fetch_reg <= 1'b0;
        exc_tlbrentry_fetch_reg <= 1'b0;
        inst_reg <= 32'h80000000;
    end
    else if (if_to_id_valid && id_allowin) begin      
        pc_reg <= pc_i;    
        exc_adef_reg <= exc_adef_i;
        exc_pif_reg <= exc_pif_i;
        exc_ppi_fetch_reg <= exc_ppi_fetch_i;
        exc_tlbrentry_fetch_reg <= exc_tlbrentry_fetch_i; 
        inst_reg <= inst_i;    
    end
end
//////////////////////////////////////////////////////////////////////////////////
assign inst = inst_reg;     
assign pc_o = pc_reg;
   
assign op_31_26  = inst[31:26];
assign op_25_22  = inst[25:22];
assign op_21_20  = inst[21:20];
assign op_19_15  = inst[19:15];

assign rd   = inst[ 4: 0];
assign rj   = inst[ 9: 5];
assign rk   = inst[14:10];

assign i12  = inst[21:10];
assign i20  = inst[24: 5];
assign i16  = inst[25:10];
assign i26  = {inst[ 9: 0], inst[25:10]};
assign i5  =  inst[14:10];
decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];//rd
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];//rd
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];//11�?17 //rd
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];//rd
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];//rd
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];//rd
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14]; 
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~inst[25];//只有rd無rj
assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'h0d];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'h0e];
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'h0f];
assign inst_sll_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~inst[25];
assign inst_mul_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18]; 
assign inst_mulh_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19]; 
assign inst_mulh_wu= op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a]; 
assign inst_div_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h0]; 
assign inst_mod_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h1]; 
assign inst_div_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h2]; 
assign inst_mod_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h3]; 

assign inst_blt    = op_31_26_d[6'h18];
assign inst_bge    = op_31_26_d[6'h19];
assign inst_bltu   = op_31_26_d[6'h1a];
assign inst_bgeu   = op_31_26_d[6'h1b];
assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h0];//rd
assign inst_ld_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h1];//rd
assign inst_ld_bu  = op_31_26_d[6'h0a] & op_25_22_d[4'h8];//rd
assign inst_ld_hu  = op_31_26_d[6'h0a] & op_25_22_d[4'h9];//rd
assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h4];//rd
assign inst_st_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h5];//rd

assign inst_csrrd  = op_31_26_d[6'h1]  & ~inst[25] & ~inst[24] & ~inst[9] & ~inst[8] & ~inst[7] & ~inst[6] & ~inst[5];
assign inst_csrwr  = op_31_26_d[6'h1]  & ~inst[25] & ~inst[24] & ~inst[9] & ~inst[8] & ~inst[7] & ~inst[6] & inst[5];
assign inst_csrxchg  = op_31_26_d[6'h1]  & ~inst[25] & ~inst[24] & rj != 5'b0 & rj != 5'b1;
assign inst_ertn   = op_31_26_d[6'h1]  & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] 
                   & (rk == 5'b01110) & (rj == 5'd0) & (rd == 5'd0);
assign inst_syscall = op_31_26_d[6'h0] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h16];
assign inst_break = op_31_26_d[6'h0] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h14];
assign inst_rdcntid = op_31_26_d[6'h0] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h0] & (rk == 5'b11000) & (rd == 5'b00000);      //这三条指令暂时�?�择输入到alu中，如果要上板可能要补充其他不需要alu的指令进入alu

assign inst_rdcntvl_w = op_31_26_d[6'h0] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h0] & (rk == 5'b11000) & (rj == 5'b00000);      
assign inst_rdcntvh_w = op_31_26_d[6'h0] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h0] & (rk == 5'b11001) & (rj == 5'b00000);      

assign inst_tlbsrch = op_31_26_d[6'h1] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & (rk == 5'ha) & (rj == 5'h0) & (rd == 5'h0);
assign inst_tlbrd = op_31_26_d[6'h1] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & (rk == 5'hb) & (rj == 5'h0) & (rd == 5'h0);
assign inst_tlbwr = op_31_26_d[6'h1] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & (rk == 5'hc) & (rj == 5'h0) & (rd == 5'h0);
assign inst_tlbfill = op_31_26_d[6'h1] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & (rk == 5'hd) & (rj == 5'h0) & (rd == 5'h0);
assign inst_invtlb = op_31_26_d[6'h1] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h13] ;

assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl | inst_pcaddu12i | inst_ld_b
                    | inst_ld_h | inst_ld_bu | inst_ld_hu |inst_st_b | inst_st_h | inst_csrrd
                     | inst_csrwr | inst_csrxchg | inst_rdcntvl_w | inst_rdcntvh_w | inst_rdcntid
                     | inst_tlbsrch | inst_tlbrd | inst_tlbwr | inst_tlbfill | inst_invtlb;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt | inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltui;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll_w;
assign alu_op[ 9] = inst_srli_w | inst_srl_w;
assign alu_op[10] = inst_srai_w | inst_sra_w;
assign alu_op[11] = inst_lu12i_w ;


assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui | inst_st_b | inst_st_h
                    | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu            ;
                                                                                                                    
assign need_si16  =  inst_jirl | inst_beq | inst_bne | inst_blt 
                     | inst_bge | inst_bltu | inst_bgeu;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;//?
wire need_csr;
assign need_csr = inst_csrwr | inst_csrxchg;
assign need_si12_zero_extend = inst_andi | inst_ori | inst_xori;
assign imm = need_csr | inst_invtlb  ? 32'h0:
             src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_si12 ? {{20{i12[11]}}, i12[11:0]} :
             need_ui5  ? {27'd0,i5[4:0]}            ://有更改，need_ui5处为自己�?
     {20'd0,i12[11:0]};  //need_si12_zero_extend ?

assign op_invtlb_id = {inst_invtlb,rd};
assign op_tlb = ({3{inst_tlbsrch}} & 3'd1) 
            |   ({3{inst_tlbwr}} & 3'd2) 
            |   ({3{inst_tlbrd}} & 3'd3) 
            |   ({3{inst_tlbfill}} & 3'd4) ;
assign csr_num = inst_rdcntid ? 14'h40 :inst[23:10];
assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_blt
                        | inst_bge | inst_bltu | inst_bgeu | inst_st_b | inst_st_h | inst_csrwr | inst_csrxchg;
                            
assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_slti   |
                       inst_sltui  |
                       inst_andi   |
                       inst_xori   |
                       inst_ori    |
                       inst_pcaddu12i |
                       inst_ld_b |
                       inst_ld_h |
                       inst_ld_bu |
                       inst_ld_hu |
                       inst_st_b |
                       inst_st_h |
                       inst_csrwr |
                       inst_csrxchg|
                       inst_invtlb;
assign res_from_mem  = inst_ld_w |
                       inst_ld_b |
                       inst_ld_h |
                       inst_ld_bu |
                       inst_ld_hu;
assign dst_is_r1     = inst_bl;
assign dst_is_rj     = inst_rdcntid;
assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & 
                       ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu & ~inst_st_h & ~inst_st_b 
                       & ~inst_tlbfill & ~inst_tlbsrch & ~inst_tlbrd & ~inst_tlbwr & ~inst_invtlb;
assign mem_we        = inst_st_w | inst_st_b | inst_st_h;
assign dest          = dst_is_r1 ? 5'd1 
                    :  dst_is_rj ? rj :rd;

assign rf_raddr1 = (op_invtlb_id[5] & !op_invtlb_id[2]) ? 5'h0 : rj ;    //invtlb操作不需要asid时�?�置rj�?0
assign rf_raddr2 = src_reg_is_rd ? rd : 
                   (op_invtlb_id[5] & (op_invtlb_id[2:0] != 3'b101) & (op_invtlb_id[2:0] != 3'b110)) ? 5'h0: rk;  //invtlb操作不需要va时�?�置rk�?0
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );
    
assign rj_value  = ( !(inst_jirl && r1_cf))  ?  rf_rdata1 :  //jirl指令的src1来自pc，src2来自imm，其�?要跳转的值也来自gr，因此此部分�?要设置fwd   
                  fwd_r1[2]   ? ex_result  :
                  fwd_r1[1]   ? mem_result :
                                 wb_result  ;                                          
assign rkd_value =( !((inst_st_w | inst_st_h | inst_st_b | inst_csrwr | inst_csrxchg | inst_invtlb) && r2_cf)) 
                              ?  rf_rdata2 : //st指令的src1来自gr，src2来自imm，其�?要储存的值也来自gr，因此此部分�?要设置fwd         ;    
                  fwd_r2[2]   ? ex_result  :
                  fwd_r2[1]   ? mem_result :
                                 wb_result  ;
 
    
wire rj_eq_rd;         //增添此行
assign rj_eq_rd = (alu_src1 == alu_src2);//(rj_value == rkd_value);
wire rj_gr_rd_signed;                  //rj>=rd,signed
assign rj_gr_rd_signed = $signed(alu_src1) >= $signed(alu_src2) ;
wire rj_gr_rd_unsigned;                //rj>=rd,unsigned             
assign rj_gr_rd_unsigned =(alu_src1) >= (alu_src2) ;
assign br_stall = br_taken & !id_readygo;
assign br_taken =   id_readygo & //防止假冲突，见exp13日志
                   ( !csr_cf &(   inst_beq  &&  rj_eq_rd //csr冲突用阻塞解决，防止跳转有冲突，但是没有前�?�，导致译码过早判断br_taken
                   || inst_bne  && !rj_eq_rd 
                   || inst_blt  && !rj_gr_rd_signed
                   || inst_bge  && rj_gr_rd_signed
                   || inst_bltu &&  !rj_gr_rd_unsigned
                   || inst_bgeu && rj_gr_rd_unsigned  
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  ) && id_valid); //&& !r1_cf && !r2_cf ;//此处valid�?
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b
                    || inst_blt || inst_bge || inst_bgeu || inst_bltu) 
                                                                ? (pc_o + br_offs) :
                                                    (rj_value + jirl_offs);///*inst_jirl

assign alu_src1 = src1_is_pc  ? pc_o[31:0] : 
                  fwd_r1[2]   ? ex_result  :
                  fwd_r1[1]   ? mem_result :
                  fwd_r1[0]   ? wb_result :  rj_value;
assign alu_src2 = src2_is_imm ? imm : 
                  fwd_r2[2]   ? ex_result  :
                  fwd_r2[1]   ? mem_result :
                  fwd_r2[0]   ? wb_result :  rkd_value;

wire [ 2:0] fwd_r1 ;
wire [ 2:0] fwd_r2 ;   
assign fwd_r1 = ex_cf_r1  ? 3'b100 :
                mem_cf_r1 ? 3'b010 :
                wb_cf_r1  ? 3'b001 : 3'b000;
assign fwd_r2 = ex_cf_r2  ? 3'b100 :
                mem_cf_r2 ? 3'b010 :
                wb_cf_r2  ? 3'b001 : 3'b000;                
 
 assign mul_div_op = ({3{inst_mul_w}} & 3'd1) 
                   | ({3{inst_mulh_w}} & 3'd2)   
                   | ({3{inst_mulh_wu}} & 3'd3)   
                   | ({3{inst_div_w}} & 3'd4)   
                   | ({3{inst_mod_w}} & 3'd5)   
                   | ({3{inst_div_wu}} & 3'd6)   
                   | ({3{inst_mod_wu}} & 3'd7)   
                   | ({3{(inst_mod_wu) & (!inst_mod_w) & (!inst_div_wu) & (!inst_div_w) & (!inst_mulh_wu) & (!inst_mul_w) & (!inst_mulh_w)}} & 3'd0);   
 assign div_sign = id_valid & (inst_mod_w | inst_div_w | inst_mod_wu | inst_div_wu) ;                                    
 assign ld_type = (   {3{inst_ld_w}} & 3'd1) 
                   | ({3{inst_ld_b}} & 3'd2)   
                   | ({3{inst_ld_h}} & 3'd3)  
                   | ({3{inst_ld_bu}} & 3'd4)   
                   | ({3{inst_ld_hu}} & 3'd5)   ;
 assign st_type =    ({2{inst_st_w}} & 2'd1) 
                   | ({2{inst_st_b}} & 2'd2)   
                   | ({2{inst_st_h}} & 2'd3)   ;

assign csr_inst_type =              (inst_csrwr)   ? 2'b01:
                             inst_csrrd | inst_rdcntid    ? 2'b10:
                                     inst_csrxchg  ? 2'b11:
                                                     2'b00;
assign exc_sys_call = inst_syscall;
assign exc_refetch_o = (inst_tlbfill | inst_tlbrd | inst_tlbwr | inst_invtlb |  //不�?�虑valid的瑕疵：wb发出冲刷，此时id仍有可能�?测出重取指，导致做了多余操作（不过重取指不影响正确，且这种冲突应该频率低，暂时不优化�?
                                  inst_csrxchg | inst_csrwr);

assign exc_break = inst_break;
assign exc_adef_o = exc_adef_reg;
assign exc_ine =   !exc_adef_o &
                    (!(inst_add_w | inst_sub_w | inst_slt | inst_sltu | inst_nor | inst_and | inst_or | inst_xor |
                   inst_slli_w | inst_srli_w | inst_srai_w | inst_addi_w | inst_ld_w | inst_st_w | inst_jirl |
                   inst_b | inst_bl | inst_beq | inst_bne | inst_lu12i_w | inst_slti | inst_sltui | inst_andi |
                   inst_ori | inst_xori | inst_sll_w | inst_srl_w | inst_sra_w | inst_pcaddu12i | inst_mul_w |
                   inst_mulh_w | inst_mulh_wu | inst_div_w | inst_mod_w | inst_div_wu | inst_mod_wu | inst_blt |
                   inst_bge | inst_bltu | inst_bgeu | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu | inst_st_b |
                   inst_st_h | inst_csrrd | inst_csrwr | inst_csrxchg | inst_syscall | inst_ertn | inst_break
                   | inst_rdcntvl_w | inst_rdcntvh_w | inst_rdcntid | inst_tlbsrch | inst_tlbrd | inst_tlbwr | inst_tlbfill
                   | inst_invtlb ));//在某个周期为1，随后报bug（导�?47不过），改为恒为0后bug消失�?47�?
assign exc_int = has_int;
assign exc_pif_o = exc_pif_reg;
assign exc_ppi_fetch_o = exc_ppi_fetch_reg;
assign exc_tlbrentry_fetch_o = exc_tlbrentry_fetch_reg;
endmodule
