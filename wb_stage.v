
module wb_stage(
input wire clk,
input wire resetn,
input wire gr_we,
input wire mem_we,

input wire [4:0] dest_i,
output wire [4:0] dest_o,

input wire [31:0] final_result_i,
input wire mem_to_wb_valid,
output wire [31:0] debug_wb_pc,
output wire [ 3:0] debug_wb_rf_we,
output wire [ 4:0] debug_wb_rf_wnum,
output wire [31:0] debug_wb_rf_wdata,
output wire rf_we,
output wire [ 4:0] rf_waddr,
output wire [31:0] rf_wdata,
input  wire [31:0] pc_i,
output wire wb_allowin,

input wire none_dest_i,
output wire none_dest_o,
output wire valid,

output wire ertn_flush,
output wire [5:0] wb_ecode,
output wire [8:0] wb_esubcode,
input wire [1:0] csr_inst_type_i,
output wire [1:0] csr_inst_type_o,
input wire [13:0] csr_num_i,
output wire [13:0] csr_num_o,
input wire [31:0] rkd_value_i,
output wire [31:0] rkd_value_o,
input wire [31:0] csr_rvalue,
output wire [31:0] csr_wmask,
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
//renewe sign up
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
output wire exc_ppi_o,
//renew sign down
output wire exc_tlbrentry_o,

input wire [31:0] vaddr_i,
output wire [31:0] vaddr_o,
output wire csr_we,
output wire flush ,
output wire exc_wb,
input wire csr_inst_judge_cf,
input wire [2:0] op_tlb_i,
output wire [2:0] op_tlb_o,

output wire op_tlbrd_wb,
output wire op_tlbwr_wb,
output wire op_tlbfill_wb,
//tlb例外
output wire exc_tlb_o,
//重取�?
output wire exc_refetch_o,
output wire [31:0] refetch_pc_o,
input wire exc_refetch_i,
//tlbsrch写后读冲�?
output wire change_csr_o
    );
wire out_allow;
assign out_allow = 1'b1;
reg  wb_valid;
reg [31:0] rkd_value_reg;
reg none_dest_reg;
reg [31:0] pc_reg;
reg gr_we_reg;
reg mem_we_reg;
reg [4:0] dest_reg;
reg [31:0] final_result_reg;
reg mem_to_wb_valid_reg;
wire wb_readygo;
wire [31:0] wb_result;
wire tlbrentry_type_o;
wire ppi_type_o;
reg [13:0] csr_num_reg;
reg [1:0] csr_inst_type_reg;
reg inst_ertn_reg;
//异常
reg exc_sys_call_reg;
reg exc_adef_reg;
reg exc_ale_reg;
reg exc_ine_reg;
reg exc_break_reg;
reg exc_int_reg;
reg exc_pil_reg;
reg exc_pis_reg;
reg exc_pif_reg;
reg exc_pme_reg;
reg exc_ppi_memory_reg;
reg exc_ppi_fetch_reg;
reg exc_tlbrentry_memory_reg;
reg exc_tlbrentry_fetch_reg;

reg exc_refetch_reg;
reg [31:0] vaddr_reg;
reg [2:0] op_tlb_reg;
//vaddr judge                                             
assign vaddr_o =((exc_tlbrentry_o & ~tlbrentry_type_o) | exc_adef_o | exc_pif_o | (exc_ppi_o & ~ppi_type_o))
               ? pc_reg : vaddr_reg;    //vaddr_reg actually stands for ld/st vaddr
//异常

assign exc_sys_call_o = exc_sys_call_reg ;
assign exc_adef_o = exc_adef_reg  ;//int>adef
assign exc_ale_o = exc_ale_reg; //int>pi
assign exc_ine_o = exc_ine_reg;//int>pif>ine,when appears at the same time
assign exc_break_o = exc_break_reg ;//pif first,when appears at the same time;
assign exc_int_o = exc_int_reg;
assign exc_pil_o = exc_pil_reg;
assign exc_pis_o = exc_pis_reg;
assign exc_pif_o = exc_pif_reg ;
assign exc_pme_o = exc_pme_reg ;
assign exc_ppi_o = exc_ppi_memory_reg | exc_ppi_fetch_reg;
assign exc_tlbrentry_o = (exc_tlbrentry_memory_reg | exc_tlbrentry_fetch_reg) & wb_valid;
//fetch exc first
assign tlbrentry_type_o = exc_tlbrentry_memory_reg & ~exc_tlbrentry_fetch_reg;//high stands for exc is coming from memory
assign ppi_type_o = exc_ppi_memory_reg & ~exc_ppi_fetch_reg;//high stands for exc is coming from memory
assign exc_wb =  wb_valid & (exc_sys_call_o | exc_adef_o | exc_ale_o | exc_ine_o 
               | exc_break_o | exc_int_o | exc_refetch_o | exc_pil_o | exc_pif_o
               | exc_pis_o | exc_pme_o | exc_ppi_o | exc_tlbrentry_o) ;
