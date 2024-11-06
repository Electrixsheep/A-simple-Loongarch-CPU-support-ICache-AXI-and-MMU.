
module mem_stage(
    input wire clk,
    input wire resetn,
    input wire res_from_mem_i,
    input wire gr_we_i,
    input wire mem_we_i,
    input wire [4:0] dest_i,
    input wire [31:0] alu_result_i,

    output wire gr_we_o,
    output wire mem_we_o,
    output wire [4:0] dest_o,
    output wire [31:0] final_result,
    input  wire wb_allowin,
    input  wire ex_to_mem_valid,
    input  wire [31:0]rkd_value,
    
    output wire res_from_mem_o, 

    input wire none_dest_i,
    output wire none_dest_o,
    input  wire [31:0] data_sram_rdata ,
    output wire mem_to_wb_valid,
    input wire [31:0] pc_i,
    output wire [31:0] pc_o,
    output wire mem_allowin,
    output wire valid,
    input wire [2:0] ld_type,
    input wire [1:0] csr_inst_type_i,
    output wire [1:0] csr_inst_type_o,
    input wire [13:0] csr_num_i,
    output wire [13:0] csr_num_o,
    output wire [31:0] rkd_value_o,
    input wire inst_ertn_i,
    output wire inst_ertn_o,
    
    input wire exc_sys_call_i,
    output wire exc_sys_call_o,
    input wire exc_adef_i,
    output wire exc_adef_o,
    input wire exc_ale_i,
    output wire exc_ale_o,
    input wire exc_ine_i,
    output wire exc_ine_o,
    input wire exc_break_i,
    output wire exc_break_o, 
    input wire exc_int_i,
    output wire exc_int_o,       
    input wire flush,
    output wire csr_inst_judge_cf,
    output wire [31:0] vaddr,

    input wire st_req,
    input wire data_data_ok,
    input wire ex_readygo,
    output wire exc_mem,
    output wire mem_readygo,
    
    input wire data_addr_ok,
    input wire data_req,
    output wire data_unfinished_o,
    input wire [2:0] op_tlb_i,
    output wire [2:0] op_tlb_o,
    //重取�?
    input wire exc_refetch_i,
    output wire exc_refetch_o,
    //tlbsrch写后读冲�?
    output wire change_csr_o,
    //renew
    input wire exc_pil_i,
    input wire exc_pis_i,
    input wire exc_pif_i,
    input wire exc_pme_i,
    input wire exc_ppi_memory_i,
    input wire exc_tlbrentry_memory_i,
    input wire exc_ppi_fetch_i,
    input wire exc_tlbrentry_fetch_i,
    output wire exc_pil_o,
    output wire exc_pis_o,
    output wire exc_pif_o,
    output wire exc_pme_o,
    output wire exc_ppi_memory_o,
    output wire exc_tlbrentry_memory_o,
    output wire exc_ppi_fetch_o,
    output wire exc_tlbrentry_fetch_o
);
reg none_dest_reg;
reg res_from_mem_reg;
reg st_req_reg;
reg gr_we_reg;
reg mem_we_reg;
reg [4:0] dest_reg;
reg [31:0] alu_result_reg;
reg [31:0] rkd_value_reg;
reg [31:0] pc_reg;
reg  mem_valid;
wire [31:0] mem_result;
wire [1:0] ld_select;
wire st_req_o;
reg [2:0] ld_type_reg;
reg [13:0] csr_num_reg;
reg [1:0] csr_inst_type_reg;
reg inst_ertn_reg;
//exc reg
reg exc_sys_call_reg;
reg exc_adef_reg;
reg exc_ale_reg;
reg exc_ine_reg;
reg exc_break_reg;
reg exc_int_reg;
reg exc_refetch_reg;
reg exc_pil_reg;
reg exc_pis_reg;
reg exc_pif_reg;
reg exc_pme_reg;
reg exc_ppi_memory_reg;
reg exc_tlbrentry_memory_reg;
reg exc_ppi_fetch_reg;
reg exc_tlbrentry_fetch_reg;
reg [2:0] op_tlb_reg;
reg data_unfinished;

assign data_unfinished_o = data_unfinished;
always@(posedge clk)begin
    if(!resetn)
        data_unfinished <= 1'b0;
    else if(data_req & data_addr_ok)
        data_unfinished <= 1'b1;
    else if(data_data_ok)
        data_unfinished <= 1'b0;    
end

