
module ex_stage(
input wire clk,
input wire resetn,
input wire [31:0] alu_src1_i,
input wire [31:0] alu_src2_i,
input wire [11:0] alu_op_i,
input wire        res_from_mem_i,
input wire        gr_we_i,
input wire        mem_we_i,
input wire [4: 0] dest_i,
input wire [31:0] rkd_value_i,

output wire        res_from_mem_o,
output wire        gr_we_o,
output wire        mem_we_o,
output wire [4: 0] dest_o,
output wire [31:0] alu_result,//实际上不只是alu模块的结果，还包含了乘除法运算部件的输出
output wire [31:0] rkd_value_o,
input wire mem_allowin,
input wire id_to_ex_valid,
output wire ex_to_mem_valid,
input wire [31:0] pc_i,
output wire [31:0] pc_o,

output wire [ 3:0] data_sram_we_va    ,
output wire [ 3:0] data_sram_we,
output wire [31:0] data_sram_addr  ,
output wire [31:0] data_sram_wdata ,
output wire ex_allowin,
input wire none_dest_i,
output wire none_dest_o,
output wire valid,

input wire [2:0] mul_div_op_i,
input wire div_sign,
input wire [2:0] ld_type_i,
output wire [2:0] ld_type_o,
input wire [1:0] st_type_i,
output wire [1:0] st_type,
input wire [1:0] csr_inst_type_i,
output wire [1:0] csr_inst_type_o,
input wire [13:0] csr_num_i,
output wire [13:0] csr_num_o,
input wire inst_ertn_i,
output wire inst_ertn_o,

input wire exc_sys_call_i,
output wire exc_sys_call_o,
input wire exc_adef_i,
output wire exc_adef_o,
output wire exc_ale,
input wire exc_ine_i,
output wire exc_ine_o,
input wire exc_break_i,
output wire exc_break_o,
input wire exc_int_i,
output wire exc_int_o,

input wire flush,

input wire exc_sys_call_mem,
input wire exc_sys_call_wb,

input wire inst_ertn_mem,
input wire inst_ertn_wb,
input wire exc_mem,
input wire exc_wb,
input wire [31:0] counter64_l,
output wire [31:0] counter64_h,

input wire inst_rdcntid_i,
output wire inst_rdcntid_o,
input wire inst_rdcntvl_w,
input wire inst_rdcntvh_w,
output wire csr_inst_judge_cf,

output wire st_req,
input wire data_addr_ok,
output wire data_req,
output wire ex_readygo,
input wire [5:0] op_invtlb_id,
input wire [2:0] op_tlb_i,
output wire [2:0] op_tlb_o,

output wire invtlb_valid,
output wire [4:0] invtlb_op,
output wire op_tlbsrch_ex,
//重取�?
input wire exc_refetch_i,
output wire exc_refetch_o,

//tlbsrch写后读冲�?
input wire change_csr_mem,
input wire change_csr_wb,
//renew
input wire exc_pif_i,
input wire exc_ppi_fetch_i,
input wire exc_tlbrentry_fetch_i,
output wire exc_pif_o,
output wire exc_ppi_fetch_o,
output wire exc_tlbrentry_fetch_o,
input wire exc_pis_ex,
input wire exc_pil_ex,
input wire exc_pme_ex,
input wire exc_tlbrentry_memory_ex,
input wire exc_ppi_memory_ex,
output wire res_from_mem_o_va
    );   
