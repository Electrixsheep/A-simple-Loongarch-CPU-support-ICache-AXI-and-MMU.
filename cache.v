module cache(
    input  wire         clk,
    input  wire         resetn,

    // cache - cpu
    input  wire         valid,
    input  wire         op,
    input  wire [ 7: 0] index,
    input  wire [19: 0] tag,
    input  wire [ 3: 0] offset,
    input  wire [ 3: 0] wstrb,
    input  wire [31: 0] wdata,

    output wire         addr_ok,
    output wire         data_ok,
    output wire [31: 0] rdata,

    // cache - axi
    output wire         rd_req,
    output wire [ 2: 0] rd_type,
    output wire [31: 0] rd_addr,
    input  wire         rd_rdy,
    input  wire         ret_valid,
    input  wire         ret_last,
    input  wire [31: 0] ret_data,

    output wire         wr_req,
    output wire [ 2: 0] wr_type,
    output wire [31: 0] wr_addr,
    output wire [ 3: 0] wr_wstrb,
    output wire [127:0] wr_data,
    input  wire         wr_rdy
);
//define
parameter idle = 3'b000,lookup = 3'b001,miss = 3'b010,replace = 3'b011,refill = 3'b100;
reg op_reg; 
reg [ 7:0] index_reg;
reg [19:0] tag_reg;
reg [ 3:0] offset_reg;
reg [ 3:0] wstrb_reg;
reg [31:0] wdata_reg;
reg [2:0] state_main;

    //look up
wire way0_hit;
wire way1_hit;
wire cache_hit;
    //data select
wire [31:0] way0_load_word;
wire [31:0] way1_load_word;
wire load_res;
wire random;//use LFSR to create random
wire replace_data;
wire replace_tag;
wire replace_v;
wire replace_d;
    //miss buffer

reg [1:0] return_num;
    //write buffer
reg w_way_reg;
reg [7:0] w_index_reg;
reg [3:0] w_offset_reg;
reg [3:0] w_wstrb_reg;
reg [31:0] w_data_reg;
//way0
    //tagv
    
wire [19:0] way0_tag;
wire way0_v;
wire wea_tagv0;
wire [7:0] addra_tagv0;
wire [20:0] dina_tagv0;
assign wea_tagv0 = ret_valid & ret_last & ~replace_way;
assign addra_tagv0 = ({8{state_main == lookup  || state_main == idle}} & index)
                 | ({8{state_main == miss || state_main == replace || state_main == refill}} & index_reg);
assign dina_tagv0 = {tag_reg,1'b1};                 
tagv_ram tagv_ram_way0 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_tagv0),      // input wire [0 : 0] wea
  .addra(addra_tagv0),  // input wire [7 : 0] addra
  .dina(dina_tagv0),    // input wire [20 : 0] dina
  .douta({way0_tag,way0_v})  // output wire [20 : 0] douta
);
    //d
reg [255:0] way0_d_reg;
wire way0_d;
assign way0_d = way0_d_reg[index_reg];
always@(posedge clk)begin
    if(!resetn)
        way0_d_reg <= 256'b0;
    else if(wr_state & ~w_way_reg)
        way0_d_reg[w_index_reg] <= 1'b1;
    else if(state_main == refill & ret_valid & ret_last &~replace_way)
        way0_d_reg[index_reg] <= op_reg;    
end
    //data
