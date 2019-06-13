// @file controller.v
// @breif controller(コントローラ)
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// データパスを制御する信号を生成する．
// フェイズは phasegen が生成するので
// このモジュールは完全な組み合わせ回路となる．
//
// [入力]
// cstate:     動作フェイズを表す4ビットの信号
// ir:         IRレジスタの値
// addr:       メモリアドレス(mem_wrbitsの生成に用いる)
// alu_out:    ALUの出力(分岐命令の条件判断に用いる)
//
// [出力]
// pc_sel:     PCの入力選択
// pc_ld:      PCの書き込み制御
// mem_sel:    メモリアドレスの入力選択
// mem_read:   メモリの読み込み制御
// mem_write:  メモリの書き込み制御
// mem_wrbits: メモリの書き込みビットマスク
// ir_ld:      IRレジスタの書き込み制御
// rs1_addr:   RS1アドレス
// rs2_addr:   RS2アドレス
// rd_addr:    RDアドレス
// rd_sel:     RDの入力選択
// rd_ld:      RDの書き込み制御
// a_ld:       Aレジスタの書き込み制御
// b_ld:       Bレジスタの書き込み制御
// a_sel:      ALUの入力1の入力選択
// b_sel:      ALUの入力2の入力選択
// imm:        即値
// alu_ctl:    ALUの機能コード
// c_ld:       Cレジスタの書き込み制御
module controller(input [3:0]    cstate,
                  input [31:0]   ir,
                  input [31:0]   addr,
                  input [31:0]   alu_out,
                  output         pc_sel,
                  output         pc_ld,
                  output         mem_sel,
                  output         mem_read,
                  output         mem_write,
                  output [3:0]   mem_wrbits,
                  output         ir_ld,
                  output [4:0]   rs1_addr,
                  output [4:0]   rs2_addr,
                  output [4:0]   rd_addr,
                  output [1:0]   rd_sel,
                  output         rd_ld,
                  output         a_ld,
                  output         b_ld,
                  output         a_sel,
                  output         b_sel,
                  output [31:0]  imm,
                  output [3:0]   alu_ctl,
                  output         c_ld);

                  
parameter IF = 4'b0001;
parameter DE = 4'b0010;
parameter EX = 4'b0100;
parameter WB = 4'b1000;


wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [6:0] funct7 = ir[31:25];


function f_pc_sel(input f);
   if ( cstate == IF )
      f_pc_sel = 0;
   else if (
      ( cstate == WB && (opcode == 7'b1101111 || opcode == 7'b1100111) ) ||
      ( cstate == WB && opcode == 7'b1100011 && alu_out == 32'b1 )
   )
      f_pc_sel = 1;
endfunction


function f_pc_ld(input f);
   if (
      ( cstate == IF ) || 
      ( cstate == WB && (opcode == 7'b1101111 || opcode == 7'b1100111) ) || 
      ( cstate == WB && opcode == 7'b1100011 && alu_out == 32'b1 )
   )
      f_pc_ld = 1;
   else
      f_pc_ld = 0;
endfunction


function f_mem_sel(input f);
   if ( cstate == IF )
      f_mem_sel = 0;
   else if ( cstate == WB && (opcode == 7'b0000011 || opcode == 7'b0100011) )
      f_mem_sel = 1;
endfunction


function [3:0] f_mem_wrbits(input f);
   case (ir[14:12])
      000: begin // SB
         case (addr[1:0])
            2'b00: f_mem_wrbits = 4'b0001;
            2'b01: f_mem_wrbits = 4'b0010;
            2'b10: f_mem_wrbits = 4'b0100;
            2'b11: f_mem_wrbits = 4'b1000;
         endcase
      end
      001: begin // SH
         case (addr[1])
            1'b0: f_mem_wrbits = 4'b0011;
            1'b1: f_mem_wrbits = 4'b1100; 
         endcase
      end
      default: begin // SWその他
         f_mem_wrbits = 4'b1111;
      end
   endcase
