module m_top();
    reg r_clk=0; initial #150 forever #50 r_clk = ~r_clk;
    reg r0=0;
    reg r1, r2;
    always @(posedge r_clk) begin
        r0 = ~r0;
        r1 = r0;
        r2 = r1;
    end
    initial #99 forever begin
        #50;
        $display("time: %3d", $time);
        $display("r_clk:        %b", r_clk);
        $display("r0: %b", r0);
        $display("r1: %b", r1);
        $display("r2: %b", r2);
        $display("====");
    end
    initial #700 $finish;
endmodule
