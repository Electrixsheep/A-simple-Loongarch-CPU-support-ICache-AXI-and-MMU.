`timescale 1ns / 1ps
module sram_axi_bridge(
    input wire clk,
    input wire resetn,
    input  wire        inst_sram_req,
    input  wire        inst_sram_wr,//
    input  wire [1:0]  inst_sram_size,
    input  wire [3:0]  inst_sram_wstrb,//
    input  wire [31:0] inst_sram_addr,
    input  wire [31:0] inst_sram_wdata,//
    output wire        inst_sram_addr_ok,
    output wire        inst_sram_data_ok,
    output wire [31:0] inst_sram_rdata,
    // Data SRAM interface
    input  wire        data_sram_req,
    input  wire        data_sram_wr,
    input  wire [1:0]  data_sram_size,
    input  wire [3:0]  data_sram_wstrb,
    input  wire [31:0] data_sram_addr,
    input  wire [31:0] data_sram_wdata,
    output wire        data_sram_addr_ok,
    output wire        data_sram_data_ok,
    output wire [31:0] data_sram_rdata,
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
    
    input wire br_taken,
    input wire flush,
    input wire st_req,
    //last sign
    output wire rlast_inst,
    output wire rlast_data
    );
/////////////////////////////constant value/////////////////////////////////////////////////////
assign arlen = axi_r_data_sign ? 8'd0 : 8'd3;
assign arburst = 2'b01;
assign arlock = 2'b0;
assign arcache = 4'b0;
assign arprot = 3'b0;    
    
assign awid = 4'b0001;
assign awlen = 8'h0;
assign awburst = 2'b01;    
assign awlock = 2'b0;
assign awcache = 4'b0;
assign awprot = 3'b0; 

assign wid = 4'b0001;
assign wlast = 1'b1;
assign wstrb = data_sram_wstrb;

///////////////////////////////跳转或异常取�?///////////////////////////////////////////////////////
/*wire throw_axi_r;
wire throw_axi_w;
reg throw_axi_r_reg;
reg throw_axi_rid_reg;
assign throw_axi_r = throw_axi_r_reg;
always@(posedge clk)begin
    if(!resetn)begin
        throw_axi_r_reg <= 1'b0;
        throw_axi_rid_reg <= 4'b0;
    end
    else if((ar_state[0] & (br_taken | flush | (st_req | bready))) | (ar_state[1] & (flush | (st_req | bready)))) begin//不能�?单的丢弃第一个数据，尝试通过id分辨
        throw_axi_r_reg <= 1'b1;
        throw_axi_rid_reg <= arid;
    end
    /////////////////////////debug可能�?要注意的////////////////////////////////////////////
    else if(rid == throw_axi_rid_reg & rvalid) begin//读响应返�?
        throw_axi_r_reg <= 1'b0;
    end 
end*/
///////////////////////////////类SRAM从方输入///////////////////////////////////////////////////////
wire axi_r_inst_sign;
wire axi_r_data_sign;
wire axi_w_sign;
assign axi_w_sign = data_sram_req & data_sram_wr;
assign axi_r_inst_sign = ~(st_req | bready) & inst_sram_req;
assign axi_r_data_sign = ~(st_req | bready) & data_sram_req & ~data_sram_wr;
///////////////////////////////////////////////////////////////////////////////////////
wire [1:0] r_req;//00代表无读请求�?01代表当前周期�?个读请求�?10代表当前周期两个读请�?
assign r_req = {1'b0,inst_sram_req} + {1'b0,data_sram_req & ~data_sram_wr}; 
//////////////////////读请求状态机////////////////////////////////////////////////////////////
//throw有效或将要有效（下个周期有效）开始，就只能发送一个读请求至throw无效为止
reg [1:0] ar_state;//0空，1只有取指的读�?2只有数据的读�?3同时有两个的�?
wire [1:0] ar_sign;//00无请求，01当前周期发出指令读，10当前周期发出数据�?
reg [31:0] araddr_reg;
assign arsize = (ar_sign[1] ) ? {1'b0,data_sram_size} : 3'h2;//�?00时的提前逻辑

assign ar_sign = {2{ar_state[0] & ~ar_state[1]}} & 2'b01 
            |    {2{ar_state[1]}} & 2'b10
            |    {2{~ar_state[0] & ~ar_state[1]}} & 2'b00;
assign arid =( ar_state[1] )? 4'b0001 : 4'b0;//�?00时的提前逻辑
assign araddr =  araddr_reg;
assign arvalid = resetn & //(!st_req) &
                ( ar_sign[1] | ar_sign[0] );//�?00时的提前逻辑
always @(posedge clk) begin
    if(!resetn) begin
        ar_state <= 2'b0;
   end    
   //0
   else  if (ar_state == 2'b00) begin
        if(/*throw_axi_r */| (st_req | bready))begin
            ar_state <= ar_state;
        end
        else if (axi_r_data_sign)begin
            ar_state <= 2'b10; 
            araddr_reg <= data_sram_addr;
        end    
        else if (axi_r_inst_sign)begin
            ar_state <= 2'b01;
            araddr_reg <= inst_sram_addr;
        end   
    end 
    //取指读请求状�?
    else if (ar_state == 2'b01) begin
     /*   if(throw_axi_r | (br_taken | flush))begin
            if(arready)begin
                ar_state <= 2'b00; 
            end
            else begin
                ar_state <= ar_state;
            end
        end
        else */if (axi_r_data_sign & arready)begin//握手和数据请求同时来
            ar_state <= 2'b10;
            araddr_reg <= data_sram_addr;
        end   
        else if(arready)
            ar_state <= 2'b00;
    end 
    //数据读请求状�?
    else if (ar_state == 2'b10) begin
    /*    if(throw_axi_r | flush)begin
            if(arready)begin
                ar_state <= 2'b00; 
            end
            else begin
                ar_state <= ar_state;
            end
        end
        else */if (axi_r_inst_sign & arready)begin//握手和数据请求同时来
            ar_state <= 2'b01;
            araddr_reg <= inst_sram_addr;
        end   
        else if(arready)
            ar_state <= 2'b00;
    end 
end
//////////////////////read data,use buffer to output////////////////////////////////////////////////////////////
reg [1:0] r_state;//00没收到，01收到inst的读数据�?10收到data的读数据
reg [31:0] inst_rdata_reg;
reg [31:0] data_rdata_reg;
reg rlast_inst_reg;//to match rdata buffer
reg rlast_data_reg;//to match rdata buffer

assign rlast_inst = rlast_inst_reg;
assign rlast_data = rlast_data_reg;
always @(posedge clk) begin
    if(!resetn) 
        rlast_inst_reg <= 1'b0;
    else if(rlast & rvalid & rready & rid == 4'b0)
        rlast_inst_reg <= 1'b1;
    else 
        rlast_inst_reg <= 1'b0;
end
always @(posedge clk) begin
    if(!resetn) 
        rlast_data_reg <= 1'b0;
    else if(rlast & rvalid & rready & rid == 4'b1)
        rlast_data_reg <= 1'b1;
    else 
        rlast_data_reg <= 1'b0;
end
assign rready = 1'b1;

always @(posedge clk) begin
    if(!resetn) begin
        r_state <= 2'b0;
    end    
   //实际上，任意状�?�在�?01/10的上升沿，已经完成握�?
   else if (r_state == 2'b00) begin
        if (rvalid & rready & rid == 4'b0)begin//指令读响应返�?
            r_state <= 2'b01; 
            inst_rdata_reg <= rdata;
        end    
        else if (rvalid & rready & rid == 4'b1)begin//指令读响应返�?
            r_state <= 2'b10; 
            data_rdata_reg <= rdata;
        end    
    end 
    //取指收到读数据状态握手完成状�?
    else if (r_state == 2'b01) begin//实际上这个状态用于cpu interface数据的准�?
        if (rvalid & rready & (rid == 4'b1))begin//指令读响应返�?
            r_state <= 2'b10; 
            data_rdata_reg <= rdata;
        end
        else if (rvalid & rready & rid == 4'b0)//指令读响应返�?
            inst_rdata_reg <= rdata;
        else 
            r_state <= 2'b00;  
    end 
    //取指收到读数据状态握手完成状�?
    else if (r_state == 2'b10) begin//实际上这个状态用于cpu interface数据的准�?
        if (rvalid & rready & (rid == 4'b0))begin//指令读响应返�?
            r_state <= 2'b01; 
            inst_rdata_reg <= rdata;
        end
        else if (rvalid & rready & rid == 4'b1)//指令读响应返�?
            data_rdata_reg <= rdata;  
        else 
            r_state <= 2'b00;
    end 
end
//////////////////////写请求�?�数据状态机////////////////////////////////////////////////////////////
reg [1:0] w_state;//00无，11数据和地�?都没握手�?01数据未握手成功，10地址未握手成�?
reg [31:0] awaddr_reg;
reg [31:0] wdata_reg;
assign awaddr = awaddr_reg;
assign wdata = wdata_reg;
assign awvalid =resetn &  w_state[1];
assign wvalid = resetn &  w_state[0];
always @(posedge clk) begin
    if(!resetn) begin
        w_state <= 2'b0;
   end    
   //0
    else if (w_state == 2'b00) begin//可优化一个周期：这个状�?�req和arready同时为高的握手？
        if (axi_w_sign)begin
            w_state <= 2'b11; 
            awaddr_reg <= data_sram_addr;
            wdata_reg <= data_sram_wdata;
        end    
    end 
    //数据和地�?都没握手
    else if (w_state == 2'b11) begin
        if(awready & wready)begin
            w_state <= 2'b00;
        end
        else if(awready)begin
            w_state <= 2'b01;
        end   
        else if (wready)begin
            w_state <= 2'b10;
        end
    end 
    //地址未握手成功状�?
    else if (w_state == 2'b10) begin
        if(awready)begin
            w_state <= 2'b00;
        end
    end 
    //数据未握手成功状�?
    else if (w_state == 2'b01) begin
        if(wready)begin
            w_state <= 2'b00;
        end
    end     
    else 
        w_state <= 2'b00;
end
//////////////////////写响应状态机////////////////////////////////////////////////////////////
//响应信号注意与写后读相关�?
reg [1:0] b_state;
assign bready = b_state[0];
always@(posedge clk)begin
    if(!resetn)begin
        b_state <= 2'b00;
    end
    else if(b_state == 2'b00)begin
        if(axi_w_sign)begin
            b_state <= 2'b01;
        end         
    end
    else if(b_state == 2'b01)begin
        if(bvalid)begin
            b_state <= 2'b00;   
        end
    end
end
//////////////////////////////////////////////////////////////////////////////////////////////
assign inst_sram_addr_ok = /*!throw_axi_r*/ &( (ar_state[0] & arready)
                       /*| ( (~ar_state[0]&~ar_state[1]) & ~axi_r_data_sign & axi_r_inst_sign & arready )*/) ;//�?00时的提前逻辑
assign data_sram_addr_ok = (st_req | bready) ?
                    ( (~w_state[0] & w_state[1] & awready) | (w_state[0] & ~w_state[1] & wready) | (w_state[0] & w_state[1] & awready & wready) )
                     : /*(!throw_axi_r) &*/( (ar_state[1] & arready) 
                       /*| ( (~ar_state[0]&~ar_state[1]) & axi_r_data_sign & arready )*/) ;//�?00时的提前逻辑
assign inst_sram_rdata = inst_rdata_reg;
assign data_sram_rdata = data_rdata_reg;
assign inst_sram_data_ok = /*!(throw_axi_r &throw_axi_rid_reg == 4'b0) &*/ (r_state[0] );
assign data_sram_data_ok = (st_req | bready)  ?  ( b_state[0] & bvalid ) :
                       /* ! (throw_axi_r & throw_axi_rid_reg == 4'b1) & */(r_state[1]) ;   
endmodule