endfunction


function f_rd_sel(input f);
   if (cstate == WB) begin
      if (opcode == 7'b0010011 || opcode == 7'b0110011)
         f_rd_sel = 2; // 演算命令     -> C
      if (opcode == 7'b0110111 || opcode == 7'b0000011)
         f_rd_sel = 0; // ロード命令   -> メモリ
      if (opcode == 7'b1100011)
         f_rd_sel = 1; // ジャンプ命令 -> PC
   end
endfunction


function f_rd_ld(input f);
   if (cstate == WB) begin
      if (
         opcode == 7'b0010011 || 
         opcode == 7'b0110011 || 
         opcode == 7'b0110111 ||
         opcode == 7'b0000011 ||
         opcode == 7'b1100011
      )
         f_rd_ld = 1; 
  end
endfunction

function [31:0] expand(input [11:0] in);
   expand = { { 20{ in[11] } }, in[11:0] };
endfunction

function [31:0]  f_imm(input f);
   f_imm = 0;
endfunction


function [3:0]  f_alu_ctl(input f);
   if (cstate == EX) begin
      if      (opcode == 7'b0110111                                            ) f_alu_ctl = 4'b0000; // LUI
      else if (opcode == 7'b1100011 && funct3 == 3'b000                        ) f_alu_ctl = 4'b0010; // BEQ
      else if (opcode == 7'b1100011 && funct3 == 3'b100                        ) f_alu_ctl = 4'b0011; // BLT
      else if (opcode == 7'b0110011 && funct3 == 3'b010                        ) f_alu_ctl = 4'b0011; // SLT
      else if (opcode == 7'b1100011 && funct3 == 3'b101                        ) f_alu_ctl = 4'b0100; // BGE
      else if (opcode == 7'b1100011 && funct3 == 3'b110                        ) f_alu_ctl = 4'b0101; // BLTU
      else if (opcode == 7'b0110011 && funct3 == 3'b011                        ) f_alu_ctl = 4'b0101; // SLTU
      else if (opcode == 7'b1100011 && funct3 == 3'b111                        ) f_alu_ctl = 4'b0110; // BGEU
      else if (opcode == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000000) f_alu_ctl = 4'b1000; // ADD
      else if (opcode == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0100000) f_alu_ctl = 4'b1001; // SUB
      else if (opcode == 7'b0110011 && funct3 == 3'b100                        ) f_alu_ctl = 4'b1010; // XOR
      else if (opcode == 7'b0110011 && funct3 == 3'b110                        ) f_alu_ctl = 4'b1011; // OR
      else if (opcode == 7'b0110011 && funct3 == 3'b111                        ) f_alu_ctl = 4'b1100; // AND
      else if (opcode == 7'b0110011 && funct3 == 3'b001                        ) f_alu_ctl = 4'b1101; // SLL
      else if (opcode == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0000000) f_alu_ctl = 4'b1110; // SRL
      else if (opcode == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0100000) f_alu_ctl = 4'b1111; // SRA
   end
endfunction


assign pc_sel     = f_pc_sel(0);
assign pc_ld      = f_pc_ld(0);
assign mem_sel    = f_mem_sel(0);
assign mem_read   = (cstate == WB && opcode == 7'b0000011);
assign mem_write  = (cstate == WB && opcode == 7'b0100011);
assign mem_wrbits = f_mem_wrbits(0);
assign ir_ld      = (cstate == IF);
assign rs1_addr   = ir[19:15];
assign rs2_addr   = ir[24:20];
assign rd_addr    = ir[11:7];
assign rd_sel     = f_rd_sel(0);
assign rd_ld      = f_rd_ld(0);
assign a_ld       = (cstate == DE);
assign b_ld       = (cstate == DE);
assign a_sel      = 0;
assign b_sel      = 0;
assign imm        = f_imm(0);
assign alu_ctl    = f_alu_ctl(0);
assign c_ld       = (cstate == EX);

endmodule // controller
