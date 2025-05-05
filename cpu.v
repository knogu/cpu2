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

module m_mem(input wire w_clk,
  input wire [31:0] w_addr,
  input wire w_write_enabled,
  input wire [31:0] w_write_data,
  output wire [31:0] w_mem_out);

  reg [31:0] mem [0:63];
  assign w_mem_out = mem[w_addr[7:2]];
  always @(posedge w_clk) begin
    if (w_write_enabled) mem[w_addr[7:2]] <= w_write_data;
  end
  integer i; initial for (i=0; i<64; i=i+1) mem[i] = 32'b0;
endmodule

module m_mux(w_in1, w_in2, w_sel, w_out);
    input wire [31:0] w_in1, w_in2;
    input wire w_sel;
    output wire [31:0] w_out;
    assign w_out = (w_sel) ? w_in2 : w_in1;
endmodule

module main_decoder(input wire [6:0] opcode,
  output wire [1:0] imm_src,
  output wire second_operand_src,
  output wire is_mem_write,
  output wire is_result_from_mem,
  output wire is_reg_write);
  assign imm_src =
    (opcode == 7'b0010011 | opcode == 7'b0000011) ? 2'b00 :
    (opcode == 7'b0100011) ? 2'b01 :
    (opcode == 7'b1100011) ? 2'b10 :
    2'b11;
  assign second_operand_src = (opcode == 7'b0010011) | (opcode == 7'b0000011) | (opcode == 7'b0100011);
  assign is_mem_write = (opcode == 7'b0100011);
  assign is_result_from_mem = (opcode == 7'b0000011);
  assign is_reg_write = (opcode == 7'b0000011) | (opcode == 7'b0110011) | (opcode == 7'b0010011);
endmodule

module m_imm_gen(input wire w_clk,
  input wire [31:0] w_inst,
  input wire [1:0] imm_src,
  output wire [31:0] w_imm
); 
  assign w_imm =
    (imm_src == 2'b00) ? {20'b0, w_inst[31:20]}:
    (imm_src == 2'b01) ? { {20{w_inst[31]}}, w_inst[31:25], w_inst[11:7] }:
    31'b0;
endmodule

module m_alu(input wire[31:0] rs1_val, input wire[31:0] second_operand, output wire[31:0] alu_out);
  assign alu_out = rs1_val + second_operand;
endmodule

module m_ex(
    input wire w_clk,
    input wire [31:0] w_pc,
    output wire [31:0] w_next_pc,
    output wire [31:0] w_alu_res,
    output wire [31:0] w_result,
    output wire [31:0] w_inst,
    output wire [31:0] w_mem_out,
    output wire [31:0] second_operand
  );

  imem imem(w_pc[7:2], w_clk, w_inst);
  wire[31:0] w_rs1_val, w_rs2_val;
  wire is_reg_write;
  m_RF rf(w_clk, w_inst[19:15], w_inst[24:20], is_reg_write, w_inst[11:7], w_result, w_rs1_val, w_rs2_val);
  wire [31:0] w_imm;
  wire [1:0] imm_src;
  wire alu_src;
  wire is_mem_write;
  wire is_result_from_mem;
  main_decoder dec(w_inst[6:0], imm_src, alu_src, is_mem_write, is_result_from_mem, is_reg_write);
  m_imm_gen imm_gen(w_clk, w_inst, imm_src, w_imm);
  
  m_mux second_operand_chooser(w_rs2_val, w_imm, alu_src, second_operand);
  m_alu alu(w_rs1_val, second_operand, w_alu_res);

  // Memory Access
  m_mem mem(w_clk, w_alu_res, is_mem_write, w_rs2_val, w_mem_out);

  // Write Back
  m_mux result_chooser(w_alu_res, w_mem_out, is_result_from_mem, w_result);

  assign w_next_pc = w_pc + 4;
endmodule

module m_top();
  reg r_clk=0; initial #150 forever #50 r_clk = ~r_clk;
  reg [31:0] r_pc = 0;
  wire [31:0] w_next_pc;
  // wire[31:0] w_inst, w_rs1_val, w_rs2_val, w_imm;
  wire[31:0] w_result, w_alu_res, w_mem_out, w_inst, w_second_operand;
  m_ex ex(r_clk, r_pc, w_next_pc, w_alu_res, w_result, w_inst, w_mem_out, w_second_operand);
  reg is_pc_updated = 1;
  always @(posedge r_clk) begin
    is_pc_updated = ~is_pc_updated;
    if (is_pc_updated) r_pc <= w_next_pc;
  end
  initial #99 forever begin
    #100;
    $display("time: %3d", $time);
    $display("r_clk:        %b", r_clk);
    $display("pc:          %5d", r_pc);
    $display("inst:        %b ", ex.w_inst);
    $display("next_pc:        %5d", w_next_pc);
    $display("pc updated:     %5d", is_pc_updated);
    $display("opecode:        %7b", ex.w_inst[6:0]);
    $display("rd:             %5d", ex.w_inst[11:7]);
    $display("rs1:            %5d", ex.w_inst[19:15]);
    $display("rs1_val:        %5d", ex.w_rs1_val);
    $display("rs2:            %5d", ex.w_inst[24:20]);
    $display("rs2_val:        %5d", ex.w_rs2_val);
    $display("imm_src:        %2b", ex.imm_src);
    $display("imm:            %5d", ex.w_imm);
    $display("second_operand: %5d", ex.second_operand);
    $display("alu_res:        %5d", ex.w_alu_res);
    $display("result:         %5d", ex.w_result);
    $display("x1:             %5d", ex.rf.mem[1]);
    $display("x2:             %5d", ex.rf.mem[2]);
    $display("x3:             %5d", ex.rf.mem[3]);
    $display("write reg:      %5d", ex.rf.w_write_addr);
    $display("write data:     %5d", ex.rf.w_write_data);
    $display("write enabled:  %5d", ex.rf.w_write_enabled);
    $display("======================");
  end
  initial begin
    `define MM ex.imem.mem
    `include "asm.txt"
  end
  initial #900 $finish;
endmodule
