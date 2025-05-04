module imem(w_clk, w_pc, r_inst_out);
    input wire w_clk;
    input wire [31:0] w_pc;
    output reg [31:0] r_inst_out;
    reg[31:0] mem[0:63];
    always @(posedge w_clk) begin 
      r_inst_out <= mem[w_pc[7:2]];
    end
    initial begin
        mem[0]=32'b0;
        mem[1]=32'd1;
        mem[2]=32'd2;
        mem[3]=32'd4;
    end
endmodule
