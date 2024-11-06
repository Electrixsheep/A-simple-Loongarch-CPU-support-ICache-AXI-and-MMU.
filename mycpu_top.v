module mycpu_top (
    input wire aclk,
    input wire aresetn,   // low active

    // Read address channel
    output wire [3:0] arid,
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    output wire [2:0] arsize,
    output wire [1:0] arburst,
    output wire [1:0] arlock,
    output wire [3:0] arcache,
    output wire [2:0] arprot,
    output wire arvalid,
    input wire arready,

    // Read data channel
    input wire [3:0] rid,
    input wire [31:0] rdata,
    input wire [1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready,

    // Write address channel
    output wire [3:0] awid,
    output wire [31:0] awaddr,
    output wire [7:0] awlen,
    output wire [2:0] awsize,
    output wire [1:0] awburst,
    output wire [1:0] awlock,
    output wire [3:0] awcache,
    output wire [2:0] awprot,
    output wire awvalid,
    input wire awready,

    // Write data channel
    output wire [3:0] wid,
    output wire [31:0] wdata,
    output wire [3:0] wstrb,
    output wire wlast,
    output wire wvalid,   
    input wire wready,

    // Write response channel
    input wire [3:0] bid,
    input wire [1:0] bresp,
    input wire bvalid,
    output wire bready,

    // Debug interface
    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_we,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

wire clk;
wire resetn;
assign clk = aclk;
assign resetn = aresetn;

wire [3:0] inst_sram_we;
wire [3:0] data_sram_we;
wire [3:0] data_sram_we_va;
wire res_from_mem_ex_va;
// Instruction SRAM interface signals
wire        inst_sram_req;
wire        inst_sram_req_va;
wire        inst_sram_wr;
wire [1:0]  inst_sram_size;
wire [3:0]  inst_sram_wstrb;
wire [31:0] inst_sram_addr;
wire [31:0] inst_sram_addr_va;
wire [31:0] inst_sram_wdata;
wire        inst_sram_addr_ok;
wire        inst_sram_data_ok;
wire [31:0] inst_sram_rdata;

// Data SRAM interface signals
wire        data_sram_req;
wire        data_sram_wr;
wire [1:0]  data_sram_size;
wire [3:0]  data_sram_wstrb;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_addr_va;
wire [31:0] data_sram_wdata;
wire        data_sram_addr_ok;
wire        data_sram_data_ok;
wire [31:0] data_sram_rdata;
//虚实转换


assign inst_sram_we    = 4'b0;
assign inst_sram_wr = | inst_sram_we;
assign inst_sram_addr_va  = pc_next;
assign inst_sram_wstrb = inst_sram_we;
assign inst_sram_wdata = 32'b0;
assign inst_sram_size = 2'h2;

assign data_sram_wr = | (data_sram_we);
assign data_sram_wstrb = data_sram_we; //& {4{!exc_pis_ex}} & {4{!exc_pme_ex}} & {4{!exc_ppi_memory_ex}} & {4{!exc_tlbrentry_memory_ex}});
assign data_sram_size = ( {2{(ld_type_ex == 3'd1 | st_type_ex == 2'd1)}} & 2'd2)
                    |   ( {2{(ld_type_ex == 3'd3 | ld_type_ex == 3'd5 | st_type_ex == 2'd3)}} & 2'd1) 
                    |   ( {2{(ld_type_ex == 3'd2 | ld_type_ex == 3'd4 | st_type_ex == 2'd2)}} & 2'd0) ;

//icachec define
wire         rd_req_icache;
wire [  2:0] rd_type_icache;
wire [ 31:0] rd_addr_icache;
wire         rd_rdy_icache;
wire         ret_valid_icache;
wire         ret_last_icache;
wire [ 31:0] ret_data_icache;
wire         wr_req_icache;
wire [  2:0] wr_type_icache;
wire [ 31:0] wr_addr_icache;
wire [  3:0] wr_wstrb_icache;
wire [127:0] wr_data_icache;

wire ipi_int_in = 1'b0;
wire [7:0] hw_int_in;
assign hw_int_in = 8'b0;

wire [31:0] pc_next;


wire [31:0] inst_if;
reg         reset;


always @(posedge clk) reset <= ~resetn;




wire [31:0] rkd_value;


wire if_allowin;
wire id_allowin;
wire ex_allowin;
wire mem_allowin;
wire wb_allowin;
wire br_taken;
wire [31:0] br_target;

wire [31:0] pc_next_inst_ram;

wire if_to_id_valid;
wire id_to_ex_valid;
wire ex_to_mem_valid;
wire mem_to_wb_valid;

wire preif_readygo;
wire ex_readygo;
wire mem_readygo;

wire [31:0] pc_id;
wire [31:0] pc_ex;
wire [31:0] pc_mem;
wire [31:0] pc_wb;
wire [31:0] pc_if;    

wire [11:0] alu_op;
wire res_from_mem_ex;
wire res_from_mem_mem;

wire gr_we_ex;
wire gr_we_mem;
wire gr_we_wb;

wire mem_we_ex;
wire mem_we_mem;
wire mem_we_wb;

wire [4:0] dest_ex;
wire [4:0] dest_mem;
wire [4:0] dest_wb;

wire [31:0] rkd_value_ex;

wire         rf_we   ;
wire [ 4:0]  rf_waddr;
wire [31:0] rf_wdata;

wire [31:0] alu_src1;
wire [31:0] alu_src2;

wire [31:0] alu_result;

wire [31:0] final_result;

wire none_dest_id;
wire none_dest_mem;
wire none_dest_ex;
wire none_dest_wb;

wire mem_valid;
wire ex_valid;
wire wb_valid;


wire res_from_mem_id;
wire gr_we_id;
wire mem_we_id;
wire [4:0] dest_id;
wire [31:0] rkd_value_id;
wire id_readygo;
wire div_sign;

wire [2:0] mul_div_op;
wire [2:0] ld_type_id;
wire [2:0] ld_type_ex;
wire [1:0] st_type_id;
wire [1:0] st_type_ex;
wire [31:0] exc_entry;
wire has_int;
wire ertn_flush;
wire wb_exc;
wire [5:0] wb_ecode;
wire [8:0] wb_esubcode;

wire [31:0] rkd_value_mem;
wire [31:0] rkd_value_wb;
 
wire [1:0] csr_inst_type_id;
wire [1:0] csr_inst_type_ex;
wire [1:0] csr_inst_type_mem;
wire [1:0] csr_inst_type_wb;
   
wire [13:0] csr_num_id;
wire [13:0] csr_num_ex;
wire [13:0] csr_num_mem;
wire [13:0] csr_num_wb;

 
 wire [31:0] csr_re;//某一位被设置�?1，表示对应的CSR位可以被读取
 wire [31:0] csr_rvalue;
 wire  csr_we;
 wire [31:0] csr_wmask;//某一位被设置�?1，表示对应的CSR位可以被写入
 wire [31:0] csr_wvalue;
 
 wire inst_ertn_id;
 wire inst_ertn_ex;
 wire inst_ertn_mem;
 wire inst_ertn_wb;
 
 
 wire exc_sys_call_id;
 wire exc_sys_call_ex;
 wire exc_sys_call_mem;
 wire exc_sys_call_wb;

wire exc_break_id;
wire exc_break_ex;
wire exc_break_mem;
wire exc_break_wb;

wire exc_ine_id;
wire exc_ine_ex;
wire exc_ine_mem;
wire exc_ine_wb;

wire exc_adef_if;
wire exc_adef_id;
wire exc_adef_ex;
wire exc_adef_mem;
wire exc_adef_wb;

wire exc_ale_ex;
wire exc_ale_mem;
wire exc_ale_wb;

wire exc_int_id; 
wire exc_int_mem; 
wire exc_int_wb; 
wire exc_int_ex; 
//重取指标�?
wire exc_refetch_if;//实际上不是真正的异常，只�?"如同异常"�?样处�?
wire exc_refetch_id;
wire exc_refetch_ex;
wire exc_refetch_mem;
wire exc_refetch_wb;
wire refetch_sign_id;
wire [31:0] refetch_pc_wb;
//tlbsrch的写后读相关
wire change_csr_mem;
wire change_csr_wb;
wire [31:0] vaddr_wb;
wire [31:0] vaddr_mem;

wire exc_wb;
wire exc_mem;
//exc for tlb
wire [31:0] csr_era_rvalue;
wire [31:0] csr_eentry_rvalue;
wire flush;
wire csr_inst_judge_cf_ex;
wire csr_inst_judge_cf_mem;
wire csr_inst_judge_cf_wb;

wire [31:0] counter64_l;
wire [31:0] counter64_h;
 wire inst_rdcntvl_w;
 wire inst_rdcntvh_w;
 
 wire br_stall;
 wire st_req;
 wire data_unfinished;
 
 wire [5:0] op_invtlb_id; 
 wire [2:0] op_tlb_id;
 wire [2:0] op_tlb_ex;
 wire [2:0] op_tlb_mem;
 wire [2:0] op_tlb_wb; 
wire [18:0] s0_vppn, s1_vppn, w_vppn, r_vppn;
wire s0_va_bit12, s1_va_bit12, invtlb_valid, we, w_e, w_g;
wire [9:0] s0_asid, s1_asid, w_asid, r_asid;
wire s0_found, s1_found, r_e, r_g;
wire [3:0] s0_index, s1_index, w_index, r_index;
wire [19:0] s0_ppn, s1_ppn, w_ppn0, w_ppn1, r_ppn0, r_ppn1;
wire [5:0] s0_ps, s1_ps, w_ps, r_ps;
wire [1:0] s0_plv, s1_plv, w_plv0, w_plv1, r_plv0, r_plv1;
wire [1:0] s0_mat, s1_mat, w_mat0, w_mat1, r_mat0, r_mat1;
wire s0_d, s1_d, w_d0, w_d1, r_d0, r_d1;
wire s0_v, s1_v, w_v0, w_v1, r_v0, r_v1;
wire [4:0] invtlb_op;
wire op_tlbrd_wb;//
wire op_tlbwr_wb;
wire op_tlbsrch_ex;
wire op_tlbfill_wb;
wire op_tlbrd_csr;//思路：对tlb的控制统�?从csr发出
wire op_tlbwr_csr;
wire op_tlbsrch_csr;
wire op_tlbfill_csr;
wire invtlb_valid_ex;
wire [4:0] invtlb_op_ex;
wire [18:0] csr_tlbehi_vppn_rvalue;
wire [3:0] csr_tlbidx_index_rvalue;
wire [9:0] csr_asid_asid_rvalue;
wire [31:0] csr_tlbrentry_rvalue;
wire [31:0] csr_dmw0_rvalue;
wire [31:0] csr_dmw1_rvalue;
wire csr_crmd_da_rvalue;
wire csr_crmd_pg_rvalue;
wire [1:0] csr_crmd_plv_rvalue;
//trans
wire exc_tlb_fetch_trans;
wire exc_tlb_memory_trans;
//tlb related exc
wire exc_tlb;//在wb汇�?�的exc for tlb信号
    //pil
wire exc_pil_ex;
wire exc_pil_mem;
wire exc_pil_wb;
    //pis
wire exc_pis_ex;
wire exc_pis_mem;
wire exc_pis_wb;
    //pif
wire exc_pif_if;
wire exc_pif_id;
wire exc_pif_ex;
wire exc_pif_mem;
wire exc_pif_wb;
    //pme
wire exc_pme_ex;
wire exc_pme_mem;
wire exc_pme_wb;
    //ppi
wire exc_ppi_fetch_if;
wire exc_ppi_fetch_id;
wire exc_ppi_fetch_ex;
wire exc_ppi_fetch_mem;
wire exc_ppi_fetch_wb;
wire exc_ppi_memory_ex;    
wire exc_ppi_memory_mem;    
wire exc_ppi_memory_wb;    
wire exc_ppi_wb;    
    //tlbrentry
wire exc_tlbrentry_memory_ex;
wire exc_tlbrentry_memory_mem;
wire exc_tlbrentry_memory_wb;
wire exc_tlbrentry_fetch_if;
wire exc_tlbrentry_fetch_id;
wire exc_tlbrentry_fetch_ex;
wire exc_tlbrentry_fetch_mem;
wire exc_tlbrentry_fetch_wb;
wire exc_tlbrentry_wb;
//tlb接口
//s1,load and store
assign s1_vppn = op_tlbsrch_csr ? csr_tlbehi_vppn_rvalue :
                invtlb_valid ? rkd_value_ex[31:13] :
                                                 data_sram_addr_va[31:13] ;//复用了rkd_value的数据�?�路在ex取出rk的�??
assign s1_va_bit12 = invtlb_valid ? rkd_value_ex[12] : data_sram_addr_va[12];
assign s1_asid = invtlb_valid ?  alu_result[9:0] : csr_asid_asid_rvalue;//复用了alu的数据�?�路.将src2的imm设置�?0，并设置加法操作数，以在ex能取出rj的�??
//s0,fetch
assign s0_vppn = inst_sram_addr_va[31:13];
assign s0_va_bit12 = inst_sram_addr_va[12];
assign s0_asid = csr_asid_asid_rvalue;
//fetch paddr
wire [31:0] inst_paddr_da;
wire [31:0] inst_paddr_dmw;
wire [31:0] inst_paddr_tlb;

//ld and st paddr
wire [31:0] data_paddr_da;
wire [31:0] data_paddr_dmw;
wire [31:0] data_paddr_tlb;
//r
assign r_index = csr_tlbidx_index_rvalue;
    if_stage u_if_stage (
        .clk(clk),
        .resetn(resetn),

        .id_allowin(id_allowin),
        .br_taken(br_taken),
        .br_target(br_target),
        .pc_next_o(pc_next),
        .if_to_id_valid(if_to_id_valid),
        .exc_entry(exc_entry),
        .flush(flush),
        .csr_era_rvalue(csr_era_rvalue),
        .csr_eentry_rvalue(csr_eentry_rvalue),
        .exc_wb(exc_wb),
        .ertn_flush(ertn_flush),
        .if_allowin(if_allowin),
        .exc_adef(exc_adef_if),
        .inst_i(inst_sram_rdata),
        .inst_o(inst_if),
        .br_stall(br_stall),
        .inst_data_ok(inst_sram_data_ok),
        .inst_addr_ok(inst_sram_addr_ok),
        
        .inst_req(inst_sram_req),
        .preif_readygo(preif_readygo),
        .pc_o(pc_if),//约定：跟随在流水线寄存器xx_regs后面（输出）的组合�?�辑信号，后�?为xx
        //重取指异常标�?
        .exc_refetch_wb(exc_refetch_wb),
        .refetch_pc_i(refetch_pc_wb),
        .exc_tlbrentry_i(exc_tlbrentry_wb),
        .csr_tlbrentry_i(csr_tlbrentry_rvalue),
        .exc_pif_if(exc_pif_if),
        .exc_ppi_fetch_if(exc_ppi_fetch_if),
        .exc_tlbrentry_fetch_if(exc_tlbrentry_fetch_if)
            );

    id_stage u_id_stage (
        .clk(clk),
        .resetn(resetn),
        .inst_i(inst_if),
        .pc_i(pc_if),
        .if_to_id_valid(if_to_id_valid),
        .id_to_ex_valid(id_to_ex_valid),
        .ex_allowin(ex_allowin),
        .alu_op(alu_op),
        .res_from_mem(res_from_mem_id),
        .gr_we(gr_we_id),
        .mem_we(mem_we_id),
        .dest(dest_id),
        .rf_we(rf_we),
        .rf_waddr(rf_waddr),
        .rf_wdata(rf_wdata),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .br_taken(br_taken),
        .br_target(br_target),
        .pc_o(pc_id),
        
        .id_readygo(id_readygo),
        
        .none_dest(none_dest_id),
        .none_dest_wb(none_dest_wb),
        .none_dest_ex(none_dest_ex),
        .none_dest_mem(none_dest_mem),
        
        .rkd_value(rkd_value_id),
        .id_allowin(id_allowin),
       
        .dest_ex(dest_ex),
        .dest_mem(dest_mem),
        .dest_wb(rf_waddr),
        .wb_valid(wb_valid),
        .ex_valid(ex_valid),
        .mem_to_wb_valid(mem_to_wb_valid),
        
        .ex_result(alu_result),
        .mem_result(final_result),
        .wb_result(rf_wdata),
        
        .res_from_mem_ex(res_from_mem_ex),
        .res_from_mem_mem(res_from_mem_mem),
        
        .mul_div_op(mul_div_op),
        .div_sign(div_sign),
        .ld_type(ld_type_id),
        .st_type(st_type_id),
        
        .has_int(has_int),
        .csr_inst_type(csr_inst_type_id),
        .csr_num(csr_num_id),
        
        .csr_inst_type_ex(csr_inst_type_ex),
        .csr_inst_type_mem(csr_inst_type_mem),
        .csr_inst_type_wb(csr_inst_type_wb),

        .inst_ertn(inst_ertn_id),
        .inst_ertn_ex(inst_ertn_ex),
        .inst_ertn_mem(inst_ertn_mem),  
        .inst_ertn_wb(inst_ertn_wb),
        .flush(flush),
        
        
        .exc_sys_call(exc_sys_call_id),
        .exc_adef_i(exc_adef_if),
        .exc_adef_o(exc_adef_id),
        .exc_break(exc_break_id),
        .exc_ine(exc_ine_id),
        .exc_int(exc_int_id),
        .exc_pif_i(exc_pif_if),
        .exc_pif_o(exc_pif_id),
        .exc_ppi_fetch_i(exc_ppi_fetch_if),
        .exc_tlbrentry_fetch_i(exc_tlbrentry_fetch_if),        
        .exc_ppi_fetch_o(exc_ppi_fetch_id),
        .exc_tlbrentry_fetch_o(exc_tlbrentry_fetch_id),         
        .br_stall(br_stall),
        
        .mem_readygo(mem_readygo),        
                
        .inst_rdcntvl_w(inst_rdcntvl_w),
        .inst_rdcntvh_w(inst_rdcntvh_w),
        .csr_inst_judge_cf_ex(csr_inst_judge_cf_ex),
        .csr_inst_judge_cf_mem(csr_inst_judge_cf_mem),
        .csr_inst_judge_cf_wb(csr_inst_judge_cf_wb),
        
        .data_unfinished(data_unfinished),
        .op_invtlb_id(op_invtlb_id),
        .op_tlb(op_tlb_id),
         //重取指异常标�?
        .exc_refetch_o(exc_refetch_id)

    );
    
      ex_stage u_ex_stage (
        .clk(clk),
        .resetn(resetn),
        .alu_src1_i(alu_src1),
        .alu_src2_i(alu_src2),
        .alu_op_i(alu_op),
        .res_from_mem_i(res_from_mem_id),
        .gr_we_i(gr_we_id),
        .mem_we_i(mem_we_id),
        .dest_i(dest_id),
        .rkd_value_i(rkd_value_id),
        .res_from_mem_o(res_from_mem_ex),
        .res_from_mem_o_va(res_from_mem_ex_va),

        .gr_we_o(gr_we_ex),
        .mem_we_o(mem_we_ex),
        .dest_o(dest_ex),
        .alu_result(alu_result),
        .rkd_value_o(rkd_value_ex),
        .mem_allowin(mem_allowin),
        .id_to_ex_valid(id_to_ex_valid),
        .ex_to_mem_valid(ex_to_mem_valid),
        .pc_i(pc_id),
        .pc_o(pc_ex),
        .data_sram_we(data_sram_we),
        .data_sram_we_va(data_sram_we_va),
        .data_sram_addr(data_sram_addr_va),
        .data_sram_wdata(data_sram_wdata),
        .ex_allowin(ex_allowin),
        
        .none_dest_i(none_dest_id),
        .none_dest_o(none_dest_ex),
        .valid(ex_valid),        
        .mul_div_op_i(mul_div_op),
        
        .div_sign(div_sign),
        .ld_type_i(ld_type_id),
        .ld_type_o(ld_type_ex),
        .st_type_i(st_type_id),
        .st_type(st_type_ex),
        .csr_inst_type_i(csr_inst_type_id),
        .csr_inst_type_o(csr_inst_type_ex),
        .csr_num_i(csr_num_id),
        .csr_num_o(csr_num_ex),
        .inst_ertn_i(inst_ertn_id),
        .inst_ertn_o(inst_ertn_ex),
       
        .exc_sys_call_i(exc_sys_call_id),
        .exc_sys_call_o(exc_sys_call_ex),
        .exc_adef_i(exc_adef_id),
        .exc_adef_o(exc_adef_ex),
        .exc_ale(exc_ale_ex),
        .exc_ine_i(exc_ine_id),
        .exc_ine_o(exc_ine_ex),
        .exc_break_i(exc_break_id),
        .exc_break_o(exc_break_ex),
        .exc_int_i(exc_int_id),
        .exc_int_o(exc_int_ex),
        .exc_pif_i(exc_pif_id),
        .exc_pif_o(exc_pif_ex),
        .exc_ppi_fetch_i(exc_ppi_fetch_id),
        .exc_tlbrentry_fetch_i(exc_tlbrentry_fetch_id),        
        .exc_ppi_fetch_o(exc_ppi_fetch_ex),
        .exc_tlbrentry_fetch_o(exc_tlbrentry_fetch_ex),  

        .exc_pis_ex(exc_pis_ex),
        .exc_pil_ex(exc_pil_ex),
        .exc_pme_ex(exc_pme_ex),
        .exc_tlbrentry_memory_ex(exc_tlbrentry_memory_ex),
        .exc_ppi_memory_ex(exc_ppi_memory_ex),
         
        .inst_ertn_mem(inst_ertn_mem),  
        .inst_ertn_wb(inst_ertn_wb),
        .exc_mem(exc_mem),
        .exc_wb(exc_wb),
                
        .flush(flush),
        .exc_sys_call_wb(exc_sys_call_wb),
        .exc_sys_call_mem(exc_sys_call_mem),
        .csr_inst_judge_cf(csr_inst_judge_cf_ex),
        .inst_rdcntvl_w(inst_rdcntvl_w),
        .inst_rdcntvh_w(inst_rdcntvh_w),
        .counter64_l(counter64_l),
        .counter64_h(counter64_h),
        
        .data_addr_ok(data_sram_addr_ok),
        .data_req(data_sram_req),
        .st_req(st_req),
        .ex_readygo(ex_readygo),
      
        .op_tlbsrch_ex(op_tlbsrch_ex),
        .op_invtlb_id(op_invtlb_id),
        .invtlb_valid(invtlb_valid_ex),
        .invtlb_op(invtlb_op_ex),
        .op_tlb_i(op_tlb_id),
        .op_tlb_o(op_tlb_ex),
         //重取指异常标�?
        .exc_refetch_i(exc_refetch_id),
        .exc_refetch_o(exc_refetch_ex),
        //tlbsrch写后读冲突解�?
        .change_csr_mem(change_csr_mem),
        .change_csr_wb(change_csr_wb)
    );
    
    mem_stage u_mem_stage (
        .clk(clk),
        .resetn(resetn),
        .res_from_mem_i(res_from_mem_ex),
        .gr_we_i(gr_we_ex),
        .mem_we_i(mem_we_ex),
        .dest_i(dest_ex),
        .alu_result_i(alu_result),
        .gr_we_o(gr_we_mem),
        .mem_we_o(mem_we_mem),
        .dest_o(dest_mem),
        .final_result(final_result),
        .wb_allowin(wb_allowin),
        .ex_to_mem_valid(ex_to_mem_valid),
        .rkd_value(rkd_value_ex),
        
        .res_from_mem_o(res_from_mem_mem),
        
        .none_dest_i(none_dest_ex),
        .none_dest_o(none_dest_mem),
        .rkd_value_o(rkd_value_mem),
        
        .data_sram_rdata(data_sram_rdata),
        .mem_to_wb_valid(mem_to_wb_valid),
        .pc_i(pc_ex),
        .pc_o(pc_mem),
        .mem_allowin(mem_allowin),
        .valid(mem_valid),
        .ld_type(ld_type_ex),
        .csr_inst_type_i(csr_inst_type_ex),
        .csr_inst_type_o(csr_inst_type_mem),
        .csr_num_i(csr_num_ex),
        .csr_num_o(csr_num_mem) ,
        .inst_ertn_i(inst_ertn_ex),
        .inst_ertn_o(inst_ertn_mem),
  
        .exc_sys_call_i(exc_sys_call_ex),
        .exc_sys_call_o(exc_sys_call_mem),
        .exc_adef_i(exc_adef_ex),
        .exc_adef_o(exc_adef_mem),
        .exc_ale_i(exc_ale_ex),
        .exc_ale_o(exc_ale_mem),
        .exc_ine_i(exc_ine_ex),
        .exc_ine_o(exc_ine_mem),
        .exc_break_i(exc_break_ex),
        .exc_break_o(exc_break_mem),
        .exc_int_i(exc_int_ex),
        .exc_int_o(exc_int_mem),
        .exc_pil_i(exc_pil_ex),
        .exc_pis_i(exc_pis_ex),
        .exc_pif_i(exc_pif_ex),
        .exc_pme_i(exc_pme_ex),
        .exc_pil_o(exc_pil_mem),
        .exc_pis_o(exc_pis_mem),
        .exc_pif_o(exc_pif_mem),
        .exc_pme_o(exc_pme_mem),
        .exc_ppi_memory_i(exc_ppi_memory_ex),
        .exc_tlbrentry_memory_i(exc_tlbrentry_memory_ex),
        .exc_ppi_fetch_i(exc_ppi_fetch_ex),
        .exc_tlbrentry_fetch_i(exc_tlbrentry_fetch_ex),        
        .exc_ppi_memory_o(exc_ppi_memory_mem),
        .exc_tlbrentry_memory_o(exc_tlbrentry_memory_mem),
        .exc_ppi_fetch_o(exc_ppi_fetch_mem),
        .exc_tlbrentry_fetch_o(exc_tlbrentry_fetch_mem),     
        .exc_mem(exc_mem),
                
        .vaddr(vaddr_mem),
        .flush(flush),
        .csr_inst_judge_cf(csr_inst_judge_cf_mem),
        .data_data_ok(data_sram_data_ok),
        .st_req(st_req),
        .ex_readygo(ex_readygo),
        .mem_readygo(mem_readygo),
        
        .data_addr_ok(data_sram_addr_ok),
        .data_req(data_sram_req),
        .data_unfinished_o(data_unfinished),
        .op_tlb_i(op_tlb_ex),
        .op_tlb_o(op_tlb_mem),
         //重取指异常标�?
        .exc_refetch_i(exc_refetch_ex),
        .exc_refetch_o(exc_refetch_mem),
        //tlbsrch写后读冲�?
        .change_csr_o(change_csr_mem)
    );
    
        wb_stage u_wb_stage (
        .clk(clk),
        .resetn(resetn),
        .none_dest_i(none_dest_mem),
        .none_dest_o(none_dest_wb),        
        .gr_we(gr_we_mem),
        .mem_we(mem_we_mem),
        .dest_i(dest_mem),
        .final_result_i(final_result),
        .mem_to_wb_valid(mem_to_wb_valid),
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_we(debug_wb_rf_we),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        .rf_we(rf_we),
        .wb_allowin(wb_allowin),
        .rf_waddr(rf_waddr),
        .rf_wdata(rf_wdata),
        .pc_i(pc_mem),
        .valid(wb_valid),
        .dest_o(dest_wb),
        
        .ertn_flush(ertn_flush),
        .wb_ecode(wb_ecode),
        .wb_esubcode(wb_esubcode),
        
        .csr_rvalue(csr_rvalue),
        .rkd_value_i(rkd_value_mem),
        .csr_inst_type_i(csr_inst_type_mem),
        .csr_inst_type_o(csr_inst_type_wb),
        .csr_num_i(csr_num_mem),
        .csr_num_o(csr_num_wb),
        .rkd_value_o(rkd_value_wb),
        .csr_wmask(csr_wmask),
        .inst_ertn_i(inst_ertn_mem),
        .inst_ertn_o(inst_ertn_wb),

        .exc_sys_call_i(exc_sys_call_mem),
        .exc_sys_call_o(exc_sys_call_wb),
        .exc_adef_i(exc_adef_mem),
        .exc_adef_o(exc_adef_wb),
        .exc_ale_i(exc_ale_mem),
        .exc_ale_o(exc_ale_wb),
        .exc_ine_i(exc_ine_mem),
        .exc_ine_o(exc_ine_wb),
        .exc_break_i(exc_break_mem),
        .exc_break_o(exc_break_wb),
        .exc_int_i(exc_int_mem),
        .exc_int_o(exc_int_wb),
        .exc_pil_i(exc_pil_mem),
        .exc_pis_i(exc_pis_mem),
        .exc_pif_i(exc_pif_mem),
        .exc_pme_i(exc_pme_mem),
        .exc_pil_o(exc_pil_wb),
        .exc_pis_o(exc_pis_wb),
        .exc_pif_o(exc_pif_wb),
        .exc_pme_o(exc_pme_wb),
        .exc_tlb_o(exc_tlb),  
        .exc_ppi_o(exc_ppi_wb),
        .exc_tlbrentry_o(exc_tlbrentry_wb),  
        .exc_ppi_memory_i(exc_ppi_memory_mem),
        .exc_tlbrentry_memory_i(exc_tlbrentry_memory_mem),
        .exc_ppi_fetch_i(exc_ppi_fetch_mem),
        .exc_tlbrentry_fetch_i(exc_tlbrentry_fetch_mem),
        .vaddr_i(vaddr_mem),
        .vaddr_o(vaddr_wb),
        
        .csr_we(csr_we),
        .exc_wb(exc_wb),
        .flush(flush),
        .csr_inst_judge_cf(csr_inst_judge_cf_wb),
        .op_tlb_i(op_tlb_mem),
        .op_tlb_o(op_tlb_wb),
        .op_tlbrd_wb(op_tlbrd_wb),
        .op_tlbwr_wb(op_tlbwr_wb),
        .op_tlbfill_wb(op_tlbfill_wb),
         //重取指异常标�?
        .exc_refetch_i(exc_refetch_mem),
        .exc_refetch_o(exc_refetch_wb),
        .refetch_pc_o(refetch_pc_wb),
        //tlbsrch写后读冲�?
        .change_csr_o(change_csr_wb)
    );
    
       CSR u_csr (
        .clk(clk),
        .resetn(resetn),
        .csr_re(csr_re),
        .csr_num(csr_num_wb),
        .csr_rvalue(csr_rvalue),//
        .csr_we(csr_we),//
        .csr_wmask(csr_wmask),
        .csr_wvalue(rkd_value_wb),
        .exc_entry(exc_entry),
        .has_int(has_int),
        .ertn_flush(ertn_flush),
        .wb_exc(exc_wb & !exc_refetch_wb),
        .wb_ecode(wb_ecode),
        .wb_esubcode(wb_esubcode),
        .hw_int_in(hw_int_in),
        .ipi_int_in(ipi_int_in),
        .wb_pc(debug_wb_pc),
        .csr_era_rvalue(csr_era_rvalue),
        .csr_eentry_rvalue(csr_eentry_rvalue),
        .wb_vaddr(vaddr_wb),
        .exc_tlb(exc_tlb),
        .exc_tlbrentry(exc_tlbrentry_wb),
        //from mycpu and to tlb
        .op_tlbrd_wb(op_tlbrd_wb),
        .op_tlbwr_wb(op_tlbwr_wb),
        .op_tlbsrch_ex(op_tlbsrch_ex),
        .op_tlbfill_wb(op_tlbfill_wb),
        .op_tlbrd_csr(op_tlbrd_csr),
        .op_tlbwr_csr(op_tlbwr_csr),
        .op_tlbsrch_csr(op_tlbsrch_csr),
        .op_tlbfill_csr(op_tlbfill_csr),
        .invtlb_op_i(invtlb_op_ex),
        .invtlb_valid_i(invtlb_valid_ex),        
        .invtlb_op_o(invtlb_op),
        .invtlb_valid_o(invtlb_valid), 
        //to tlb
        .csr_tlbehi_vppn_rvalue(csr_tlbehi_vppn_rvalue),  
        .csr_tlbidx_index_rvalue(csr_tlbidx_index_rvalue),
        .csr_asid_asid_rvalue(csr_asid_asid_rvalue),
        .csr_tlbrentry_rvalue(csr_tlbrentry_rvalue),
        .csr_dmw0_rvalue(csr_dmw0_rvalue),
        .csr_dmw1_rvalue(csr_dmw1_rvalue),
        .csr_crmd_da_rvalue(csr_crmd_da_rvalue),
        .csr_crmd_pg_rvalue(csr_crmd_pg_rvalue),
        .csr_crmd_plv_rvalue(csr_crmd_plv_rvalue),
         //from tlb
        .s1_found(s1_found),
        .s1_index(s1_index),
        .r_e(r_e),
        .r_vppn(r_vppn),
        .r_asid(r_asid),
        .r_g(r_g),
        .r_ps(r_ps),
        .r_ppn0(r_ppn0),
        .r_plv0(r_plv0),
        .r_mat0(r_mat0),
        .r_d0(r_d0),
        .r_v0(r_v0),
        .r_ppn1(r_ppn1),
        .r_plv1(r_plv1),
        .r_mat1(r_mat1),
        .r_d1(r_d1),
        .r_v1(r_v1),
        .we(we),
        .w_e(w_e),
        .w_vppn(w_vppn),
        .w_asid(w_asid),
        .w_g(w_g),
        .w_ps(w_ps),
        .w_index(w_index),
        .w_ppn0(w_ppn0),
        .w_plv0(w_plv0),
        .w_mat0(w_mat0),
        .w_d0(w_d0),
        .w_v0(w_v0),
        .w_ppn1(w_ppn1),
        .w_plv1(w_plv1),
        .w_mat1(w_mat1),
        .w_d1(w_d1),
        .w_v1(w_v1)
     );
    
    sram_axi_bridge u_sram_axi_bridge (
        .clk(clk),
        .resetn(resetn),
        .inst_sram_req(rd_req_icache),// & ~exc_tlb_fetch_trans),
        .inst_sram_wr(1'b0),
        .inst_sram_size(2'h2),
        .inst_sram_wstrb(4'b0),
        .inst_sram_addr(rd_addr_icache),
        .inst_sram_wdata(wr_data_icache),
        .inst_sram_addr_ok(rd_rdy_icache),
        .inst_sram_data_ok(ret_valid_icache),
        .inst_sram_rdata(ret_data_icache),
        .data_sram_req(data_sram_req),//& ~exc_tlb_memory_trans),
        .data_sram_wr(data_sram_wr),
        .data_sram_size(data_sram_size),
        .data_sram_wstrb(data_sram_wstrb),
        .data_sram_addr(data_sram_addr),
        .data_sram_wdata(data_sram_wdata),
        .data_sram_addr_ok(data_sram_addr_ok),
        .data_sram_data_ok(data_sram_data_ok),
        .data_sram_rdata(data_sram_rdata),
        .arid(arid),
        .araddr(araddr),
        .arlen(arlen),
        .arsize(arsize),
        .arburst(arburst),
        .arlock(arlock),
        .arcache(arcache),
        .arprot(arprot),
        .arvalid(arvalid),
        .arready(arready),
        .rid(rid),
        .rdata(rdata),
        .rresp(rresp),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready),
        .awid(awid),
        .awaddr(awaddr),
        .awlen(awlen),
        .awsize(awsize),
        .awburst(awburst),
        .awlock(awlock),
        .awcache(awcache),
        .awprot(awprot),
        .awvalid(awvalid),
        .awready(awready),
        .wid(wid),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready),
        .bid(bid),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .br_taken(br_taken),
        .flush(flush),
        .st_req(st_req),
        //last sign
        .rlast_inst(ret_last_icache),
        .rlast_data()
    );

    counter64 u_counter64 (
    .clk(clk),
    .rst_n(resetn),
    .count({counter64_h,counter64_l})
);

   tlb u_tlb (
        .clk(clk),
        .s0_vppn(s0_vppn),
        .s0_va_bit12(s0_va_bit12),
        .s0_asid(s0_asid),
        .s0_found(s0_found),
        .s0_index(s0_index),
        .s0_ppn(s0_ppn),
        .s0_ps(s0_ps),
        .s0_plv(s0_plv),
        .s0_mat(s0_mat),
        .s0_d(s0_d),
        .s0_v(s0_v),
        .s1_vppn(s1_vppn),
        .s1_va_bit12(s1_va_bit12),
        .s1_asid(s1_asid),
        .s1_found(s1_found),
        .s1_index(s1_index),
        .s1_ppn(s1_ppn),
        .s1_ps(s1_ps),
        .s1_plv(s1_plv),
        .s1_mat(s1_mat),
        .s1_d(s1_d),
        .s1_v(s1_v),
        .invtlb_valid(invtlb_valid),
        .invtlb_op(invtlb_op),
        .we(we),
        .w_e(w_e),
        .w_vppn(w_vppn),
        .w_asid(w_asid),
        .w_g(w_g),
        .w_ps(w_ps),
        .w_index(w_index),
        .w_ppn0(w_ppn0),
        .w_plv0(w_plv0),
        .w_mat0(w_mat0),
        .w_d0(w_d0),
        .w_v0(w_v0),
        .w_ppn1(w_ppn1),
        .w_plv1(w_plv1),
        .w_mat1(w_mat1),
        .w_d1(w_d1),
        .w_v1(w_v1),
        .r_index(r_index),
        .r_e(r_e),
        .r_vppn(r_vppn),
        .r_asid(r_asid),
        .r_g(r_g),
        .r_ps(r_ps),
        .r_ppn0(r_ppn0),
        .r_plv0(r_plv0),
        .r_mat0(r_mat0),
        .r_d0(r_d0),
        .r_v0(r_v0),
        .r_ppn1(r_ppn1),
        .r_plv1(r_plv1),
        .r_mat1(r_mat1),
        .r_d1(r_d1),
        .r_v1(r_v1)
    );

    addrtrans u_addrtrans (
        .inst_sram_addr_va(inst_sram_addr_va),
        .data_sram_addr_va(data_sram_addr_va),
        .st_sign(|data_sram_we_va),
        .ld_sign(res_from_mem_ex_va ),//& ~data_sram_wr),
        .inst_paddr(inst_sram_addr),
        .data_paddr(data_sram_addr),
        .csr_dmw0_rvalue(csr_dmw0_rvalue),
        .csr_dmw1_rvalue(csr_dmw1_rvalue),
        .csr_crmd_da_rvalue(csr_crmd_da_rvalue),
        .csr_crmd_pg_rvalue(csr_crmd_pg_rvalue),
        .csr_crmd_plv_rvalue(csr_crmd_plv_rvalue),
        .s0_found(s0_found),
        .s0_index(s0_index),
        .s0_ppn(s0_ppn),
        .s0_ps(s0_ps),
        .s0_plv(s0_plv),
        .s0_mat(s0_mat),
        .s0_d(s0_d),
        .s0_v(s0_v),
        .s1_found(s1_found),
        .s1_index(s1_index),
        .s1_ppn(s1_ppn),
        .s1_ps(s1_ps),
        .s1_plv(s1_plv),
        .s1_mat(s1_mat),
        .s1_d(s1_d),
        .s1_v(s1_v),
        .exc_pil_o(exc_pil_ex),
        .exc_pis_o(exc_pis_ex),
        .exc_pif_o(exc_pif_if),
        .exc_pme_o(exc_pme_ex),
        .tlbrentry_memory_o(exc_tlbrentry_memory_ex),
        .tlbrentry_fetch_o(exc_tlbrentry_fetch_if),
        .ppi_fetch_o(exc_ppi_fetch_if),
        .ppi_memory_o(exc_ppi_memory_ex),
        .exc_tlb_fetch(exc_tlb_fetch_trans),
        .exc_tlb_memory(exc_tlb_memory_trans)
    );
reg [19:0] icache_tag;
always@(posedge clk)begin
    if(!resetn)
        icache_tag <= 20'b0;
    else
        icache_tag <= inst_sram_addr[31:12];    
end


cache icache(
    .clk    (clk),
    .resetn (resetn),
    .valid  (inst_sram_req),
    .op     (inst_sram_wr ),
    .index  (inst_sram_addr_va[11:4]  ),
    .tag    (inst_sram_addr[31:12]),
    .offset (inst_sram_addr_va[3:0] ),
    .wstrb  (inst_sram_wstrb),
    .wdata  (inst_sram_wdata),

    .addr_ok(inst_sram_addr_ok),
    .data_ok(inst_sram_data_ok),
    .rdata  (inst_sram_rdata ),

    .rd_req   (rd_req_icache   ),
    .rd_type  (rd_type_icache  ),
    .rd_addr  (rd_addr_icache  ),
    .rd_rdy   (rd_rdy_icache   ),
    .ret_valid(ret_valid_icache),
    .ret_last (ret_last_icache ),
    .ret_data (ret_data_icache ),
    

    .wr_req  (wr_req_icache  ),
    .wr_type (wr_type_icache ),
    .wr_addr (wr_addr_icache ),
    .wr_wstrb(wr_wstrb_icache),
    .wr_data (wr_data_icache ),
    .wr_rdy  (1'b1  )
);
    endmodule
