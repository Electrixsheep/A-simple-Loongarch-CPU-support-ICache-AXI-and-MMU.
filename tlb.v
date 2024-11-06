`timescale 1ns / 1ps
module tlb(
    input wire clk,
    // serach port 0 (for fetch)
    input wire [18:0] s0_vppn,
    input wire        s0_va_bit12,
    input wire [ 9:0] s0_asid,
    output wire        s0_found,
    output wire [ 3:0] s0_index,
    output wire [19:0] s0_ppn, 
    output wire [ 5:0] s0_ps,
    output wire [ 1:0] s0_plv, 
    output wire [ 1:0] s0_mat,
    output wire        s0_d   ,
    output wire        s0_v   ,
   // search port 1 (for load/store) 
    input wire [18:0] s1_vppn,
    input wire        s1_va_bit12,
    input wire [ 9:0] s1_asid,
    output wire        s1_found,
    output wire [ 3:0] s1_index,
    output wire [19:0] s1_ppn, 
    output wire [ 5:0] s1_ps,
    output wire [ 1:0] s1_plv, 
    output wire [ 1:0] s1_mat,
    output wire        s1_d   ,
    output wire        s1_v   ,
    // invtlb opcode
    input wire         invtlb_valid,
    input wire  [ 4:0] invtlb_op,
    // write port         
    input wire        we,
    input wire        w_e,
    input wire [18:0] w_vppn,
    input wire [ 9:0] w_asid,
    input wire        w_g,
    input wire [ 5:0] w_ps,    
    input wire [ 3:0] w_index,
    input wire [19:0] w_ppn0, 
    input wire [ 1:0] w_plv0, 
    input wire [ 1:0] w_mat0,
    input wire        w_d0   ,
    input wire        w_v0   ,
    input wire [19:0] w_ppn1, 
    input wire [ 1:0] w_plv1, 
    input wire [ 1:0] w_mat1,
    input wire        w_d1   ,
    input wire        w_v1   ,    
    //read port    
    input wire [ 3:0] r_index,
    output wire        r_e,
    output wire [18:0] r_vppn,
    output wire [ 9:0] r_asid,
    output wire        r_g,
    output wire [ 5:0] r_ps,    
    output wire [19:0] r_ppn0, 
    output wire [ 1:0] r_plv0, 
    output wire [ 1:0] r_mat0,
    output wire        r_d0   ,
    output wire        r_v0   ,
    output wire [19:0] r_ppn1, 
    output wire [ 1:0] r_plv1, 
    output wire [ 1:0] r_mat1,
    output wire        r_d1   ,
    output wire        r_v1   
    );
reg [15:0] tlb_e;
reg [15:0] tlb_ps4MB;  //pagesize 1:4MB,0:4KB
reg [18:0] tlb_vppn [15:0];
reg [ 9:0] tlb_asid [15:0];
reg        tlb_g    [15:0];
reg [19:0] tlb_ppn0 [15:0];
reg [ 1:0] tlb_plv0 [15:0]; 
reg [ 1:0] tlb_mat0 [15:0];
reg        tlb_d0   [15:0];
reg        tlb_v0   [15:0];
reg [19:0] tlb_ppn1 [15:0];
reg [ 1:0] tlb_plv1 [15:0]; 
reg [ 1:0] tlb_mat1 [15:0];
reg        tlb_d1   [15:0];
reg        tlb_v1   [15:0];  

wire [15:0] match0;
wire [15:0] match1;

// WRITE
always @(posedge clk) begin
    if (we) begin
        tlb_e[w_index] <= w_e;
        tlb_vppn[w_index] <= w_vppn;
        tlb_asid[w_index] <= w_asid;
        tlb_g[w_index] <= w_g;
        tlb_ps4MB[w_index] <= (w_ps == 6'd21);
        tlb_ppn0[w_index] <= w_ppn0;
        tlb_plv0[w_index] <= w_plv0;
        tlb_mat0[w_index] <= w_mat0;
        tlb_d0[w_index] <= w_d0;
        tlb_v0[w_index] <= w_v0;
        tlb_ppn1[w_index] <= w_ppn1;
        tlb_plv1[w_index] <= w_plv1;
        tlb_mat1[w_index] <= w_mat1;
        tlb_d1[w_index] <= w_d1;
        tlb_v1[w_index] <= w_v1;
    end
    else if(invtlb_valid)begin
        tlb_e <= ~invtlb_mask[invtlb_op] & tlb_e;
    end
end
// READ
assign r_e = tlb_e[r_index];
assign r_vppn = tlb_vppn[r_index];
assign r_asid = tlb_asid[r_index];
assign r_g = tlb_g[r_index];
assign r_ps = tlb_ps4MB[r_index] ? 6'd21 : 6'b001100;
assign r_ppn0 = tlb_ppn0[r_index];
assign r_plv0 = tlb_plv0[r_index];
assign r_mat0 = tlb_mat0[r_index];
assign r_d0 = tlb_d0[r_index];
assign r_v0 = tlb_v0[r_index];
assign r_ppn1 = tlb_ppn1[r_index];
assign r_plv1 = tlb_plv1[r_index];
assign r_mat1 = tlb_mat1[r_index];
assign r_d1 = tlb_d1[r_index];
assign r_v1 = tlb_v1[r_index];
//±È½Ï
//////////////////////////////////////////////////////////////////////////////////////////////
assign match0[0] = (s0_vppn[18:9] == tlb_vppn[0][18:9])
                &&  (tlb_ps4MB[0] || s0_vppn[8:0] == tlb_vppn[0][8:0])
                &&  ( (s0_asid == tlb_asid[0]) || tlb_g[0] ) && tlb_e[0];
assign match0[1] = (s0_vppn[18:9] == tlb_vppn[1][18:9])
                &&  (tlb_ps4MB[1] || s0_vppn[8:0] == tlb_vppn[1][8:0])
                &&  ( (s0_asid == tlb_asid[1]) || tlb_g[1] ) && tlb_e[1];
assign match0[2] = (s0_vppn[18:9] == tlb_vppn[2][18:9])
                &&  (tlb_ps4MB[2] || s0_vppn[8:0] == tlb_vppn[2][8:0])
                &&  ( (s0_asid == tlb_asid[2]) || tlb_g[2] ) && tlb_e[2];
assign match0[3] = (s0_vppn[18:9] == tlb_vppn[3][18:9])
                &&  (tlb_ps4MB[3] || s0_vppn[8:0] == tlb_vppn[3][8:0])
                &&  ( (s0_asid == tlb_asid[3]) || tlb_g[3] ) && tlb_e[3];
assign match0[4] = (s0_vppn[18:9] == tlb_vppn[4][18:9])
                &&  (tlb_ps4MB[4] || s0_vppn[8:0] == tlb_vppn[4][8:0])
                &&  ( (s0_asid == tlb_asid[4]) || tlb_g[4] ) && tlb_e[4];
assign match0[5] = (s0_vppn[18:9] == tlb_vppn[5][18:9])
                &&  (tlb_ps4MB[5] || s0_vppn[8:0] == tlb_vppn[5][8:0])
                &&  ( (s0_asid == tlb_asid[5]) || tlb_g[5] ) && tlb_e[5];
assign match0[6] = (s0_vppn[18:9] == tlb_vppn[6][18:9])
                &&  (tlb_ps4MB[6] || s0_vppn[8:0] == tlb_vppn[6][8:0])
                &&  ( (s0_asid == tlb_asid[6]) || tlb_g[6] ) && tlb_e[6];
assign match0[7] = (s0_vppn[18:9] == tlb_vppn[7][18:9])
                &&  (tlb_ps4MB[7] || s0_vppn[8:0] == tlb_vppn[7][8:0])
                &&  ( (s0_asid == tlb_asid[7]) || tlb_g[7] ) && tlb_e[7];
assign match0[8] = (s0_vppn[18:9] == tlb_vppn[8][18:9])
                &&  (tlb_ps4MB[8] || s0_vppn[8:0] == tlb_vppn[8][8:0])
                &&  ( (s0_asid == tlb_asid[8]) || tlb_g[8] ) && tlb_e[8];
assign match0[9] = (s0_vppn[18:9] == tlb_vppn[9][18:9])
                &&  (tlb_ps4MB[9] || s0_vppn[8:0] == tlb_vppn[9][8:0])
                &&  ( (s0_asid == tlb_asid[9]) || tlb_g[9] ) && tlb_e[9];
assign match0[10] = (s0_vppn[18:9] == tlb_vppn[10][18:9])
                &&  (tlb_ps4MB[10] || s0_vppn[8:0] == tlb_vppn[10][8:0])
                &&  ( (s0_asid == tlb_asid[10]) || tlb_g[10] ) && tlb_e[10];
assign match0[11] = (s0_vppn[18:9] == tlb_vppn[11][18:9])
                &&  (tlb_ps4MB[11] || s0_vppn[8:0] == tlb_vppn[11][8:0])
                &&  ( (s0_asid == tlb_asid[11]) || tlb_g[11] ) && tlb_e[11];
assign match0[12] = (s0_vppn[18:9] == tlb_vppn[12][18:9])
                &&  (tlb_ps4MB[12] || s0_vppn[8:0] == tlb_vppn[12][8:0])
                &&  ( (s0_asid == tlb_asid[12]) || tlb_g[12] ) && tlb_e[12];
assign match0[13] = (s0_vppn[18:9] == tlb_vppn[13][18:9])
                &&  (tlb_ps4MB[13] || s0_vppn[8:0] == tlb_vppn[13][8:0])
                &&  ( (s0_asid == tlb_asid[13]) || tlb_g[13] ) && tlb_e[13];
assign match0[14] = (s0_vppn[18:9] == tlb_vppn[14][18:9])
                &&  (tlb_ps4MB[14] || s0_vppn[8:0] == tlb_vppn[14][8:0])
                &&  ( (s0_asid == tlb_asid[14]) || tlb_g[14] ) && tlb_e[14];
assign match0[15] = (s0_vppn[18:9] == tlb_vppn[15][18:9])
                &&  (tlb_ps4MB[15] || s0_vppn[8:0] == tlb_vppn[15][8:0])
                &&  ( (s0_asid == tlb_asid[15]) || tlb_g[15] ) && tlb_e[15];                

assign match1[0] = (s1_vppn[18:9] == tlb_vppn[0][18:9])
                &&  (tlb_ps4MB[0] || s1_vppn[8:0] == tlb_vppn[0][8:0])
                &&  ( (s1_asid == tlb_asid[0]) || tlb_g[0] ) && tlb_e[0];
assign match1[1] = (s1_vppn[18:9] == tlb_vppn[1][18:9])
                &&  (tlb_ps4MB[1] || s1_vppn[8:0] == tlb_vppn[1][8:0])
                &&  ( (s1_asid == tlb_asid[1]) || tlb_g[1] ) && tlb_e[1];
assign match1[2] = (s1_vppn[18:9] == tlb_vppn[2][18:9])
                &&  (tlb_ps4MB[2] || s1_vppn[8:0] == tlb_vppn[2][8:0])
                &&  ( (s1_asid == tlb_asid[2]) || tlb_g[2] ) && tlb_e[2];
assign match1[3] = (s1_vppn[18:9] == tlb_vppn[3][18:9])
                &&  (tlb_ps4MB[3] || s1_vppn[8:0] == tlb_vppn[3][8:0])
                &&  ( (s1_asid == tlb_asid[3]) || tlb_g[3] ) && tlb_e[3];
assign match1[4] = (s1_vppn[18:9] == tlb_vppn[4][18:9])
                &&  (tlb_ps4MB[4] || s1_vppn[8:0] == tlb_vppn[4][8:0])
                &&  ( (s1_asid == tlb_asid[4]) || tlb_g[4] ) && tlb_e[4];
assign match1[5] = (s1_vppn[18:9] == tlb_vppn[5][18:9])
                &&  (tlb_ps4MB[5] || s1_vppn[8:0] == tlb_vppn[5][8:0])
                &&  ( (s1_asid == tlb_asid[5]) || tlb_g[5] ) && tlb_e[5];
assign match1[6] = (s1_vppn[18:9] == tlb_vppn[6][18:9])
                &&  (tlb_ps4MB[6] || s1_vppn[8:0] == tlb_vppn[6][8:0])
                &&  ( (s1_asid == tlb_asid[6]) || tlb_g[6] ) && tlb_e[6];
assign match1[7] = (s1_vppn[18:9] == tlb_vppn[7][18:9])
                &&  (tlb_ps4MB[7] || s1_vppn[8:0] == tlb_vppn[7][8:0])
                &&  ( (s1_asid == tlb_asid[7]) || tlb_g[7] ) && tlb_e[7];
assign match1[8] = (s1_vppn[18:9] == tlb_vppn[8][18:9])
                &&  (tlb_ps4MB[8] || s1_vppn[8:0] == tlb_vppn[8][8:0])
                &&  ( (s1_asid == tlb_asid[8]) || tlb_g[8] ) && tlb_e[8];
assign match1[9] = (s1_vppn[18:9] == tlb_vppn[9][18:9])
                &&  (tlb_ps4MB[9] || s1_vppn[8:0] == tlb_vppn[9][8:0])
                &&  ( (s1_asid == tlb_asid[9]) || tlb_g[9] ) && tlb_e[9];
assign match1[10] = (s1_vppn[18:9] == tlb_vppn[10][18:9])
                &&  (tlb_ps4MB[10] || s1_vppn[8:0] == tlb_vppn[10][8:0])
                &&  ( (s1_asid == tlb_asid[10]) || tlb_g[10] ) && tlb_e[10];
assign match1[11] = (s1_vppn[18:9] == tlb_vppn[11][18:9])
                &&  (tlb_ps4MB[11] || s1_vppn[8:0] == tlb_vppn[11][8:0])
                &&  ( (s1_asid == tlb_asid[11]) || tlb_g[11] ) && tlb_e[11];
assign match1[12] = (s1_vppn[18:9] == tlb_vppn[12][18:9])
                &&  (tlb_ps4MB[12] || s1_vppn[8:0] == tlb_vppn[12][8:0])
                &&  ( (s1_asid == tlb_asid[12]) || tlb_g[12] ) && tlb_e[12];
assign match1[13] = (s1_vppn[18:9] == tlb_vppn[13][18:9])
                &&  (tlb_ps4MB[13] || s1_vppn[8:0] == tlb_vppn[13][8:0])
                &&  ( (s1_asid == tlb_asid[13]) || tlb_g[13] ) && tlb_e[13];
assign match1[14] = (s1_vppn[18:9] == tlb_vppn[14][18:9])
                &&  (tlb_ps4MB[14] || s1_vppn[8:0] == tlb_vppn[14][8:0])
                &&  ( (s1_asid == tlb_asid[14]) || tlb_g[14] ) && tlb_e[14];
assign match1[15] = (s1_vppn[18:9] == tlb_vppn[15][18:9])
                &&  (tlb_ps4MB[15] || s1_vppn[8:0] == tlb_vppn[15][8:0])
                &&  ( (s1_asid == tlb_asid[15]) || tlb_g[15] ) && tlb_e[15];

assign s0_found = (match0[15:0] != 16'b0);
assign s0_index = ({4{match0[15]}} & 4'd15) | ({4{match0[14]}} & 4'd14) | ({4{match0[13]}} & 4'd13) |
                   ({4{match0[12]}} & 4'd12) | ({4{match0[11]}} & 4'd11) | ({4{match0[10]}} & 4'd10) |
                   ({4{match0[9]}} & 4'd9) | ({4{match0[8]}} & 4'd8) | ({4{match0[7]}} & 4'd7) |
                   ({4{match0[6]}} & 4'd6) | ({4{match0[5]}} & 4'd5) | ({4{match0[4]}} & 4'd4) |
                   ({4{match0[3]}} & 4'd3) | ({4{match0[2]}} & 4'd2) | ({4{match0[1]}} & 4'd1) |({4{match0[0]}} & 4'd0);            

wire s0_odd = tlb_ps4MB[s0_index] ? s0_vppn[8] : s0_va_bit12;
assign s0_ps  =   tlb_ps4MB[s0_index]==1'b1 ? 6'd21 :6'd12;
assign s0_ppn =   s0_odd ? tlb_ppn1 [s0_index] : tlb_ppn0 [s0_index];
assign s0_mat =   s0_odd ? tlb_mat1 [s0_index] : tlb_mat0 [s0_index];
assign s0_d   =   s0_odd ? tlb_d1   [s0_index] : tlb_d0   [s0_index];
assign s0_v   =   s0_odd ? tlb_v1   [s0_index] : tlb_v0   [s0_index];
assign s0_plv =   s0_odd ? tlb_plv1 [s0_index] : tlb_plv0 [s0_index];

wire s1_odd  =   tlb_ps4MB[s1_index] ? s1_vppn[8] : s1_va_bit12;
assign s1_ps  =   tlb_ps4MB[s1_index]==1'b1 ? 6'd21 :6'd12;
assign s1_ppn =   s1_odd ? tlb_ppn1 [s1_index] : tlb_ppn0 [s1_index];
assign s1_mat =   s1_odd ? tlb_mat1 [s1_index] : tlb_mat0 [s1_index];
assign s1_d   =   s1_odd ? tlb_d1   [s1_index] : tlb_d0   [s1_index];
assign s1_v   =   s1_odd ? tlb_v1   [s1_index] : tlb_v0   [s1_index];
assign s1_plv =   s1_odd ? tlb_plv1 [s1_index] : tlb_plv0 [s1_index];

assign s1_found = (match1[15:0] != 16'b0);
assign s1_index = ({4{match1[15]}} & 4'd15) | ({4{match1[14]}} & 4'd14) | ({4{match1[13]}} & 4'd13) |
                   ({4{match1[12]}} & 4'd12) | ({4{match1[11]}} & 4'd11) | ({4{match1[10]}} & 4'd10) |
                   ({4{match1[9]}} & 4'd9) | ({4{match1[8]}} & 4'd8) | ({4{match1[7]}} & 4'd7) |
                   ({4{match1[6]}} & 4'd6) | ({4{match1[5]}} & 4'd5) | ({4{match1[4]}} & 4'd4) |
                   ({4{match1[3]}} & 4'd3) | ({4{match1[2]}} & 4'd2) | ({4{match1[1]}} & 4'd1) | ({4{match1[0]}} & 4'd0);           

wire [15:0] cond [3:0];
wire [15:0] invtlb_mask [31:0];
genvar i;
generate for (i = 0;i < 16; i = i + 1)begin
    assign cond[0][i] = ~tlb_g[i];
    assign cond[1][i] = tlb_g[i];
    assign cond[2][i] = s1_asid == tlb_asid[i];
    assign cond[3][i] = (s1_vppn[18:9] == tlb_vppn[i][18:9]) &&  (tlb_ps4MB[i] || s1_vppn[8:0] == tlb_vppn[i][8:0]);
end
endgenerate 
assign invtlb_mask[0] = 16'hffff;
assign invtlb_mask[1] = 16'hffff;
assign invtlb_mask[2] = cond[1];
assign invtlb_mask[3] = cond[0];
assign invtlb_mask[4] = cond[0] & cond[2];
assign invtlb_mask[5] = cond[0] & cond[2] & cond[3];
assign invtlb_mask[6] = (cond[1] | cond[2]) & cond[3];

generate for (i = 7; i < 32; i = i + 1) begin
    assign invtlb_mask[i] = 16'b0; 
end
endgenerate
endmodule
