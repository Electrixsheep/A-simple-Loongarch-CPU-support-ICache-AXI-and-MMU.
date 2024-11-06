`timescale 1ns / 1ps
module addrtrans(
input wire [31:0] inst_sram_addr_va,
input wire [31:0] data_sram_addr_va,
//ld or st
input wire st_sign,
input wire ld_sign,
//fetch paddr
output wire [31:0] inst_paddr,

//ld and st paddr
output wire [31:0] data_paddr,
//from csr
input wire [31:0] csr_dmw0_rvalue,
input wire [31:0] csr_dmw1_rvalue,
input wire csr_crmd_da_rvalue,
input wire csr_crmd_pg_rvalue,
input wire [1:0] csr_crmd_plv_rvalue,

//from tlb
input wire        s0_found,
input wire [ 3:0] s0_index,
input wire [19:0] s0_ppn, 
input wire [ 5:0] s0_ps,
input wire [ 1:0] s0_plv, 
input wire [ 1:0] s0_mat,
input wire        s0_d   ,
input wire        s0_v   ,
input wire        s1_found,
input wire [ 3:0] s1_index,
input wire [19:0] s1_ppn, 
input wire [ 5:0] s1_ps,
input wire [ 1:0] s1_plv, 
input wire [ 1:0] s1_mat,
input wire        s1_d   ,
input wire        s1_v   ,
//exc
output wire exc_pil_o,
output wire exc_pis_o,
output wire exc_pif_o,
output wire exc_pme_o,
output wire tlbrentry_memory_o,//ld and st
output wire tlbrentry_fetch_o,//fetch
output wire ppi_fetch_o,//fetch
output wire ppi_memory_o,//ld and st
//when exc,there shall be no req to axi
output wire exc_tlb_fetch,
output wire exc_tlb_memory
    );
//fetch paddr
wire [31:0] inst_paddr_da;
wire [31:0] inst_paddr_dmw;
wire [31:0] inst_paddr_tlb;
//ld and st paddr
wire [31:0] data_paddr_da;
wire [31:0] data_paddr_dmw;
wire [31:0] data_paddr_tlb;
//judge 
assign inst_paddr = ({32{(csr_crmd_da_rvalue & ~csr_crmd_pg_rvalue)}} & inst_paddr_da)
                |   ({32{(~csr_crmd_da_rvalue & csr_crmd_pg_rvalue)}} & 
                        ((inst_match_dmw0 | inst_match_dmw1) ? inst_paddr_dmw : inst_paddr_tlb ));
assign data_paddr = ({32{(csr_crmd_da_rvalue & ~csr_crmd_pg_rvalue)}} & data_paddr_da)
                |   ({32{(~csr_crmd_da_rvalue & csr_crmd_pg_rvalue)}} & 
                        ((data_match_dmw0 | data_match_dmw1) ? data_paddr_dmw : data_paddr_tlb )
                                                                                                );
//da
assign inst_paddr_da = inst_sram_addr_va;
assign data_paddr_da = data_sram_addr_va;
//dmw
wire inst_match_dmw0;
wire inst_match_dmw1;
wire data_match_dmw0;
wire data_match_dmw1;
    //match
assign inst_match_dmw0 = (inst_sram_addr_va[31:29] == csr_dmw0_rvalue[31:29]);
assign inst_match_dmw1 = (inst_sram_addr_va[31:29] == csr_dmw1_rvalue[31:29]);
assign data_match_dmw0 = (data_sram_addr_va[31:29] == csr_dmw0_rvalue[31:29]);
assign data_match_dmw1 = (data_sram_addr_va[31:29] == csr_dmw1_rvalue[31:29]);
    //paddr_dmw
assign inst_paddr_dmw = ({32{inst_match_dmw0}} & {csr_dmw0_rvalue[27:25],inst_sram_addr_va[28:0]})
                      | ({32{inst_match_dmw1}} & {csr_dmw1_rvalue[27:25],inst_sram_addr_va[28:0]});     
    
assign data_paddr_dmw = ({32{data_match_dmw0}} & {csr_dmw0_rvalue[27:25],data_sram_addr_va[28:0]})
                      | ({32{data_match_dmw1}} & {csr_dmw1_rvalue[27:25],data_sram_addr_va[28:0]});   
//tlb
wire tlb_mode0;//for fetch
assign tlb_mode0 = ~csr_crmd_da_rvalue & csr_crmd_pg_rvalue & !(inst_match_dmw0 | inst_match_dmw1);
wire tlb_mode1;//for fetch
assign tlb_mode1 = ~csr_crmd_da_rvalue & csr_crmd_pg_rvalue & !(data_match_dmw0 | data_match_dmw1);
wire found_ps0_is_21;
wire found_ps1_is_21;
assign found_ps0_is_21 = s0_ps == 6'd21;
assign found_ps1_is_21 = s1_ps == 6'd21;
assign inst_paddr_tlb = found_ps0_is_21 ? {s0_ppn[19:9],inst_sram_addr_va[20:0]}
                                        : {s0_ppn[19:0],inst_sram_addr_va[11:0]}  ;              
assign data_paddr_tlb = found_ps1_is_21 ? {s1_ppn[19:9],data_sram_addr_va[20:0]}
                                        : {s1_ppn[19:0],data_sram_addr_va[11:0]}  ;
//exc
assign exc_pil_o = ~s1_v & ld_sign & tlb_mode1;
assign exc_pis_o = ~s1_v & st_sign & tlb_mode1;
assign exc_pif_o = ~s0_v & tlb_mode0;
assign exc_pme_o = ~s1_d & st_sign & tlb_mode1;
assign tlbrentry_memory_o = (~s1_found & (st_sign | ld_sign)) & tlb_mode1;
assign tlbrentry_fetch_o = ~s0_found & tlb_mode0  ;
assign ppi_memory_o = ((csr_crmd_plv_rvalue > s1_plv)& (st_sign | ld_sign)) & tlb_mode1 ;           
assign ppi_fetch_o = (csr_crmd_plv_rvalue > s0_plv ) & tlb_mode0 ;           
assign exc_tlb_fetch = (exc_pif_o | tlbrentry_fetch_o | ppi_fetch_o) & tlb_mode0;
assign exc_tlb_memory = (exc_pil_o | exc_pis_o | exc_pme_o | tlbrentry_memory_o |  ppi_memory_o) & tlb_mode1;
endmodule
