module m_RF(w_clk, w_rs1, w_rs2, w_write_enabled, w_write_addr, w_write_data, w_rs1_val, w_rs2_val);
  input wire w_clk, w_write_enabled;
  input wire[4:0] w_rs1, w_rs2, w_write_addr;
  input wire[31:0] w_write_data;
  output wire[31:0] w_rs1_val, w_rs2_val;

  reg[31:0] mem[0:63];
  assign w_rs1_val = (w_rs1 == 5'd0) ? 32'd0 : mem[w_rs1];
  assign w_rs2_val = (w_rs2 == 5'd0) ? 32'd0 : mem[w_rs2];
  always @(posedge w_clk) if (w_write_enabled) mem[w_write_addr] <= w_write_data;
  always @(posedge w_clk) if (w_write_enabled & w_write_addr == 5'd30) $finish;
endmodule

module m_ex(w_clk, w_pc, r_inst_out, w_next_pc);
  input wire w_clk;
  input wire [31:0] w_pc;
  output wire [31:0] r_inst_out, w_next_pc;

  imem mem(w_clk, w_pc, r_inst_out);
  assign w_next_pc = w_pc + 4;
endmodule

module m_top();
  reg r_clk=0; initial #150 forever #50 r_clk = ~r_clk;
  reg [31:0] r_pc = 0;
  wire [31:0] inst_out, w_next_pc;
  m_ex ex(r_clk, r_pc, inst_out, w_next_pc);
  reg is_pc_updated = 1;
  always @(posedge r_clk) begin
    is_pc_updated = ~is_pc_updated;
    if (is_pc_updated) r_pc <= w_next_pc;
  end
  initial #99 forever begin
    #100;
    $display("time: %3d", $time);
    $display("r_clk:        %b", r_clk);
    $display("r_pc:          %5d", r_pc);
    $display("inst:        %b ", inst_out);
    $display("next_pc:        %5d", w_next_pc);
    $display("pc updated:        %5d", is_pc_updated);
    $display("====");
  end
  initial #700 $finish;
endmodule
