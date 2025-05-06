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

module m_mux_2bit(w_in1, w_in2, w_in3, w_in4, w_sel, w_out);
    input wire [31:0] w_in1, w_in2, w_in3, w_in4;
    input wire [1:0] w_sel;
    output wire [31:0] w_out;
    assign w_out = (w_sel == 2'b00) ? w_in1 :
                   (w_sel == 2'b01) ? w_in2 :
                   (w_sel == 2'b10) ? w_in3 :
                   w_in4;
endmodule

module main_decoder(input wire [6:0] opcode,
  input  wire [2:0] funct3,
  output wire second_operand_src,
  output wire [1:0] result_src,
  output wire is_reg_write,
  output wire is_branch_if_zero,
  output wire is_branch_if_nonzero,
  output wire is_jmp,
  output wire [2:0] alu_control,
  output wire is_j,
  output wire is_b,
  output wire is_s,
  output wire is_r,
  output wire is_u,
  output wire is_i,
  output wire is_jalr);

  assign is_j = (opcode[6:2] == 5'b11011);
  assign is_b = (opcode[6:2] == 5'b11000);
  assign is_s = (opcode[6:2] == 5'b01000);
  assign is_r = (opcode[6:2] == 5'b01100);
  assign is_u = (opcode[6:2] == 5'b01101 || opcode[6:2] ==5'b00101);
  assign is_i = ~(is_j | is_b | is_s | is_r | is_u);
  assign is_jalr = (opcode == 7'b1100111);
  assign is_lui = (opcode == 7'b0110111);
  assign is_auipc = (opcode == 7'b0010111);
  
  assign second_operand_src = is_i | is_s | is_jalr | is_lui;
  assign result_src = (opcode == 7'b0000011) ? 2'b01 :
                      (opcode == 7'b1101111) ? 2'b10 :
                      is_auipc ? 2'b11 :
                      0;
  assign is_reg_write = (opcode == 7'b0000011) | (opcode == 7'b0110011) | (opcode == 7'b0010011) | (opcode == 7'b1101111) |
                        is_lui | is_auipc ;
  assign is_branch_if_zero = (is_b & funct3 == 3'b000);
  assign is_branch_if_nonzero = (is_b & funct3 == 3'b001);
  assign is_jmp = (opcode == 7'b1101111);
  assign alu_control = (opcode == 7'b0000011 | opcode == 7'b0100011) ? 3'b000 : // load and store
                       (opcode == 7'b1100011) ? 3'b001 :
                       is_lui ? 3'b100 :
                       3'b000; // add
  
endmodule

module m_imm_gen(input wire w_clk,
  input wire [31:0] w_inst,
  input wire is_j,
  input wire is_b,
  input wire is_s,
  input wire is_r,
  input wire is_u,
  input wire is_i,
  output wire [31:0] w_imm
); 
  assign w_imm = (is_i) ? { {20{w_inst[31]}}, w_inst[31:20] } :
                 (is_s) ? { {20{w_inst[31]}}, w_inst[31:25], w_inst[11:7] } :
                 (is_b) ? { {20{w_inst[31]}}, w_inst[7], w_inst[30:25], w_inst[11:8], 1'b0} :
                 (is_u) ? { w_inst[31:12], 12'b0 } :
                 (is_j) ? { {12{w_inst[31]}}, w_inst[19:12], w_inst[20], w_inst[30:21], 1'b0 } :
                 0;
endmodule

module m_adder(input wire [31:0] w_in1, input wire [31:0] w_in2, output wire [31:0] w_out);
  assign w_out = w_in1 + w_in2;
endmodule

module m_is_next_pc_jmp_br(
  input wire is_branch_if_zero,
  input wire is_branch_if_nonzero,
  input wire is_alu_out_zero,
  input wire is_jmp,
  output wire is_jmp_or_br
);
  assign is_jmp_or_br = (is_jmp) |
                        (is_branch_if_zero & is_alu_out_zero) |
                        (is_branch_if_nonzero & !is_alu_out_zero);
endmodule

module m_alu(input wire[31:0] rs1_val, input wire[31:0] second_operand, input wire [2:0] alu_control, output wire[31:0] alu_out);
  assign alu_out = (alu_control == 3'b001) ? rs1_val - second_operand :
                   (alu_control == 3'b100) ? second_operand :
                   rs1_val + second_operand;
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
  wire alu_src;
  wire [1:0] result_src;
  wire is_branch_if_zero;
  wire is_branch_if_nonzero;
  wire [2:0] alu_control;
  wire is_jmp;
  wire is_j, is_b, is_s, is_r, is_u, is_i, is_jalr;
  main_decoder dec(w_inst[6:0], w_inst[14:12], alu_src, result_src, is_reg_write, is_branch_if_zero, is_branch_if_nonzero, is_jmp, alu_control, is_j, is_b, is_s, is_r, is_u, is_i, is_jalr);
  m_imm_gen imm_gen(w_clk, w_inst, is_j, is_b, is_s, is_r, is_u, is_i, w_imm);
  
  m_mux second_operand_chooser(w_rs2_val, w_imm, alu_src, second_operand);
  // wire is_alu_out_zero;
  m_alu alu(w_rs1_val, second_operand, alu_control, w_alu_res);
  wire [31:0] pc_plus_imm;
  m_adder br_or_jmp(w_pc, w_imm, pc_plus_imm);
  wire is_pc_jmp_or_br;
  m_is_next_pc_jmp_br m(is_branch_if_zero, is_branch_if_nonzero, (w_alu_res == 0), is_jmp, is_pc_jmp_or_br);

  // Memory Access
  m_mem mem(w_clk, w_alu_res, is_s, w_rs2_val, w_mem_out);

  // Write Back
  m_mux_2bit result_chooser(w_alu_res, w_mem_out, w_pc+4, pc_plus_imm, result_src, w_result);

  assign w_next_pc = is_jalr ? {w_alu_res[31:1], 1'b0} :
                     is_pc_jmp_or_br ? pc_plus_imm :
                     w_pc + 4;
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
    $display("is_pc_jmp_or_br: %b", ex.is_pc_jmp_or_br);
    $display("pc updated:     %5d", is_pc_updated);
    $display("opecode:        %7b", ex.w_inst[6:0]);
    $display("is_i:           %b",  ex.is_i);
    $display("is_s:           %b",  ex.is_s);
    $display("rd:             %5d", ex.w_inst[11:7]);
    $display("rs1:            %5d", ex.w_inst[19:15]);
    $display("rs1_val:        %5d", ex.w_rs1_val);
    $display("rs2:            %5d", ex.w_inst[24:20]);
    $display("rs2_val:        %5d", ex.w_rs2_val);
    $display("imm:            %5d", $signed(ex.w_imm));
    $display("imm_u:          %5d", ex.w_imm);
    $display("second_operand: %5d", ex.second_operand);
    $display("alu_control:    %3b", ex.alu_control);
    $display("alu_res:        %5d", ex.w_alu_res);
    $display("result_src:     %2b", ex.result_src);
    $display("result:         %5d", ex.w_result);
    $display("x1:             %5d", ex.rf.mem[1]);
    $display("x2:             %5d", ex.rf.mem[2]);
    $display("x3:             %5d", ex.rf.mem[3]);
    $display("write reg:      %5d", ex.rf.w_write_addr);
    $display("write data:     %5d", ex.rf.w_write_data);
    $display("is_reg_write:  %5d", ex.rf.w_write_enabled);
    $display("======================");
  end
  initial begin
    `define MM ex.imem.mem
    `include "asm.txt"
  end
  initial #900 $finish;
endmodule
