
`timescale 1ns / 1ps
module if_stage(
input wire clk,
input wire resetn,
//input wire validin,
input wire id_allowin,
input wire ertn_flush,
input wire br_taken,         //跳转标志
input wire [31:0] br_target,        //跳转地址
output wire [31:0] pc_next_o,
output wire if_to_id_valid,

input wire [31:0] exc_entry,

output wire if_allowin,
output wire [31:0] pc_o ,  //pc指针�?,
input wire flush,
input wire exc_wb,
input wire [31:0] csr_eentry_rvalue,
input wire [31:0] csr_era_rvalue,//valid
output wire exc_adef,
input wire [31:0] inst_i,
output wire [31:0] inst_o,
///////////////更新类sram总线
input wire br_stall,
input wire inst_data_ok,
input wire inst_addr_ok,

output wire inst_req,
output wire preif_readygo,
//重取指标�?
input wire exc_refetch_wb,
input wire [31:0] refetch_pc_i,
input wire exc_tlbrentry_i,
input wire [31:0] csr_tlbrentry_i,
//
input wire exc_pif_if,
input wire exc_ppi_fetch_if,
input wire exc_tlbrentry_fetch_if
    );
wire [31:0] pc_next; 
wire [31:0] seq_pc;
wire validin;       // to fs valid
wire inst_req_va;
assign validin = resetn; //&& preif_valid;
//IF REG 
reg [31:0] pc_reg;
reg if_valid;
wire if_readygo;//可能关键
assign if_readygo =   ((inst_data_ok| fake_data_ok) | buf_valid ) & ~flush_throw ;
assign if_allowin = flush |                          //防止阻塞影响冲刷
                    ((!if_valid) || if_readygo && id_allowin);
assign if_to_id_valid = (if_valid && if_readygo);
assign inst_req = inst_req_va & !exc_pif_if & !exc_tlbrentry_fetch_if & !exc_ppi_fetch_if;//judge if it should go to visit axi

//make pipeline go when exc_mmu happened to fetch
//when fetch_illegal valid, we want to pretend addr_ok and data_ok are both "valid��
wire fake_addr_ok;
assign fake_addr_ok = inst_req != inst_req_va;
reg fake_data_ok;
always@(posedge clk)begin
    if(!resetn)
        fake_data_ok <= 1'b0;
    else if ( fake_addr_ok ) 
        fake_data_ok <= 1'b1;
    else 
        fake_data_ok <= 1'b0; 
end     
////////////////////////////    
always@(posedge clk )begin
    if (!resetn ) begin
        if_valid <= 1'b0;
    end
    else if (if_allowin) begin
        if_valid <= (/*~flush & */preif_readygo);//validin;
    end
    else if (br_taken) begin
        if_valid <= 1'b0;
    end
end
        
always@(posedge clk) begin
    if (!resetn)begin
        pc_reg <= 32'h1bfffffc;
    end
    else if ( preif_readygo & (if_allowin) )begin
        pc_reg <= pc_next;
    end
end   
assign pc_o = pc_reg;
//////////////////////////////////////////////////////////////////////////////////临时缓存
reg [31:0] inst_buf;
reg buf_valid;
always@(posedge clk)begin
    if(!resetn)begin
        inst_buf <= 32'h80000000;
        buf_valid <= 1'b0;
    end
    else if(flush | br_taken)begin
        buf_valid <= 1'b0;
    end
    else if (inst_data_ok) begin 
        inst_buf <= inst_i;
        buf_valid <= !id_allowin; 
    end
    else if(if_to_id_valid && id_allowin)
        buf_valid <= 1'b0; 
end
//////////////////////////////////////////////////////////////////////////////////
reg inst_unfinished;
wire inst_unfinished_o;
assign inst_unfinished_o = inst_unfinished;
always@(posedge clk)begin
    if(!resetn)
        inst_unfinished <= 1'b0;
    else if(inst_req & (inst_addr_ok | fake_addr_ok))
        inst_unfinished <= 1'b1;
    else if(inst_data_ok | fake_data_ok)
        inst_unfinished <= 1'b0;    
end
//////////////////////////////////////////////////////////////////////////////////临时缓存,用作跳转pc的存�?
reg [31:0] nextpc_buf;
reg nextpc_buf_valid;
always@(posedge clk)begin
    if(!resetn)begin
        nextpc_buf_valid <= 1'b0;
    end
    else if (!preif_readygo & ( br_taken | flush) ) begin 
        nextpc_buf_valid <= 1'b1; 
        nextpc_buf <= pc_next;
    end 
    else if( preif_readygo & (if_allowin) )begin
        nextpc_buf_valid <= 1'b0;
    end
end
//////////////////////////////////////////////////////////////////////////////////
//pre-IF，即更新pc的阶�?

assign inst_req_va = if_allowin & !br_stall; 
assign preif_readygo = (inst_req_va & (inst_addr_ok | fake_addr_ok)) ;
assign seq_pc       = (exc_refetch_wb ? refetch_pc_i : pc_reg )+ 3'h4;//此处偷懒用了mux，应该可以�?�过更好的时序解�?

assign pc_next = (resetn == 1'b0) ? 32'h1bfffffc: 
                 (exc_tlbrentry_i) ? csr_tlbrentry_i :
                 ((exc_wb & !exc_refetch_wb)  == 1'b1 ) ?(  csr_eentry_rvalue)://exc_wb中包含了重取指操作这个�?�假异常”，重取指操作行为除了跳转pc，其余都跟真异常�?�?
                  ertn_flush == 1'b1 ? ( csr_era_rvalue): 
                (nextpc_buf_valid & !exc_refetch_wb) ? nextpc_buf:
                 ((br_taken == 1'b1 & !exc_refetch_wb)) ? br_target:
                                        (seq_pc);
//////////////////////////////////////////////////////////////////////////////////
assign pc_next_o = pc_next;
assign exc_adef = !(pc_next[1:0] == 2'b00);
assign inst_o = (buf_valid & !(inst_data_ok & id_allowin)) ? inst_buf : inst_i;   //need some kind of fwd logic 
//////////////////////////////////////////////////////////////////////////////////P201
reg flush_throw;//默认异常清理时最多只�?丢弃后续返回的一个数�?
always @ (posedge clk)begin 
    if(!resetn)begin
        flush_throw <= 1'b0;    
    end
    else if( ((br_taken) & ((!if_allowin & !if_readygo))) | ((inst_unfinished_o & ~(inst_data_ok |fake_data_ok)) & flush))begin
            // (inst_unfinished_o&!inst_data_ok)即到本周期都未收到信�?    //优先级或许可以取�?/优化
        flush_throw <= 1'b1;
    end
    else if (inst_data_ok | fake_data_ok) begin
        flush_throw <= 1'b0;
    end
end
endmodule
