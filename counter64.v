
module counter64 (
    input wire clk,       // 时钟信号
    input wire rst_n,     // 复位信号，低电平有效
    output reg [63:0] count // 64位计数器输出
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        count <= 64'b0; // 复位时计数器清零
    else
        count <= count + 1'b1; // 每个时钟周期计数器加1
end


endmodule