module m_sync_mem(w_clk, w_pc, r_inst_out);
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

module m_top();
  reg r_clk=0; initial #150 forever #50 r_clk = ~r_clk;
  reg [31:0] r_pc = 0;
  wire [31:0] inst_out;
  m_sync_mem mem(r_clk, r_pc, inst_out);
  always @(posedge r_clk) begin
    r_pc <= (r_pc + 4) <= 12 ? r_pc + 4 : 12;
  end
  initial #99 forever begin
    #50;
    $display("time: %3d", $time);
    $display("r_clk:        %b", r_clk);
    $display("r_pc:          %5d", r_pc);
    $display("inst:        %b ", inst_out);
    $display("====");
  end
  initial #700 $finish;
endmodule
