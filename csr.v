
module CSR(
input wire clk,
input wire resetn,
input wire [31:0] csr_re,//某一位被设置�?1，表示对应的CSR位可以被读取
input wire [13:0] csr_num,
output wire [31:0] csr_rvalue,
input wire  csr_we,
input wire [31:0] csr_wmask,//某一位被设置�?1，表示对应的CSR位可以被写入
input wire [31:0] csr_wvalue,
output wire [31:0] exc_entry,
output wire has_int,
input wire ertn_flush,
input wire wb_exc,
input wire [5:0] wb_ecode,
input wire [8:0] wb_esubcode,
input wire ipi_int_in,
input wire [7:0] hw_int_in,
input wire [31:0] wb_pc,
output wire [31:0] csr_era_rvalue,
output wire [31:0] csr_eentry_rvalue,
input wire [31:0] wb_vaddr,//
output wire [9:0] csr_asid_asid_rvalue,
//from mycpu annd to tlb
input wire op_tlbrd_wb,
input wire op_tlbwr_wb,
input wire op_tlbsrch_ex,
input wire op_tlbfill_wb,
output wire op_tlbrd_csr,
output wire op_tlbwr_csr,
output wire op_tlbsrch_csr,
output wire op_tlbfill_csr,
input wire [4:0] invtlb_op_i,
input wire invtlb_valid_i,        
output wire [4:0] invtlb_op_o,
output wire invtlb_valid_o,
input wire exc_tlb,//for csr_tlbehi_vppn and badv
input wire exc_tlbrentry,
/*input wire exc_pil,
input wire exc_pis,
input wire exc_pif,
input wire exc_pme,
input wire exc_ppi,*/
//to tlb
output wire [18:0]csr_tlbehi_vppn_rvalue,
output wire [3:0] csr_tlbidx_index_rvalue,

//from tlb
input wire s1_found,
input wire [3:0] s1_index,
input wire        r_e,
input wire [18:0] r_vppn,
input wire [ 9:0] r_asid,
input wire        r_g,
input wire [ 5:0] r_ps,    
input wire [19:0] r_ppn0, 
input wire [ 1:0] r_plv0, 
input wire [ 1:0] r_mat0,
input wire        r_d0   ,
input wire        r_v0   ,
input wire [19:0] r_ppn1, 
input wire [ 1:0] r_plv1, 
input wire [ 1:0] r_mat1,
input wire        r_d1   ,
input wire        r_v1  ,

output wire        we,
output wire        w_e,
output wire [18:0] w_vppn,
output wire [ 9:0] w_asid,
output wire        w_g,
output wire [ 5:0] w_ps,    
output wire [ 3:0] w_index,
output wire [19:0] w_ppn0, 
output wire [ 1:0] w_plv0, 
output wire [ 1:0] w_mat0,
output wire        w_d0   ,
output wire        w_v0   ,
output wire [19:0] w_ppn1, 
output wire [ 1:0] w_plv1, 
output wire [ 1:0] w_mat1,
output wire        w_d1   ,
output wire        w_v1   ,  
//renew
output wire [31:0] csr_tlbrentry_rvalue,
output wire [31:0] csr_dmw0_rvalue,
output wire [31:0] csr_dmw1_rvalue,
output wire csr_crmd_da_rvalue,
output wire csr_crmd_pg_rvalue,
output wire [1:0] csr_crmd_plv_rvalue

    );
