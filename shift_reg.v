module m_main(w_clk, w_in, w_out);
    input wire w_clk, w_in;
    output wire w_out;
    reg [3:0] r_s = 0;
    always@(posedge w_clk) r_s <= {w_in, r_s[3:1]};
    assign w_out = r_s[0];
endmodule

module m_top();
    reg r_clk = 0;
    initial #150 forever #50 r_clk = ~r_clk;
    wire w_out;
    reg r_in = 1;
    m_main m(r_clk, r_in, r_out);
    initial #700 $finish;
    initial #99 forever begin
        #50;
        $display("======");
        $display("time: %3d", $time);
        $display("reg: %4b", m.r_s);
        $display("out: %3d", r_out);
    end
endmodule