assign inst_ertn_o = inst_ertn_reg;
//重取�?
assign refetch_pc_o = pc_reg;
assign exc_refetch_o = wb_valid & exc_refetch_reg;
//流水线控�?
assign wb_readygo = 1'b1;  //可能关键
assign wb_allowin = !wb_valid || wb_readygo && out_allow;
assign valid= wb_valid;
assign csr_inst_type_o = csr_inst_type_reg;
assign csr_num_o = csr_num_reg;
assign csr_wmask =/* csr_inst_type_o == 2'b0  ? 31'h0 :  */   final_result_reg;
assign csr_we = ! (csr_inst_type_o == 2'b0) & wb_valid;
assign ertn_flush = inst_ertn_o & wb_valid;
assign flush = (ertn_flush | exc_wb) & wb_valid;
//it shall be priority logic
assign wb_ecode =  exc_int_o ? 6'h0 ://sys
                  exc_adef_o ? 6'h8 ://if
                  exc_tlbrentry_fetch_reg ? 6'h3f :                   
                  exc_pif_o ? 6'h3 :
                  exc_ppi_fetch_reg ? 6'h7 :
                  exc_sys_call_o ? 6'hb ://id
                  exc_break_o ? 6'hc :
                  exc_ine_o ? 6'hd :
                  exc_ale_o ? 6'h9 ://ex
                  exc_tlbrentry_memory_reg ? 6'h3f :                  
                  exc_pil_o ? 6'h1 :
                  exc_pis_o ? 6'h2 :
                  exc_ppi_memory_reg ? 6'h7 :
                  exc_pme_o ? 6'h4 :
                  ~exc_wb ? 6'h1a :
                  6'h0; // defalut

assign csr_inst_judge_cf =  (csr_inst_type_o[0] | csr_inst_type_o[1]) &{wb_valid}; 
assign wb_esubcode =  9'b0;
assign op_tlb_o = op_tlb_reg;
assign op_tlbrd_wb   = (op_tlb_o == 3'd3) & wb_valid;
assign op_tlbwr_wb   = (op_tlb_o == 3'd2) & wb_valid;
assign op_tlbfill_wb = (op_tlb_o == 3'd4) & wb_valid;
assign exc_tlb_o = exc_pis_o | exc_pif_o | exc_pil_o | exc_pme_o | exc_ppi_o | exc_tlbrentry_o;
//tlbsrch写后读冲�?
assign change_csr_o = wb_valid & csr_inst_type_reg[0] | (op_tlb_reg[1] & op_tlb_reg[0]);    //csrwr | csrxchg | tlbrd

always@(posedge clk )begin
    if (!resetn) begin
        wb_valid <= 1'b0;
    end
    else if (flush) begin
        wb_valid <= 1'b0;
    end
    else if (wb_allowin) begin
        wb_valid <= mem_to_wb_valid;
    end
end

always@ (posedge clk )begin
    if (!resetn) begin
            gr_we_reg <= 1'b0;
            mem_we_reg <= 1'b0;
            dest_reg <= 5'b0;
            final_result_reg <= 32'b0;
            pc_reg <= 32'h1bfffffc;
            none_dest_reg <= 1'b0;
            csr_num_reg <= 14'b0;
            csr_inst_type_reg <= 2'b0;
            rkd_value_reg <= 32'b0;
            inst_ertn_reg <= 1'b0;
            exc_sys_call_reg <= 1'b0;
            exc_adef_reg <= 1'b0;
            exc_ale_reg <= 1'b0;
            exc_ine_reg <= 1'b0;
            exc_break_reg <= 1'b0;
            exc_int_reg <= 1'b0;
            vaddr_reg <= 32'b0;
            op_tlb_reg <= 3'b0;
            exc_refetch_reg <= 1'b0;
            exc_pil_reg <= 1'b0;
            exc_pis_reg <= 1'b0;
            exc_pif_reg <= 1'b0;
            exc_pme_reg <= 1'b0;
            exc_ppi_memory_reg <= 1'b0;
            exc_ppi_fetch_reg <= 1'b0;
            exc_tlbrentry_fetch_reg <= 1'b0;
            exc_tlbrentry_memory_reg <= 1'b0;
    end
    else if (mem_to_wb_valid && wb_allowin) begin      
            gr_we_reg <= gr_we;
            mem_we_reg <= mem_we;
            dest_reg <= dest_i;
            final_result_reg <= final_result_i;
            pc_reg <= pc_i;    
            none_dest_reg <= none_dest_i;
            csr_num_reg <= csr_num_i;
            csr_inst_type_reg <= csr_inst_type_i;
            rkd_value_reg <= rkd_value_i;
            inst_ertn_reg <= inst_ertn_i;
            exc_sys_call_reg <= exc_sys_call_i;
            exc_adef_reg <= exc_adef_i;
            exc_ale_reg <= exc_ale_i;
            exc_ine_reg <= exc_ine_i;
            exc_break_reg <= exc_break_i;
            exc_int_reg <= exc_int_i;
            vaddr_reg <= vaddr_i;
            op_tlb_reg <= op_tlb_i;
            exc_refetch_reg <= exc_refetch_i;
            exc_pil_reg <= exc_pil_i;
            exc_pis_reg <= exc_pis_i;
            exc_pif_reg <= exc_pif_i;
            exc_pme_reg <= exc_pme_i;
            exc_ppi_memory_reg <= exc_ppi_memory_i;
            exc_ppi_fetch_reg <= exc_ppi_fetch_i;
            exc_tlbrentry_fetch_reg <= exc_tlbrentry_fetch_i;
            exc_tlbrentry_memory_reg <= exc_tlbrentry_memory_i;
    end
end         
assign none_dest_o = none_dest_reg;    
assign rf_we    = gr_we_reg && wb_valid && !(exc_wb & !exc_refetch_o);//异常指令不应该产生影�? 
assign rf_waddr = dest_reg;
assign rf_wdata = csr_inst_type_o == 2'b0 ? final_result_reg : csr_rvalue;
assign rkd_value_o = rkd_value_reg;
// debug info generate
assign debug_wb_pc       = pc_reg;
assign debug_wb_rf_we   = {4{rf_we}};
assign debug_wb_rf_wnum  = dest_reg;
assign debug_wb_rf_wdata = rf_wdata;    
assign dest_o = dest_reg /*&& {5{wb_valid}}*/;

endmodule