assign inst_ertn_o = inst_ertn_reg;
assign mem_readygo = (!res_from_mem_o & !st_req_o) | ( buf_valid | data_data_ok );  //可能关键
assign mem_allowin = !mem_valid || mem_readygo && wb_allowin;
assign mem_to_wb_valid = mem_valid && mem_readygo;
assign pc_o = pc_reg;
assign valid = mem_to_wb_valid;
assign ld_select = alu_result_reg [1:0];
assign rkd_value_o = rkd_value_reg;
assign st_req_o = st_req_reg;
//异常
assign exc_sys_call_o = exc_sys_call_reg;
assign exc_adef_o = exc_adef_reg;
assign exc_ale_o = exc_ale_reg;
assign exc_ine_o = exc_ine_reg;
assign exc_break_o = exc_break_reg;
assign exc_int_o = exc_int_reg;
assign exc_refetch_o = exc_refetch_reg;
assign exc_pil_o = exc_pil_reg;
assign exc_pif_o = exc_pif_reg;
assign exc_pis_o = exc_pis_reg;
assign exc_pme_o = exc_pme_reg;
assign exc_ppi_memory_o = exc_ppi_memory_reg;
assign exc_tlbrentry_memory_o = exc_tlbrentry_memory_reg;
assign exc_ppi_fetch_o = exc_ppi_fetch_reg;
assign exc_tlbrentry_fetch_o = exc_tlbrentry_fetch_reg;
assign exc_mem = (exc_sys_call_o | exc_adef_o | exc_ale_o | exc_ine_o    
                  |  exc_break_o | exc_int_o | exc_refetch_o | exc_pil_o | exc_pif_o
                  | exc_pis_o | exc_pme_o | exc_ppi_memory_o | exc_tlbrentry_memory_o
                  | exc_ppi_fetch_o | exc_tlbrentry_fetch_o) & mem_valid ; 
assign op_tlb_o = op_tlb_reg;
assign csr_inst_judge_cf =  (csr_inst_type_o[0] | csr_inst_type_o[1]) &{mem_valid}; 
//���ַ
assign vaddr = alu_result_reg;
//tlbsrch写后读冲�?
assign change_csr_o = mem_valid & csr_inst_type_reg[0] | (op_tlb_reg[1] & op_tlb_reg[0]);    //csrwr | csrxchg | tlbrd
always@(posedge clk )begin
    if (!resetn) begin
        mem_valid <= 1'b0;
    end
    else if (flush) begin
        mem_valid <= 1'b0;
    end
    else if (mem_allowin) begin
        mem_valid <= ex_to_mem_valid;
    end
end
        
always@ (posedge clk )begin
    if (!resetn) begin
            st_req_reg <= 1'b0;
            res_from_mem_reg <= 1'b0;
            gr_we_reg <= 1'b0;
            mem_we_reg <= 1'b0;
            dest_reg <= 5'b0;
            alu_result_reg <= 32'b0;
            rkd_value_reg <=32'b0;
            pc_reg <= 32'h1bfffffc;
            none_dest_reg <= 1'b0;
            ld_type_reg <= 3'b0;
            csr_num_reg <= 14'b0;
            csr_inst_type_reg <= 2'b0;
            inst_ertn_reg <= 1'b0;
            exc_sys_call_reg <= 1'b0;
            exc_adef_reg <= 1'b0;
            exc_ale_reg <= 1'b0;
            exc_ine_reg <= 1'b0;
            exc_break_reg <= 1'b0;
            exc_int_reg <= 1'b0;
            op_tlb_reg <= 3'b0;
            exc_refetch_reg <= 1'b0;
            exc_pil_reg <= 1'b0;
            exc_pis_reg <= 1'b0;
            exc_pif_reg <= 1'b0;
            exc_pme_reg <= 1'b0;
            exc_ppi_memory_reg <= 1'b0;
            exc_ppi_fetch_reg <= 1'b0;
            exc_tlbrentry_memory_reg <= 1'b0;
            exc_tlbrentry_fetch_reg <= 1'b0;
    end
    else if (ex_to_mem_valid && mem_allowin) begin     
            st_req_reg <= st_req; 
            res_from_mem_reg <= res_from_mem_i;
            gr_we_reg <= gr_we_i;
            mem_we_reg <= mem_we_i;
            dest_reg <= dest_i;
            alu_result_reg <= alu_result_i;
            rkd_value_reg <= rkd_value;
            pc_reg <= pc_i;    
            none_dest_reg <= none_dest_i;
            ld_type_reg <= ld_type;
            csr_num_reg <= csr_num_i;
            csr_inst_type_reg <= csr_inst_type_i;
            inst_ertn_reg <= inst_ertn_i;
            exc_sys_call_reg <= exc_sys_call_i;
            exc_adef_reg <= exc_adef_i;
            exc_ale_reg <= exc_ale_i;
            exc_ine_reg <= exc_ine_i;
            exc_break_reg <= exc_break_i;
            exc_int_reg <= exc_int_i;
            op_tlb_reg <= op_tlb_i;
            exc_refetch_reg <= exc_refetch_i;
            exc_pil_reg <= exc_pil_i;
            exc_pis_reg <= exc_pis_i;
            exc_pif_reg <= exc_pif_i;
            exc_pme_reg <= exc_pme_i;
            exc_ppi_memory_reg <= exc_ppi_memory_i;
            exc_ppi_fetch_reg <= exc_ppi_fetch_i;
            exc_tlbrentry_memory_reg <= exc_tlbrentry_memory_i;
            exc_tlbrentry_fetch_reg <= exc_tlbrentry_fetch_reg;            
    end