reg [31:0] alu_src1_reg;
reg [31:0] alu_src2_reg;
reg [2:0] mul_div_op_reg;
reg none_dest_reg;
reg [11:0] alu_op_reg;
reg res_from_mem_reg;
reg gr_we_reg;
reg mem_we_reg;
reg [4: 0] dest_reg;
reg [31:0] rkd_value_reg;
reg [31:0] pc_reg;
reg [13:0] csr_num_reg;
reg [1:0] csr_inst_type_reg;
reg [2:0] ld_type_reg;
reg ex_valid;
reg inst_rdcntvl_w_reg;
reg inst_rdcntvh_w_reg;
reg [1:0] st_type_reg;
reg [2:0] op_tlb_reg;
reg [5:0] op_invtlb_reg;
wire [63:0] unsigned_prod;
wire [63:0] signed_prod;
wire [31:0] div_result_signed;
wire [31:0] div_result_unsigned;
wire [31:0] mod_result_signed;
wire [31:0] mod_result_unsigned;
wire s_axis_divisor_tready_signed;
wire s_axis_divisor_tready_unsigned;
wire s_axis_dividend_tready_signed;
wire s_axis_dividend_tready_unsigned;
wire m_axis_dout_tvalid_signed;
wire m_axis_dout_tvalid_unsigned;
wire s_axis_div_tvalid_signed;
wire s_axis_div_tvalid_unsigned;
reg s_axis_div_tvalid_signed_reg;
reg s_axis_div_tvalid_unsigned_reg;
wire [ 7:0] mul_div_op;
wire div_state_signed;
wire div_state_unsigned;


reg inst_rdcntid_reg;
//exc reg
reg exc_sys_call_reg;
reg exc_adef_reg;
reg exc_ine_reg;
reg exc_break_reg;
reg exc_int_reg;
reg exc_refetch_reg;
reg exc_pif_reg;
reg exc_ppi_fetch_reg;
reg exc_tlbrentry_fetch_reg;
reg inst_ertn_reg;
////////////////////////////////////////////////////////////////////////
assign res_from_mem_o = res_from_mem_o_va & !exc_pil_ex & !exc_tlbrentry_memory_ex;
assign data_req = ex_valid & mem_allowin & (res_from_mem_o | st_req);
wire data_req;
////////////////////////////////////////////////////////////////////////

assign inst_ertn_o = inst_ertn_reg;
assign div_state_signed = mul_div_op[4] | mul_div_op[5]  ;
assign div_state_unsigned = mul_div_op[6] | mul_div_op[7];
assign s_axis_div_tvalid_signed = s_axis_div_tvalid_signed_reg & ex_valid;
assign s_axis_div_tvalid_unsigned = s_axis_div_tvalid_unsigned_reg & ex_valid;
//wire op_is_mul_div;

