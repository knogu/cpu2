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
    wire [31:0] inst_out, w_next_pc;
    m_ex ex(c2, r_pc, inst_out, w_next_pc);
    reg is_pc_updated = 1;
    always @(posedge c2) begin
        is_pc_updated = ~is_pc_updated;
        if (is_pc_updated) r_pc <= w_next_pc;
    end
	
    wire [7:0] inst_dec;
    m_seven_segment seg1(inst_out[3:0], inst_dec);
    assign HEX0 = inst_dec;

    wire [7:0] pc_dec;
    m_seven_segment seg2(r_pc[3:0], pc_dec);
    assign HEX1 = pc_dec;
	
endmodule
