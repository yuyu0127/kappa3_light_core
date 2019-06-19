module controller_debugger(input          pc_sel,
                           input          pc_ld,
                           input          mem_sel,
                           input          mem_read,
                           input          mem_write,
                           input  [ 3:0]  mem_wrbits,
                           input          ir_ld,
                           input  [ 4:0]  rs1_addr,
                           input  [ 4:0]  rs2_addr,
                           input  [ 4:0]  rd_addr,
                           input  [ 1:0]  rd_sel,
                           input          rd_ld,
                           input          a_ld,
                           input          b_ld,
                           input          a_sel,
                           input          b_sel,
                           input  [ 3:0]  alu_ctl,
                           input          c_ld,
                           output [63:0]  seg7_dot64);

assign seg7_dot64 = {
	1'b0, mem_write, mem_read, mem_sel, 1'b0, pc_ld, 1'b0  , pc_sel, 
	1'b0, 1'b0,      ir_ld,    1'b0,    mem_wrbits,
	1'b0, 1'b0,      1'b0,     1'b0,    rs1_addr,
	1'b0, 1'b0,      1'b0,     1'b0,    rs2_addr,
	1'b0, 1'b0,      1'b0,     1'b0,    rd_addr,
	1'b0, 1'b0,      rd_ld,    1'b0,    1'b0, 1'b0,  rd_sel,
	1'b0, b_sel,     1'b0,     a_sel,   1'b0, b_ld,  1'b0  , a_ld,
	1'b0, 1'b0,      c_ld,     1'b0,    alu_ctl
};

endmodule // controller_debugger