assign ex_readygo = (!((op_tlb_reg == 3'd1) & (change_csr_mem | change_csr_wb))) &  //tlbsrch写后读冲�?
               (      (div_state_signed | div_state_unsigned) ?
                     (m_axis_dout_tvalid_signed | m_axis_dout_tvalid_unsigned )  
                   : ( (!res_from_mem_o & !st_req) | (data_req & data_addr_ok))   ) ;  
assign ex_allowin = !ex_valid || ex_readygo && mem_allowin;
assign ex_to_mem_valid = ex_valid && ex_readygo;
assign pc_o = pc_reg;
assign valid = ex_valid;
assign ld_type_o = ld_type_reg;
assign st_type = st_type_reg;
assign csr_inst_judge_cf = (csr_inst_type_o[0] | csr_inst_type_o[1]) &{ex_valid}; 
//异常信号
assign exc_sys_call_o = exc_sys_call_reg;
assign exc_adef_o = exc_adef_reg;
assign exc_ale = ( (ld_type_o == 3'd3 | ld_type_o == 3'd5 | st_type == 2'd3) & alu_result[0] )
               | ( (ld_type_o == 3'd1 | st_type == 2'd1) & (alu_result[0] | alu_result[1]));
assign exc_ine_o = exc_ine_reg |
                ( invtlb_valid & !((invtlb_op == 5'h0 | invtlb_op == 5'h1 | invtlb_op == 5'h2 
                | invtlb_op == 5'h3 | invtlb_op == 5'h4 | invtlb_op == 5'h5 | invtlb_op == 5'h6)));
assign exc_break_o = exc_break_reg;
assign exc_int_o = exc_int_reg;
assign exc_refetch_o = exc_refetch_reg & !exc_ine_o;//ine related to invtlb,which is related to refetch as well,so judgement is needed
assign exc_pif_o = exc_pif_reg;
assign exc_ppi_fetch_o = exc_ppi_fetch_reg;
assign exc_tlbrentry_fetch_o = exc_tlbrentry_fetch_reg;

assign inst_rdcntid_o = inst_rdcntid_reg;
assign op_tlb_o = op_tlb_reg;
assign invtlb_valid = op_invtlb_reg[5] 
                      & ex_valid
                      & !exc_ale & !exc_adef_o & !exc_int_o 
                      & !exc_pif_o & !exc_ppi_fetch_o & !exc_tlbrentry_fetch_o
                      & !exc_mem & !inst_ertn_mem
                      & !exc_wb  & !inst_ertn_wb ;
assign invtlb_op = op_invtlb_reg[4:0];
assign op_tlbsrch_ex = (op_tlb_o == 3'd1) & ex_valid
                      & !exc_ale & !exc_adef_o & !exc_int_o 
                      & !exc_pif_o & !exc_ppi_fetch_o & !exc_tlbrentry_fetch_o
                      & !exc_mem & !inst_ertn_mem
                      & !exc_wb  & !inst_ertn_wb ;
always@(posedge clk)begin
    if (!resetn) begin
        ex_valid <= 1'b0;
    end
    else if (flush) begin
        ex_valid <= 1'b0;
    end
    else if (ex_allowin) begin
        ex_valid <= id_to_ex_valid;
    end
end
        
always@ (posedge clk)begin
    if (!resetn) begin
        alu_src1_reg <= 32'h0;
        alu_src2_reg <= 32'h0;
        alu_op_reg <= 12'h0;
        res_from_mem_reg <= 1'h0;
        gr_we_reg <= 1'h0;
        mem_we_reg <= 1'h0;
        dest_reg <= 5'h0;
        rkd_value_reg <= 32'h0; 
        pc_reg <= 32'h1bfffffc;
        none_dest_reg <= 1'b0;
        mul_div_op_reg <= 3'b0;
        ld_type_reg <= 3'b0;
        st_type_reg <= 2'b0;
        csr_num_reg <= 14'b0;
        csr_inst_type_reg <= 2'b0;
        inst_ertn_reg <= 1'b0;
        exc_sys_call_reg <= 1'b0;
        exc_adef_reg <= 1'b0;
        exc_ine_reg <= 1'b0;
        exc_break_reg <= 1'b0;
        exc_int_reg <= 1'b0;
        inst_rdcntid_reg <= 1'b0;
        inst_rdcntvl_w_reg <= 1'b0;
        inst_rdcntvh_w_reg <= 1'b0;
        op_tlb_reg <= 3'b0;
        op_invtlb_reg <= 6'b0;
        exc_refetch_reg <= 1'b0;
        exc_pif_reg <= 1'b0;
        exc_ppi_fetch_reg <= 1'b0;
        exc_tlbrentry_fetch_reg <= 1'b0;
    end
    else if (id_to_ex_valid && ex_allowin) begin      
        alu_src1_reg <= alu_src1_i;
        alu_src2_reg <= alu_src2_i;
        alu_op_reg <= alu_op_i;
        res_from_mem_reg <= res_from_mem_i;
        gr_we_reg <= gr_we_i;
        mem_we_reg <= mem_we_i;
        dest_reg <= dest_i;  
        rkd_value_reg <= rkd_value_i; 
        pc_reg <= pc_i;
        none_dest_reg <= none_dest_i;               
        mul_div_op_reg <= mul_div_op_i;
        ld_type_reg <= ld_type_i;
        st_type_reg <= st_type_i;
        csr_num_reg <= csr_num_i;
        csr_inst_type_reg <= csr_inst_type_i;
        inst_ertn_reg <= inst_ertn_i;
        exc_sys_call_reg <= exc_sys_call_i;
        exc_adef_reg <= exc_adef_i;
        exc_ine_reg <= exc_ine_i;
        exc_break_reg <= exc_break_i;
        exc_int_reg <= exc_int_i;
        inst_rdcntid_reg <= inst_rdcntid_i;
        inst_rdcntvl_w_reg <= inst_rdcntvl_w;
        inst_rdcntvh_w_reg <= inst_rdcntvh_w;
        op_tlb_reg <= op_tlb_i;
        op_invtlb_reg <= op_invtlb_id;
        exc_refetch_reg <= exc_refetch_i;
        exc_pif_reg <= exc_pif_i;
        exc_ppi_fetch_reg <= exc_ppi_fetch_i;
        exc_tlbrentry_fetch_reg <= exc_tlbrentry_fetch_i; 
     end
end
//////////////////////////////////////////////////////////////////////////////////
always@(posedge clk)begin
    if(!resetn)begin
        s_axis_div_tvalid_signed_reg   <= 1'b0 ;
    end
    else if (s_axis_divisor_tready_signed & s_axis_dividend_tready_signed & s_axis_div_tvalid_signed )begin
        s_axis_div_tvalid_signed_reg   <= 1'b0;
     end
    else if (div_sign)begin        
        s_axis_div_tvalid_signed_reg   <= ((mul_div_op_i == 3'd4) | (mul_div_op_i == 3'd5));
//        ( !(s_axis_divisor_tready_signed & s_axis_dividend_tready_signed & s_axis_div_tvalid_signed))
     end
end
always@(posedge clk)begin
    if(!resetn)begin
        s_axis_div_tvalid_unsigned_reg <= 1'b0 ;
    end
    else if (s_axis_divisor_tready_unsigned & s_axis_dividend_tready_unsigned & s_axis_div_tvalid_unsigned )begin
        s_axis_div_tvalid_unsigned_reg   <= 1'b0;
     end    
    else if (div_sign)begin        
        s_axis_div_tvalid_unsigned_reg <= ((mul_div_op_i == 3'd6) | (mul_div_op_i == 3'd7));
     //    ( !(s_axis_divisor_tready_unsigned & s_axis_dividend_tready_unsigned & s_axis_div_tvalid_unsigned));    
     end
end
//////////////////////////////////////////////////////////////////////////////////
wire [31:0] alu_result_but_mul_div;
wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire [11:0] alu_op;
wire s_axis_divisor_tvalid_signed;
wire s_axis_divisor_tvalid_unsigned;
assign mul_div_op[0] = (mul_div_op_reg == 3'd0);   
assign mul_div_op[1] = (mul_div_op_reg == 3'd1);   
assign mul_div_op[2] = (mul_div_op_reg == 3'd2);   
assign mul_div_op[3] = (mul_div_op_reg == 3'd3);   
assign mul_div_op[4] = (mul_div_op_reg == 3'd4);   
assign mul_div_op[5] = (mul_div_op_reg == 3'd5);   
assign mul_div_op[6] = (mul_div_op_reg == 3'd6);   
assign mul_div_op[7] = (mul_div_op_reg == 3'd7);   

assign alu_src1 = alu_src1_reg;
assign alu_src2 = alu_src2_reg;

assign alu_op = alu_op_reg;

assign res_from_mem_o_va = res_from_mem_reg 
                         & (!exc_ale)   & {4{!exc_mem}} & {4{!inst_ertn_mem}}
                         & {4{!exc_wb}}  & {4{!inst_ertn_wb}};;
assign gr_we_o = gr_we_reg;
assign mem_we_o = mem_we_reg;
assign dest_o = dest_reg /*&& {5{ex_valid}}*/ ;
assign rkd_value_o = rkd_value_reg;   
assign csr_inst_type_o = csr_inst_type_reg;
assign csr_num_o = csr_num_reg;
wire [1:0] st_select; 
wire [3:0] st_sram_we_h;
wire [3:0] st_sram_we_b;
wire [3:0] st_sram_we;
assign st_req = (data_sram_we != 4'b0);
assign st_sram_we_b = ({4{st_select == 2'b00}} & 4'b0001)
                    | ({4{st_select == 2'b01}} & 4'b0010)
                    | ({4{st_select == 2'b10}} & 4'b0100)
                    | ({4{st_select == 2'b11}} & 4'b1000);
assign st_sram_we_h = (st_select == 2'b00) ? 4'b0011 : 4'b1100;
assign st_sram_we = (st_type == 2'd1) ? 4'b1111:
                   (st_type == 2'd2) ?  st_sram_we_b :
                   /*(st_type == 2'd3)? */ st_sram_we_h;   
assign st_select = data_sram_addr[1:0];
assign data_sram_we = data_sram_we_va & {4{!exc_pis_ex}} & {4{!exc_pme_ex}} & {4{!exc_ppi_memory_ex}} & {4{!exc_tlbrentry_memory_ex}};
assign data_sram_we_va    = {4{mem_we_reg && ex_valid}} & st_sram_we 
                       & {4{!exc_ale}} & {4{!exc_adef_o}} & {4{!exc_int_o}} 
                       & {4{!exc_pif_o}} & {4{!exc_ppi_fetch_o}} & {4{!exc_tlbrentry_fetch_o}}
                        & {4{!exc_mem}} & {4{!inst_ertn_mem}}
                        & {4{!exc_wb}}  & {4{!inst_ertn_wb}};
assign data_sram_addr  = alu_result;
assign data_sram_wdata = (st_type == 2'd2) ? {4{rkd_value_reg[7:0]}} :   /*rkd_value_reg;*///原来�?
                         (st_type == 2'd3) ? {2{rkd_value_reg[15:0]}}: rkd_value_reg;
            
assign none_dest_o = none_dest_reg; 
    alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result_but_mul_div)
    );    


assign unsigned_prod = alu_src1 * alu_src2;
assign signed_prod   = $signed(alu_src1) * $signed(alu_src2);

assign alu_result =  csr_inst_type_o == 2'b01 ? 32'hffffffff://////可针对优先级进行优化
                     csr_inst_type_o == 2'b10 ? 32'h0       :
                     inst_rdcntvl_w_reg  ? counter64_l :
                     inst_rdcntvh_w_reg  ? counter64_h :  
                     ({32{mul_div_op[0]}} & alu_result_but_mul_div) 
                   | ({32{mul_div_op[1]}} & signed_prod[31:0])    
                   | ({32{mul_div_op[2]}} & signed_prod[63:32])    
                   | ({32{mul_div_op[3]}} & unsigned_prod[63:32])    
                   | ({32{mul_div_op[4]}} & div_result_signed)    
                   | ({32{mul_div_op[5]}} & mod_result_signed)    
                   | ({32{mul_div_op[6]}} & div_result_unsigned)    
                   | ({32{mul_div_op[7]}} & mod_result_unsigned)  ;  


                               

     my_div u_mydiv_signed
   (.aclk(clk),
    .s_axis_divisor_tvalid(s_axis_div_tvalid_signed),
    .s_axis_divisor_tready(s_axis_divisor_tready_signed),
    .s_axis_divisor_tdata(alu_src2),
    .s_axis_dividend_tvalid(s_axis_div_tvalid_signed),
    .s_axis_dividend_tready(s_axis_dividend_tready_signed),
    .s_axis_dividend_tdata(alu_src1),
    .m_axis_dout_tvalid(m_axis_dout_tvalid_signed),
    .m_axis_dout_tdata({div_result_signed,mod_result_signed})
    );                                   


     my_div_unsigned u_mydiv_unsigned
   (.aclk(clk),
    .s_axis_divisor_tvalid(s_axis_div_tvalid_unsigned),
    .s_axis_divisor_tready(s_axis_divisor_tready_unsigned),
    .s_axis_divisor_tdata(alu_src2),
    .s_axis_dividend_tvalid(s_axis_div_tvalid_unsigned),
    .s_axis_dividend_tready(s_axis_dividend_tready_unsigned),
    .s_axis_dividend_tdata(alu_src1),
    .m_axis_dout_tvalid(m_axis_dout_tvalid_unsigned),
    .m_axis_dout_tdata({div_result_unsigned,mod_result_unsigned})
    );    
endmodule