wire [31:0] coreid_in;
assign coreid_in = 32'b0; 
  
    
wire [31:0] csr_crmd_rvalue;
wire [31:0] csr_prmd_rvalue;
wire [31:0] csr_ecfg_rvalue;
wire [31:0] csr_estat_rvalue;
wire [31:0] csr_save0_rvalue;
wire [31:0] csr_save1_rvalue;
wire [31:0] csr_save2_rvalue;
wire [31:0] csr_save3_rvalue;
wire [31:0] csr_badv_rvalue;
wire [31:0] csr_tid_rvalue;
wire [31:0] csr_ticlr_rvalue;
wire [31:0] csr_tcfg_rvalue;
wire [31:0] csr_tval_rvalue;
wire [31:0] csr_tlbidx_rvalue;
wire [31:0] csr_tlbehi_rvalue;
wire [31:0] csr_tlbelo0_rvalue;
wire [31:0] csr_tlbelo1_rvalue;
wire [31:0] csr_asid_rvalue;


wire wb_ex_addr_err;

reg [1:0] csr_crmd_plv;
reg csr_crmd_ie;
reg csr_crmd_da;
reg csr_crmd_pg;
reg [1:0] csr_crmd_datf;
reg [1:0] csr_crmd_datm;
reg csr_crmd_we;
reg [1:0] csr_prmd_pplv;
reg csr_prmd_pie;     
reg csr_prmd_pwe;
reg [13:0] csr_ecfg_lie;  
reg [2:0]  csr_ecfg_vs;
reg [12:0] csr_estat_is;
reg [5:0] csr_estat_ecode;
reg [8:0] csr_estat_esubcode; 
reg [31:0] csr_era_pc;
reg [19:0] csr_eentry_va; 
reg [31:0] csr_save0_data;
reg [31:0] csr_save1_data;
reg [31:0] csr_save2_data;
reg [31:0] csr_save3_data;
reg [31:0] csr_badv_vaddr;
reg [31:0] csr_tid_tid;
reg csr_tcfg_en;
reg csr_tcfg_periodic;
reg [31:0] timer_cnt;
reg [29:0] csr_tcfg_initval;
reg [3:0] csr_tlbidx_index;
reg [5:0] csr_tlbidx_ps;
reg csr_tlbidx_ne;
reg [18:0] csr_tlbehi_vppn;
reg csr_tlbelo0_v;
reg csr_tlbelo0_d;
reg [1:0] csr_tlbelo0_plv;
reg [1:0]csr_tlbelo0_mat;
reg csr_tlbelo0_g;
reg [19:0] csr_tlbelo0_ppn;
reg csr_tlbelo1_v;
reg csr_tlbelo1_d;
reg [1:0] csr_tlbelo1_plv;
reg [1:0]csr_tlbelo1_mat;
reg csr_tlbelo1_g;
reg [19:0] csr_tlbelo1_ppn;
reg [9:0] csr_asid_asid;
reg [25:0] csr_tlbrentry_pa;
reg csr_dmw0_plv0;
reg csr_dmw0_plv3;
reg [1:0] csr_dmw0_mat;
reg [2:0] csr_dmw0_pseg;
reg [2:0] csr_dmw0_vseg;
reg csr_dmw1_plv0;
reg csr_dmw1_plv3;
reg [1:0] csr_dmw1_mat;
reg [2:0] csr_dmw1_pseg;
reg [2:0] csr_dmw1_vseg;
wire [31:0] tcfg_next_value;
wire [31:0] csr_tval;
wire csr_ticlr_clr;
reg [7:0] csr_asid_asidbits;
always@(posedge clk)begin
    if (!resetn) begin
        csr_crmd_plv <= 2'b0;
        csr_crmd_ie <= 1'b0;
        csr_crmd_we <= 1'b0;
    end
    else if (wb_exc) begin
        csr_crmd_plv <= 2'b0;
        csr_crmd_ie <= 1'b0;
        csr_crmd_we <= 1'b0;
    end
    else if (ertn_flush) begin
        csr_crmd_plv <= csr_prmd_pplv;
        csr_crmd_ie <= csr_prmd_pie;
        csr_crmd_we <= csr_prmd_pwe;
    end
    else if (csr_we && (csr_num == 14'h0)) begin
        csr_crmd_plv <= csr_wmask[1:0]&csr_wvalue[1:0]
                      | ~csr_wmask[1:0]&csr_crmd_plv;
        csr_crmd_ie <= csr_wmask[2]&csr_wvalue[2]
                      | ~csr_wmask[2]&csr_crmd_ie;
        csr_crmd_we <= csr_wmask[9]&csr_wvalue[9]
                      | ~csr_wmask[9]&csr_crmd_we;
    end    
end

always@(posedge clk)begin
    if(!resetn)begin
        csr_crmd_da <= 1'b1;
        csr_crmd_pg <= 1'b0;        
        csr_crmd_datf <= 2'b00;
        csr_crmd_datm <= 2'b00;
    end
    else if(exc_tlbrentry)begin
        csr_crmd_da <= 1'b1;
        csr_crmd_pg <= 1'b0; 
    end
    else if(ertn_flush & csr_estat_ecode == 6'h3f)begin
        csr_crmd_da <= 1'b0;
        csr_crmd_pg <= 1'b1;
    //   csr_crmd_datf <= 2'b01;
    //    csr_crmd_datm <= 2'b01; 
    end 
    else if (csr_we && (csr_num == 14'h0)) begin
        csr_crmd_da <= csr_wmask[3]&csr_wvalue[3]
                      | ~csr_wmask[3]&csr_crmd_da;
        csr_crmd_pg <= csr_wmask[4]&csr_wvalue[4]
                      | ~csr_wmask[4]&csr_crmd_pg;   
        csr_crmd_datf <= csr_wmask[6:5]&csr_wvalue[6:5]
                      | ~csr_wmask[6:5]&csr_crmd_datf;
        csr_crmd_datm <= csr_wmask[8:7]&csr_wvalue[8:7]
                      | ~csr_wmask[8:7]&csr_crmd_datm;                         
    end   
end    

always@(posedge clk)begin
    if(!resetn)begin
        csr_ecfg_vs <= 3'b000;
    end
end

always@(posedge clk)begin
    if (wb_exc)begin
        csr_prmd_pplv <= csr_crmd_plv;
        csr_prmd_pie <= csr_crmd_ie;
        csr_prmd_pwe <= csr_crmd_we;
    end
    else if (csr_we && csr_num == 14'h1) begin
        csr_prmd_pplv <= csr_wmask[1:0]&csr_wvalue[1:0]
                      | ~csr_wmask[1:0]&csr_prmd_pplv;
        csr_prmd_pie <= csr_wmask[2]&csr_wvalue[2]
                      | ~csr_wmask[2]&csr_prmd_pie;
        csr_prmd_pwe <= csr_wmask[3]&csr_wvalue[3]
                      | ~csr_wmask[3]&csr_prmd_pwe;
    end
end

always@(posedge clk)begin
    if (!resetn) begin
        csr_ecfg_lie <= 13'b0;
    end
    else if (csr_we && csr_num == 14'h4) begin
        csr_ecfg_lie <= csr_wmask[12:0]&csr_wvalue[12:0]&13'h1bff
                      | ~csr_wmask[12:0]&csr_ecfg_lie&13'h1bff;
    end
end

always@(posedge clk)begin
    if (!resetn) begin
        csr_estat_is[1:0] <= 2'b0;
    end
    else if (csr_we && csr_num == 14'h5) begin
        csr_estat_is[1:0] <= csr_wmask[1:0]&csr_wvalue[1:0]
                      | ~csr_wmask[1:0]&csr_estat_is[1:0];
    end
        csr_estat_is[9:2] <= hw_int_in[7:0];
        csr_estat_is[10] <= 1'b0;
    if (csr_tcfg_en && timer_cnt[31:0] == 32'b0) begin
        csr_estat_is[11] <= 1'b1;
    end
    else if (csr_we && csr_num == 14'h44 && csr_wmask[0] && csr_wvalue[0]) begin
        csr_estat_is[11] <= 1'b0;
    end
        csr_estat_is[12] <= ipi_int_in;
end

always@ (posedge clk) begin
    if (wb_exc) begin
        csr_estat_ecode <= wb_ecode;
        csr_estat_esubcode <= wb_esubcode;
    end
end

always@(posedge clk)begin
    if (wb_exc) begin
        csr_era_pc <= wb_pc;
    end
    else if (csr_we && csr_num == 14'h6) begin
        csr_era_pc <= csr_wmask[31:0]&csr_wvalue[31:0]
                      | ~csr_wmask[31:0]&csr_era_pc;
    end
end

always @ (posedge clk)begin
    if (csr_we && csr_num == 14'hc)begin
        csr_eentry_va <= csr_wmask[31:12]&csr_wvalue[31:12]
                      | ~csr_wmask[31:12]&csr_eentry_va;
    end
end

always@(posedge clk)begin
    if (wb_exc && wb_ex_addr_err) begin
        csr_badv_vaddr <= (wb_ecode == 6'h8 &&
                          wb_esubcode == 9'h0) ? wb_pc : wb_vaddr;//selector may be delete
               
    end
end

always @ (posedge clk)begin
    if (csr_we && csr_num == 14'h30)begin
        csr_save0_data <= csr_wmask[31:0]&csr_wvalue[31:0]
                      | ~csr_wmask[31:0]&csr_save0_data;
    end
    if (csr_we && csr_num == 14'h31)begin
        csr_save1_data <= csr_wmask[31:0]&csr_wvalue[31:0]
                      | ~csr_wmask[31:0]&csr_save1_data;
    end
    if (csr_we && csr_num == 14'h32)begin
        csr_save2_data <= csr_wmask[31:0]&csr_wvalue[31:0]
                      | ~csr_wmask[31:0]&csr_save2_data;
    end
    if (csr_we && csr_num == 14'h33)begin
        csr_save3_data <= csr_wmask[31:0]&csr_wvalue[31:0]
                      | ~csr_wmask[31:0]&csr_save3_data;
    end
end

always @(posedge clk) begin
    if(!resetn)begin
        csr_tcfg_en <= 1'b0;
    end
    else if(csr_we && csr_num == 14'h41)begin
        csr_tcfg_en <= csr_wmask[0]&csr_wvalue[0]
                      | ~csr_wmask[0]&csr_tcfg_en;    
    end
    if(csr_we && csr_num == 14'h41)begin
        csr_tcfg_periodic <= csr_wmask[1]&csr_wvalue[1]
                      | ~csr_wmask[1]&csr_tcfg_periodic;    
        csr_tcfg_initval <= csr_wmask[31:2]&csr_wvalue[31:2]
                      | ~csr_wmask[31:2]&csr_tcfg_initval;     
    end
end
always@(posedge clk)begin
    if (!resetn) begin
        csr_tid_tid <= coreid_in;
    end
    else if (csr_we && csr_num == 14'h40) begin
        csr_tid_tid <= csr_wmask[31:0]&csr_wvalue[31:0]
                     | ~csr_wmask[31:0]&csr_tid_tid;
    end
end
always@(posedge clk)begin
    if(!resetn)begin
        timer_cnt <= 32'hffffffff;
    end
    else if(csr_we && csr_num == 14'h41 && tcfg_next_value[0])begin
        timer_cnt <= {tcfg_next_value[29:0],2'b0};//////////////////////[29:0]不知道是否正�?
    end
    else if (csr_tcfg_en && timer_cnt != 32'hffffffff)begin
        if(timer_cnt[31:0] == 32'b0 && csr_tcfg_periodic)begin
            timer_cnt <= {csr_tcfg_initval,2'b0};
        end
        else begin
            timer_cnt <= timer_cnt - 1'b1;
        end
    end
end
//tlbidx
always@(posedge clk)begin
    if(op_tlbsrch_ex & s1_found)begin
        csr_tlbidx_index <= s1_index;
    end
    else if (csr_we && csr_num == 14'h10) begin
        csr_tlbidx_index <= csr_wmask[3:0]&csr_wvalue[3:0]
                         | ~csr_wmask[3:0]&csr_tlbidx_index;
    end    
    if(op_tlbrd_wb)begin
        csr_tlbidx_ps <= r_e ? r_ps : 6'd0;
    end
    else if (csr_we && csr_num == 14'h10) begin
        csr_tlbidx_ps <= csr_wmask[29:24]&csr_wvalue[29:24]
                      | ~csr_wmask[29:24]&csr_tlbidx_ps;
    end        
    if(op_tlbsrch_ex | op_tlbrd_wb)begin
        csr_tlbidx_ne <= (op_tlbsrch_ex & !s1_found)  
                       | (op_tlbrd_wb & !r_e);
    end
    else if (csr_we && csr_num == 14'h10) begin
        csr_tlbidx_ne <= csr_wmask[31]&csr_wvalue[31]
                      | ~csr_wmask[31]&csr_tlbidx_ne;
    end   
end
//tlbehi
always@(posedge clk)begin
    if(exc_tlb)begin
        csr_tlbehi_vppn <= wb_vaddr[31:13];
    end
    else if(op_tlbrd_wb)begin
        csr_tlbehi_vppn <= r_e ? r_vppn : 19'h0;
    end
    else if (csr_we && csr_num == 14'h11) begin
        csr_tlbehi_vppn <= csr_wmask[31:13]&csr_wvalue[31:13]
                        | ~csr_wmask[31:13]&csr_tlbehi_vppn;
    end    
end
//tlbelo0
always@(posedge clk)begin
    if(op_tlbrd_wb)begin
        csr_tlbelo0_v <= r_e ? r_v0 : 1'h0;
        csr_tlbelo0_d <= r_e ? r_d0 : 1'h0;
        csr_tlbelo0_plv <= r_e ? r_plv0 : 2'h0;
        csr_tlbelo0_mat <= r_e ? r_mat0 : 2'h0;
        csr_tlbelo0_g <= r_e ? r_g : 1'h0;
        csr_tlbelo0_ppn <= r_e ? r_ppn0 : 20'h0;
    end
    else if (csr_we && csr_num == 14'h12) begin
        csr_tlbelo0_v <= csr_wmask[0]&csr_wvalue[0]
                      | ~csr_wmask[0]&csr_tlbelo0_v;
        csr_tlbelo0_d <= csr_wmask[1]&csr_wvalue[1]
                      | ~csr_wmask[1]&csr_tlbelo0_d;
        csr_tlbelo0_plv <= csr_wmask[3:2]&csr_wvalue[3:2]
                      | ~csr_wmask[3:2]&csr_tlbelo0_plv;
        csr_tlbelo0_mat <= csr_wmask[5:4]&csr_wvalue[5:4]
                      | ~csr_wmask[5:4]&csr_tlbelo0_mat;
        csr_tlbelo0_g <= csr_wmask[6]&csr_wvalue[6]
                      | ~csr_wmask[6]&csr_tlbelo0_g;
        csr_tlbelo0_ppn <= csr_wmask[27:8]&csr_wvalue[27:8]
                      | ~csr_wmask[27:8]&csr_tlbelo0_ppn;
    end    
end
//tlbelo1
always@(posedge clk)begin
    if(op_tlbrd_wb)begin
        csr_tlbelo1_v <= r_e ? r_v1 : 1'h0;
        csr_tlbelo1_d <= r_e ? r_d1 : 1'h0;
        csr_tlbelo1_plv <= r_e ? r_plv1 : 2'h0;
        csr_tlbelo1_mat <= r_e ? r_mat1 : 2'h0;
        csr_tlbelo1_g <= r_e ? r_g : 1'h0;
        csr_tlbelo1_ppn <= r_e ? r_ppn1 : 20'h0;
    end
    else if (csr_we && csr_num == 14'h13) begin
        csr_tlbelo1_v <= csr_wmask[0]&csr_wvalue[0]
                      | ~csr_wmask[0]&csr_tlbelo1_v;
        csr_tlbelo1_d <= csr_wmask[1]&csr_wvalue[1]
                      | ~csr_wmask[1]&csr_tlbelo1_d;
        csr_tlbelo1_plv <= csr_wmask[3:2]&csr_wvalue[3:2]
                      | ~csr_wmask[3:2]&csr_tlbelo1_plv;
        csr_tlbelo1_mat <= csr_wmask[5:4]&csr_wvalue[5:4]
                      | ~csr_wmask[5:4]&csr_tlbelo1_mat;
        csr_tlbelo1_g <= csr_wmask[6]&csr_wvalue[6]
                      | ~csr_wmask[6]&csr_tlbelo1_g;
        csr_tlbelo1_ppn <= csr_wmask[27:8]&csr_wvalue[27:8]
                      | ~csr_wmask[27:8]&csr_tlbelo1_ppn;
    end    
end
//asid
always@(posedge clk)begin
    if(op_tlbrd_wb)begin
        csr_asid_asid <= r_e ? r_asid : 10'h0;
        csr_asid_asidbits <= /*r_e ?*/ 8'ha; //: 8'h0; 
    end
    else if (csr_we && csr_num == 14'h18) begin
        csr_asid_asid <= csr_wmask[9:0]&csr_wvalue[9:0]
                      | ~csr_wmask[9:0]&csr_asid_asid;
        csr_asid_asidbits <= 8'ha; 
    end    
end
//tlbrentry
always@(posedge clk)begin
    if (csr_we && csr_num == 14'h88) begin
        csr_tlbrentry_pa <= csr_wmask[31:6]&csr_wvalue[31:6]
                      | ~csr_wmask[31:6]&csr_tlbrentry_pa;
    end        
end
// dmw0-1
always@(posedge clk)begin
    if (!resetn) begin
        csr_dmw0_plv0 <= 1'b1;
        csr_dmw0_plv3 <= 1'b1;
        csr_dmw0_mat <=  2'b0;
        csr_dmw0_pseg <= 3'b0;
        csr_dmw0_vseg <= 3'b0;
    end
    else if (csr_we && csr_num == 14'h180) begin
        csr_dmw0_plv0 <= csr_wmask[0]&csr_wvalue[0]
                     | ~csr_wmask[0]&csr_dmw0_plv0;
        csr_dmw0_plv3 <= csr_wmask[3]&csr_wvalue[3]
                     | ~csr_wmask[3]&csr_dmw0_plv3;
        csr_dmw0_mat <= csr_wmask[5:4]&csr_wvalue[5:4]
                     | ~csr_wmask[5:4]&csr_dmw0_mat;
        csr_dmw0_pseg <= csr_wmask[27:25]&csr_wvalue[27:25]
                     | ~csr_wmask[27:25]&csr_dmw0_pseg;
        csr_dmw0_vseg <= csr_wmask[31:29]&csr_wvalue[31:29]
                     | ~csr_wmask[31:29]&csr_dmw0_vseg;
    end
end
always@(posedge clk)begin
    if (!resetn) begin
        csr_dmw1_plv0 <= 1'b1;
        csr_dmw1_plv3 <= 1'b1;
        csr_dmw1_mat <=  2'b0;
        csr_dmw1_pseg <= 3'b0;
        csr_dmw1_vseg <= 3'b0;
    end
    else if (csr_we && csr_num == 14'h181) begin
        csr_dmw1_plv0 <= csr_wmask[0]&csr_wvalue[0]
                     | ~csr_wmask[0]&csr_dmw1_plv0;
        csr_dmw1_plv3 <= csr_wmask[3]&csr_wvalue[3]
                     | ~csr_wmask[3]&csr_dmw1_plv3;
        csr_dmw1_mat <= csr_wmask[5:4]&csr_wvalue[5:4]
                     | ~csr_wmask[5:4]&csr_dmw1_mat;
        csr_dmw1_pseg <= csr_wmask[27:25]&csr_wvalue[27:25]
                     | ~csr_wmask[27:25]&csr_dmw1_pseg;
        csr_dmw1_vseg <= csr_wmask[31:29]&csr_wvalue[31:29]
                     | ~csr_wmask[31:29]&csr_dmw1_vseg;
    end
end

assign has_int =((csr_estat_is[12:0] & csr_ecfg_lie[12:0]) != 13'b0) && (csr_crmd_ie ==1'b1);
assign csr_crmd_rvalue = {23'b0,csr_crmd_datm,csr_crmd_datf,csr_crmd_pg,csr_crmd_da,csr_crmd_ie,csr_crmd_plv};
assign csr_prmd_rvalue = {29'b0,csr_prmd_pie,csr_prmd_pplv};
assign csr_ecfg_rvalue = {19'b0,csr_ecfg_lie};
assign csr_estat_rvalue ={1'b0,csr_estat_esubcode,csr_estat_ecode,3'b0,csr_estat_is};
assign csr_era_rvalue = {csr_era_pc};
assign csr_eentry_rvalue = {csr_eentry_va,12'b0};
assign csr_save0_rvalue = {csr_save0_data};
assign csr_save1_rvalue = {csr_save1_data};
assign csr_save2_rvalue = {csr_save2_data};
assign csr_save3_rvalue = {csr_save3_data};
assign wb_ex_addr_err = wb_ecode == 6'h8 || wb_ecode == 6'h9 | exc_tlb;
assign tcfg_next_value = csr_wmask[31:0] & csr_wvalue[31:0]
                      | ~csr_wmask[31:0] & {csr_tcfg_initval,csr_tcfg_periodic,csr_tcfg_en};
assign csr_tval = timer_cnt[31:0];
assign csr_ticlr_clr = 1'b0;
assign csr_badv_rvalue = csr_badv_vaddr;
assign csr_ticlr_rvalue = {31'b0,csr_ticlr_clr};
assign csr_tval_rvalue = csr_tval;//////////////可能有问�?
assign csr_tcfg_rvalue = {csr_tcfg_initval,csr_tcfg_periodic,csr_tcfg_en};
assign csr_tid_rvalue = csr_tid_tid;
assign csr_tlbidx_rvalue = {csr_tlbidx_ne,1'b0,csr_tlbidx_ps,20'b0,csr_tlbidx_index};
assign csr_tlbehi_rvalue = {csr_tlbehi_vppn, 13'd0}; // 高位�? VPPN，低位填�? 0
assign csr_tlbelo0_rvalue = {4'd0,csr_tlbelo0_ppn, 1'd0,csr_tlbelo0_g, csr_tlbelo0_mat, csr_tlbelo0_plv, csr_tlbelo0_d, csr_tlbelo0_v};
assign csr_tlbelo1_rvalue = {4'd0,csr_tlbelo1_ppn, 1'd0,csr_tlbelo1_g, csr_tlbelo1_mat, csr_tlbelo1_plv, csr_tlbelo1_d, csr_tlbelo1_v};
assign csr_asid_rvalue = {8'd0,csr_asid_asidbits,6'd0,csr_asid_asid};
assign csr_tlbrentry_rvalue = {csr_tlbrentry_pa,6'd0};
assign csr_dmw0_rvalue = {csr_dmw0_vseg,1'b0,csr_dmw0_pseg,19'b0,csr_dmw0_mat,csr_dmw0_plv3,2'b0,csr_dmw0_plv0};
assign csr_dmw1_rvalue = {csr_dmw1_vseg,1'b0,csr_dmw1_pseg,19'b0,csr_dmw1_mat,csr_dmw1_plv3,2'b0,csr_dmw1_plv0};

assign csr_rvalue = {32{csr_num == 14'h0}} & csr_crmd_rvalue
                |   {32{csr_num == 14'h1}} & csr_prmd_rvalue
                |   {32{csr_num == 14'h4}} & csr_ecfg_rvalue
                |   {32{csr_num == 14'h5}} & csr_estat_rvalue
                |   {32{csr_num == 14'h6}} & csr_era_rvalue
                |   {32{csr_num == 14'hc}} & csr_eentry_rvalue
                |   {32{csr_num == 14'h30}} & csr_save0_rvalue
                |   {32{csr_num == 14'h31}} & csr_save1_rvalue
                |   {32{csr_num == 14'h32}} & csr_save2_rvalue
                |   {32{csr_num == 14'h33}} & csr_save3_rvalue
                |   {32{csr_num == 14'h7}} & csr_badv_rvalue
                |   {32{csr_num == 14'h40}} & csr_tid_rvalue
                |   {32{csr_num == 14'h41}} & csr_tcfg_rvalue
                |   {32{csr_num == 14'h42}} & csr_tval_rvalue
                |   {32{csr_num == 14'h44}} & csr_ticlr_rvalue
                |   {32{csr_num == 14'h10}} & csr_tlbidx_rvalue
                |   {32{csr_num == 14'h11}} & csr_tlbehi_rvalue
                |   {32{csr_num == 14'h12}} & csr_tlbelo0_rvalue
                |   {32{csr_num == 14'h13}} & csr_tlbelo1_rvalue
                |   {32{csr_num == 14'h18}} & csr_asid_rvalue
                |   {32{csr_num == 14'h88}} & csr_tlbrentry_rvalue
                |   {32{csr_num == 14'h180}} & csr_dmw0_rvalue
                |   {32{csr_num == 14'h181}} & csr_dmw1_rvalue;

//from mycpu to tlb
assign op_tlbrd_csr = op_tlbrd_wb;
assign op_tlbwr_csr = op_tlbwr_wb;
assign op_tlbsrch_csr = op_tlbsrch_ex;
assign op_tlbfill_csr = op_tlbfill_wb;
assign invtlb_op_o = invtlb_op_i;
assign invtlb_valid_o = invtlb_valid_i;        
//to tlb 
assign csr_tlbehi_vppn_rvalue = csr_tlbehi_vppn;
assign csr_tlbidx_index_rvalue = csr_tlbidx_index;//Tlbfill的随机�?�择�?
assign csr_asid_asid_rvalue = csr_asid_asid;
assign we = op_tlbwr_wb | op_tlbfill_wb;
assign w_e = (csr_estat_ecode == 6'h3f) ? 1'b1 : ~csr_tlbidx_ne  ;//考虑tlb重填
assign w_vppn = csr_tlbehi_vppn;
assign w_asid = csr_asid_asid;
assign w_g = csr_tlbelo0_g & csr_tlbelo1_g;
assign w_ps = csr_tlbidx_ps;
assign w_index = csr_tlbidx_index;
assign w_ppn0 = csr_tlbelo0_ppn;
assign w_plv0 = csr_tlbelo0_plv;
assign w_mat0 = csr_tlbelo0_mat;
assign w_d0 = csr_tlbelo0_d;
assign w_v0 = csr_tlbelo0_v;
assign w_ppn1 = csr_tlbelo1_ppn;
assign w_plv1 = csr_tlbelo1_plv;
assign w_mat1 = csr_tlbelo1_mat;
assign w_d1 = csr_tlbelo1_d;
assign w_v1 = csr_tlbelo1_v;

assign csr_crmd_da_rvalue = csr_crmd_da;
assign csr_crmd_pg_rvalue = csr_crmd_pg;
assign csr_crmd_plv_rvalue = csr_crmd_plv;

endmodule        
