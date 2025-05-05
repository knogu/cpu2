module TopModule(
	//////////// CLOCK //////////
	input 		          		CLK1,
	input 		          		CLK2,
	//////////// SEG7 //////////
	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,
	//////////// Push Button //////////
	input 		     [1:0]		BTN,
	//////////// LED //////////
	output		     [9:0]		LED,
	//////////// SW //////////
	input 		     [9:0]		SW

	);

    wire c1,c2;
    m_prescale50000 u0(CLK1, c1);
    m_prescale1000 u1(CLK1, c1, c2);

    reg [31:0] r_pc = 0;
    wire [31:0] w_next_pc;
    wire[31:0] w_inst, w_alu_res, w_result, w_mem_out, w_imm;
    m_ex ex(c2, r_pc, w_next_pc, w_alu_res, w_result, w_inst, w_mem_out, w_imm);
    reg is_pc_updated = 1;
    always @(posedge c2) begin
        is_pc_updated = ~is_pc_updated;
        if (is_pc_updated) r_pc <= w_next_pc;
    end
	
    wire [7:0] pc_dec;
    m_seven_segment seg1(r_pc[3:0], pc_dec);
    assign HEX0 = pc_dec;

    wire [7:0] inst_dec;
    m_seven_segment seg2(w_inst[3:0], inst_dec);
    assign HEX1 = inst_dec;

    wire [7:0] alu_res_dec;
    m_seven_segment seg3(w_alu_res[3:0], alu_res_dec);
    assign HEX2 = alu_res_dec;
    
    wire [7:0] mem_out_dec;
    m_seven_segment seg4(w_mem_out[3:0], mem_out_dec);
    assign HEX3 = mem_out_dec;

    wire [7:0] result_dec;
    m_seven_segment seg5(w_result[3:0], result_dec);
    assign HEX4 = result_dec;

    wire [7:0] second_operand_dec;
    m_seven_segment seg6(w_imm[3:0], second_operand_dec);
    assign HEX5 = second_operand_dec;

endmodule
