module imem(addr, w_clk, r_inst_out);
    input wire w_clk;
    input wire [5:0] addr;
    output reg [31:0] r_inst_out;
    reg[31:0] mem[0:63];
    always @(posedge w_clk) begin 
      r_inst_out <= mem[addr];
    end
    initial begin
        mem[0]=32'b00000000000100000000000010010011;
        mem[1]=32'b00000000001000000000000100010011;
        mem[2]=32'b00000000001000001000000110110011;
    end
endmodule