end
   
assign gr_we_o = gr_we_reg;
assign mem_we_o = mem_we_reg;
assign dest_o = dest_reg /*&& {5{mem_valid}}*/;

wire op_is_ld_w;
wire op_is_ld_b;
wire op_is_ld_h;
wire op_is_ld_bu;
wire op_is_ld_hu;
assign op_is_ld_w = (ld_type_reg == 3'd1);
assign op_is_ld_b = (ld_type_reg == 3'd2);
assign op_is_ld_h = (ld_type_reg == 3'd3);
assign op_is_ld_bu = (ld_type_reg == 3'd4);
assign op_is_ld_hu = (ld_type_reg == 3'd5);

wire [7:0] mem_rdata_b;
wire [15:0] mem_rdata_h; 
assign mem_rdata_b = ({8{ld_select == 2'b00}} & data_sram_rdata[7:0]) 
                   | ({8{ld_select == 2'b01}} & data_sram_rdata[15:8])   
                   | ({8{ld_select == 2'b10}} & data_sram_rdata[23:16]) 
                   | ({8{ld_select == 2'b11}} & data_sram_rdata[31:24]);  
assign mem_rdata_h = (ld_select == 2'b00) ? data_sram_rdata[15:0] : data_sram_rdata[31:16];                   
assign res_from_mem_o =  res_from_mem_reg;
assign none_dest_o = none_dest_reg;    
assign mem_result  = op_is_ld_w ? data_sram_rdata :
                 |   op_is_ld_b ?  {{24{mem_rdata_b[7]}},mem_rdata_b} :
                 |   op_is_ld_h ? {{16{mem_rdata_h[15]}},mem_rdata_h}: 
                     op_is_ld_bu ? {24'b0,mem_rdata_b} :
                      /*op_is_ld_hu ? */{16'b0,mem_rdata_h} ;
assign csr_inst_type_o = csr_inst_type_reg;
assign csr_num_o = csr_num_reg;
assign final_result = res_from_mem_reg ? 
                   (  buf_valid ?                   data_buf :
                                                     mem_result )
                                                    : alu_result_reg;
assign vaddr =  alu_result_reg;

//////////////////////////////////////////////////////////////////////////////////临时缓存
reg [31:0] data_buf;
reg buf_valid;
always@(posedge clk)begin
    if(!resetn)begin
        buf_valid <= 1'b0;
    end
    else if(flush)begin
        buf_valid <= 1'b0;
    end
    else if (mem_readygo & (res_from_mem_o /*| st_req_o*/)) begin 
        data_buf <= mem_result;
        buf_valid <= !wb_allowin; 
    end 
end
//////////////////////////////////////////////////////////////////////////////////P201
reg flush_throw;//默认异常清理时最多只�?丢弃后续返回的一个数�?
always @ (posedge clk)begin 
    if(!resetn)begin
        flush_throw <= 1'b0;
    end
    else if ( flush & (res_from_mem_o) & ((ex_readygo) | (!mem_allowin & !mem_readygo) ))begin //优先级或许可以取�?/优化
        flush_throw <= 1'b1;
    end
    else if (data_data_ok) begin
        flush_throw <= 1'b0;
    end
    

end

//////////////////////////////////////////////////////////////////////////////////
endmodule