wire [127:0] way0_data;
wire [7:0] addra_way0_bank0;
wire [3:0] wea_way0_bank0;
wire [31:0] dina_way0_bank0;
wire [7:0] addra_way0_bank1;
wire [3:0] wea_way0_bank1;
wire [31:0] dina_way0_bank1;
wire [7:0] addra_way0_bank3;
wire [3:0] wea_way0_bank3;
wire [31:0] dina_way0_bank3;
wire [7:0] addra_way0_bank2;
wire [3:0] wea_way0_bank2;
wire [31:0] dina_way0_bank2;
assign addra_way0_bank0 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way0_bank0 = ({4{wr_state & ~w_offset_reg[3]&~w_offset_reg[2] & ~w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num == 2'd0) & ret_valid & ~replace_way}});//replace
assign dina_way0_bank0 = ({32{wr_state}} & w_data_reg)  
                      | ({32{state_main == refill}})& (
                       ~offset_reg[3]&~offset_reg[2] & op_reg ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data);
Ram bank0_ram_way0 ( //0 is lowest , 3 is highest
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way0_bank0),      // input wire [3 : 0] wea
  .addra(addra_way0_bank0),  // input wire [7 : 0] addra
  .dina(dina_way0_bank0),    // input wire [31 : 0] dina
  .douta(way0_data[31:0])  // output wire [31 : 0] douta
);

assign addra_way0_bank1 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way0_bank1 = ({4{wr_state & ~w_offset_reg[3]&w_offset_reg[2] & ~w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num == 2'd1) & ret_valid & ~replace_way}});//replace
assign dina_way0_bank1 = ({32{wr_state}} & w_data_reg)  
                      | ({32{state_main == refill}})& (
                       ~offset_reg[3]& offset_reg[2] & op_reg ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data);
Ram bank1_ram_way0 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way0_bank1),      // input wire [3 : 0] wea
  .addra(addra_way0_bank1),  // input wire [7 : 0] addra
  .dina(dina_way0_bank1),    // input wire [31 : 0] dina
  .douta(way0_data[63:32])  // output wire [31 : 0] douta
);
assign addra_way0_bank2 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way0_bank2 = ({4{wr_state & w_offset_reg[3]&~w_offset_reg[2] & ~w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num == 2'd2) & ret_valid & ~replace_way}});//replace
assign dina_way0_bank2 = ({32{wr_state}} & w_data_reg)  
                      | ({32{state_main == refill}})& (
                       offset_reg[3]&~offset_reg[2] & op_reg ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data);
Ram bank2_ram_way0 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way0_bank2),      // input wire [3 : 0] wea
  .addra(addra_way0_bank2),  // input wire [7 : 0] addra
  .dina(dina_way0_bank2),    // input wire [31 : 0] dina
  .douta(way0_data[95:64])  // output wire [31 : 0] douta
);
assign addra_way0_bank3 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way0_bank3 = ({4{wr_state & w_offset_reg[3]&w_offset_reg[2] & ~w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num ==2'd3) & ret_valid & ~replace_way}});//replace
assign dina_way0_bank3 = ({32{wr_state}} & w_data_reg)  
                      | (({32{state_main == refill}})& (
                       offset_reg[3]&offset_reg[2] & op_reg ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data));
Ram bank3_ram_way0 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way0_bank3),      // input wire [3 : 0] wea
  .addra(addra_way0_bank3),  // input wire [7 : 0] addra
  .dina(dina_way0_bank3),    // input wire [31 : 0] dina
  .douta(way0_data[127:96])  // output wire [31 : 0] douta
);
//way1
    //tagv
wire [19:0] way1_tag;
wire way1_v;
wire wea_tagv1;
wire [7:0] addra_tagv1;
wire [20:0] dina_tagv1;
assign wea_tagv1 = ret_valid & ret_last & replace_way;
assign addra_tagv1 = ({32{state_main == lookup  || state_main == idle}} & index)
                 | ({32{state_main == miss || state_main == replace || state_main == refill}} & index_reg);
assign dina_tagv1 = {tag_reg,1'b1};                 
tagv_ram tagv_ram_way1 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_tagv1),      // input wire [0 : 0] wea
  .addra(addra_tagv1),  // input wire [7 : 0] addra
  .dina(dina_tagv1),    // input wire [20 : 0] dina
  .douta({way1_tag,way1_v})  // output wire [20 : 0] douta
);

    //d
reg [255:0] way1_d_reg;
wire way1_d;
assign way1_d = way1_d_reg[index_reg];
always@(posedge clk)begin
    if(!resetn)
        way0_d_reg <= 256'b0;
    else if(wr_state & w_way_reg)
        way1_d_reg[w_index_reg] <= 1'b1;
    else if(state_main == refill & ret_valid & ret_last & replace_way)
        way1_d_reg[index_reg] <= op_reg;    
end
    //data
wire [127:0] way1_data;
wire [7:0] addra_way1_bank0;
wire [3:0] wea_way1_bank0;
wire [31:0] dina_way1_bank0;
wire [7:0] addra_way1_bank1;
wire [3:0] wea_way1_bank1;
wire [31:0] dina_way1_bank1;
wire [7:0] addra_way1_bank3;
wire [3:0] wea_way1_bank3;
wire [31:0] dina_way1_bank3;
wire [7:0] addra_way1_bank2;
wire [3:0] wea_way1_bank2;
wire [31:0] dina_way1_bank2;
assign addra_way1_bank0 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way1_bank0 = ({4{wr_state & ~w_offset_reg[3]&~w_offset_reg[2] & w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num == 2'd0) & ret_valid & replace_way}});//replace
assign dina_way1_bank0 = ({32{wr_state}} & w_data_reg)  
                      | ({32{state_main == refill}})& (
                       ~offset_reg[3]&~offset_reg[2] & op_reg ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data);
Ram bank0_ram_way1 ( //0 is lowest , 3 is highest
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way1_bank0),      // input wire [3 : 0] wea
  .addra(addra_way1_bank0),  // input wire [7 : 0] addra
  .dina(dina_way1_bank0),    // input wire [31 : 0] dina
  .douta(way1_data[31:0])  // output wire [31 : 0] douta
);
assign addra_way1_bank1 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way1_bank1 = ({4{wr_state & ~w_offset_reg[3]&w_offset_reg[2] & w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num == 2'd1) & ret_valid & replace_way}});//replace
assign dina_way1_bank1 = ({32{wr_state}} & w_data_reg)  
                      | ({32{state_main == refill}})& (
                       ~offset_reg[3]&offset_reg[2] & op_reg ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data);
Ram bank1_ram_way1 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way1_bank1),      // input wire [3 : 0] wea
  .addra(addra_way1_bank1),  // input wire [7 : 0] addra
  .dina(dina_way1_bank1),    // input wire [31 : 0] dina
  .douta(way1_data[63:32])  // output wire [31 : 0] douta
);
assign addra_way1_bank2 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way1_bank2 = ({4{wr_state & w_offset_reg[3]&~w_offset_reg[2] & w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num == 2'd2) & ret_valid & replace_way}});//replace
assign dina_way1_bank2 = ({32{wr_state}} & w_data_reg)  
                      | ({32{state_main == refill}})& (
                       offset_reg[3]&~offset_reg[2] & op_reg ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data);
Ram bank2_ram_way1 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way1_bank2),      // input wire [3 : 0] wea
  .addra(addra_way1_bank2),  // input wire [7 : 0] addra
  .dina(dina_way1_bank2),    // input wire [31 : 0] dina
  .douta(way1_data[95:64])  // output wire [31 : 0] douta
);
assign addra_way1_bank3 = wr_state ? w_index_reg : 
                        addr_ok ? index : index_reg ;
assign wea_way1_bank3 = ({4{wr_state & w_offset_reg[3]&w_offset_reg[2] & w_way_reg}} & w_wstrb_reg )//write
                     |({4{state_main == refill & (return_num == 2'd3) & ret_valid & replace_way}});//replace
assign dina_way1_bank3 = ({32{wr_state}} & w_data_reg)  
                      | ({32{state_main == refill}})& (
                       (offset_reg[3]&offset_reg[2] & op_reg) ? {
                                        wstrb_reg[3] ? wdata_reg[31:24] : ret_data[31:24],
                                        wstrb_reg[2] ? wdata_reg[23:16] : ret_data[23:16],
                                        wstrb_reg[1] ? wdata_reg[15: 8] : ret_data[15: 8],
                                        wstrb_reg[0] ? wdata_reg[ 7: 0] : ret_data[ 7: 0]
                                    } : ret_data);
Ram bank3_ram_way1 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea_way1_bank3),      // input wire [3 : 0] wea
  .addra(addra_way1_bank3),  // input wire [7 : 0] addra
  .dina(dina_way1_bank3),    // input wire [31 : 0] dina
  .douta(way1_data[127:96])  // output wire [31 : 0] douta
);

//request buffer
always@(posedge clk)begin
    if(!resetn)begin
        op_reg <= 1'b0; 
        index_reg <= 8'b0; 
        tag_reg <= 20'b0; 
        offset_reg <= 4'b0; 
        wstrb_reg <= 4'b0; 
        wdata_reg   <= 32'b0; 
    end
    else if((state_main == idle & valid & !hit_write_cf) |
            (state_main == lookup & (cache_hit & valid & (op | (!op & !hit_write_cf) ))))begin
        op_reg <= op; 
        index_reg <= index; 
        tag_reg <= tag; 
        offset_reg <= offset; 
        wstrb_reg <= wstrb; 
        wdata_reg   <= wdata;         
    end
end
//tag compare
assign way0_hit = way0_v && {way0_tag == tag_reg};
assign way1_hit = way1_v && {way1_tag == tag_reg};
assign cache_hit = way0_hit || way1_hit;
//data select
assign way0_load_word = way0_data[offset_reg[3:2]*32 +: 32];
assign way1_load_word = way1_data[offset_reg[3:2]*32 +: 32];
assign load_res = {32{way0_hit}} & way0_load_word
                | {32{way1_hit}} & way1_load_word
                | {32{~cache_hit}} & ret_data;
//miss buffer
LFSR u_lfsr(
    .clk(clk),
    .reset(!resetn),
    .lfsr_bit(random)
);                
reg replace_way;//work when enter replace
always@(posedge clk)begin
    if(!resetn)begin
        replace_way <= 1'b0;
    end
    else if(state_main == miss & wr_rdy)begin
        replace_way <= random;
    end
end
always@(posedge clk)begin
    if(!resetn | (state_main == replace && rd_rdy))
        return_num <= 2'b0;
    else if(ret_valid)begin
        return_num <= return_num + 2'b1;
    end
end
//main SM
always@(posedge clk)begin
    if(!resetn)begin
        state_main <= idle;
    end
    else if(state_main == idle)begin
        if(valid & !hit_write_cf)begin
            state_main <= lookup;       
        end
    end
    else if(state_main == lookup)begin
        if(cache_hit & (!valid | (valid & hit_write_cf)))begin
            state_main <= idle;
        end    
        else if(!cache_hit)begin
            state_main <= miss;
        end 
    end
    else if(state_main == miss)begin
        if(wr_rdy)begin
            state_main <= replace;
        end
    end
    else if(state_main == replace)begin
        if(rd_rdy)begin
            state_main <= refill;
        end
    end
    else if(state_main == refill)begin
        if(ret_valid & ret_last)begin
            state_main <= idle;
        end
    end
    else 
        state_main <= idle;
end
//write buffer SM
reg wr_state;
wire hit_write_sign;
wire hit_write_cf;
assign hit_write_sign = (state_main == lookup) & op_reg & cache_hit;
assign hit_write_cf = ( (state_main == lookup) & op_reg & (!op & valid) & ({tag,index,offset} == {tag_reg,index_reg,offset_reg}) ) 
                    | ( wr_state & (!op & valid) & (offset[3:2] == w_offset_reg[3:2]));
always@(posedge clk)begin
    if(!resetn)begin
        wr_state <= 1'b0;
        w_way_reg <= 1'b0;
        w_index_reg <= 8'b0;
        w_offset_reg <= 4'b0;
        w_wstrb_reg <= 4'b0;
        w_data_reg <= 32'b0;
    end
    else if(~wr_state)begin
        if(hit_write_sign)begin
            wr_state <= 1'b1;
            w_way_reg <= way1_hit;
            w_index_reg <= index_reg;
            w_offset_reg <= offset_reg;
            w_wstrb_reg <= wstrb_reg;
            w_data_reg <= wdata_reg; 
        end 
    end
    else if(wr_state)begin
        if(hit_write_sign)begin
            w_way_reg <= way1_hit;
            w_index_reg <= index_reg;
            w_offset_reg <= offset_reg;
            w_wstrb_reg <= wstrb_reg;
            w_data_reg <= wdata_reg; 
        end
        else begin
            wr_state <= 1'b0;
        end    
    end
    else 
        wr_state <= 1'b0;
end
//cpu interface
assign addr_ok = ((state_main == idle) & !hit_write_cf) || 
                 (state_main == lookup & (cache_hit & valid & (op | (!op & !hit_write_cf) ))); 
assign data_ok = (state_main == lookup & (cache_hit)) ||
                 (state_main == refill && ret_valid && return_num == offset_reg[3:2]);
assign rdata = ({32{state_main == lookup & way0_hit}} & way0_load_word)
             | ({32{state_main == lookup & way1_hit}} & way1_load_word)
             | ({32{state_main == refill}} & ret_data);                  
//axi inteface 
assign rd_req = (state_main == replace);
assign rd_type = 3'b100;
assign rd_addr = {tag_reg,index_reg,4'd0};
reg wr_req_reg;
assign wr_req = wr_req_reg & 
            ((replace_way) ? (way1_d & way1_v) : (way0_d & way0_v));
assign wr_type = 3'b100;
assign wr_addr = {(replace_way ? way1_tag : way0_tag),index_reg,4'd0};
assign wr_wstrb = 4'b1111;
assign wr_data = replace_way ? way1_data : way0_data;
always@(posedge clk)begin
    if(!resetn)
        wr_req_reg <= 1'b0;
    else if(state_main == miss & wr_rdy)
        wr_req_reg <= 1'b1;
    else if(wr_rdy)
        wr_req_reg <= 1'b0;
        
end                 
endmodule


module LFSR (
    input wire clk,
    input wire reset,
    output reg lfsr_bit
);
    reg [7:0] lfsr;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= 8'h1; // 初始值，不能为0
        end else begin
            lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5]}; // 反馈多项式 x^8 + x^6 + 1
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr_bit <= 1'b0;
        end else begin
            lfsr_bit <= lfsr[0]; // 输出最低位作为伪随机数
        end
    end
endmodule
