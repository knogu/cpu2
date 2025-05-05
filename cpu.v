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
  integer i; initial for (i=0; i<32; i=i+1) mem[i]=0;
endmodule

module m_imm_gen(w_clk, w_inst, w_imm);
  input wire w_clk;
  input wire [31:0] w_inst;
  output wire [11:0] w_imm;
  assign w_imm = w_inst[31:20];
endmodule

module m_ex(
    input wire w_clk,
    input wire [31:0] w_pc,
    output wire [31:0] w_next_pc,
    output wire [11:0] w_imm,
    output wire [31:0] w_rs1_val,
    output wire [31:0] w_rs2_val,
    output wire [31:0] w_alu_res
  );

  wire [31:0] w_inst;

  imem mem(w_pc[7:2], w_clk, w_inst);
  // wire[31:0] w_rs1_val, w_rs2_val, w_alu_res;
  m_RF rf(w_clk, w_inst[19:15], w_inst[24:20], 1'b1, w_inst[11:7], w_alu_res, w_rs1_val, w_rs2_val);
  // wire[11:0] w_imm;
  m_imm_gen imm_gen(w_clk, w_inst, w_imm);
  assign w_alu_res = (w_pc == 0 || w_pc == 4) ? w_rs1_val + w_imm : w_rs1_val + w_rs2_val;

  assign w_next_pc = w_pc + 4;
endmodule

module m_top();
  reg r_clk=0; initial #150 forever #50 r_clk = ~r_clk;
  reg [31:0] r_pc = 0;
  wire [31:0] w_next_pc;
  wire[31:0] w_rs1_val, w_rs2_val, w_alu_res;
  wire[11:0] w_imm;
  m_ex ex(r_clk, r_pc, w_next_pc, w_imm, w_rs1_val, w_rs2_val, w_alu_res);
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
    $display("inst:        %b ", ex.w_inst);
    $display("next_pc:        %5d", w_next_pc);
    $display("pc updated:        %5d", is_pc_updated);
    $display("imm:        %5d", ex.w_imm);
    $display("rs1_val:        %5d", ex.w_rs1_val);
    $display("rs2_val:        %5d", ex.w_rs2_val);
    $display("alu_res:        %5d", ex.w_alu_res);
    $display("====");
  end
  initial #900 $finish;
endmodule
