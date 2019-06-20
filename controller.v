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

parameter R_TYPE = 3'b000;
parameter I_TYPE = 3'b001;
parameter S_TYPE = 3'b010;
parameter B_TYPE = 3'b011;
parameter U_TYPE = 3'b100;
parameter J_TYPE = 3'b101;

parameter OP_LUI     = 7'b0110111;
parameter OP_AUIPC   = 7'b0010111;
parameter OP_JAL     = 7'b1101111;
parameter OP_JALR    = 7'b1100111;
parameter OP_BRANCH  = 7'b1100011;
parameter OP_LOAD    = 7'b0000011;
parameter OP_STORE   = 7'b0100011;
parameter OP_IMMCALC = 7'b0010011;
parameter OP_REGCALC = 7'b0110011;
parameter OP_MRETCSR = 7'b1110011;


wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [6:0] funct7 = ir[31:25];


function [3:0] get_mem_wrbits(input f);
   case (ir[14:12])
      3'b000: begin // SB
         case (addr[1:0])
            2'b00: get_mem_wrbits = 4'b0001;
            2'b01: get_mem_wrbits = 4'b0010;
            2'b10: get_mem_wrbits = 4'b0100;
            2'b11: get_mem_wrbits = 4'b1000;
         endcase
      end
      3'b001: begin // SH
         case (addr[1:1])
            1'b0: get_mem_wrbits = 4'b0011;
            1'b1: get_mem_wrbits = 4'b1100; 
         endcase
      end
      default: begin // SWその他
         get_mem_wrbits = 4'b1111;
      end
   endcase
endfunction


function [3:0] get_type(input f);
   if      (opcode == OP_LUI                        ) get_type = U_TYPE; // lui
   else if (opcode == OP_AUIPC                      ) get_type = U_TYPE; // auipc
   else if (opcode == OP_JAL                        ) get_type = J_TYPE; // jal
   else if (opcode == OP_JALR                       ) get_type = I_TYPE; // jalr
   else if (opcode == OP_BRANCH                     ) get_type = B_TYPE; // 分岐
   else if (opcode == OP_LOAD                       ) get_type = I_TYPE; // Load
   else if (opcode == OP_STORE                      ) get_type = S_TYPE; // Store
   else if (opcode == OP_IMMCALC                    ) get_type = I_TYPE; // 即値演算
   else if (opcode == OP_REGCALC                    ) get_type = R_TYPE; // レジスタ演算
   else if (opcode == OP_MRETCSR && funct3 == 3'b000) get_type = R_TYPE; // mret
   else if (opcode == OP_MRETCSR && funct3 != 3'b000) get_type = I_TYPE; // csr
	else                                               get_type = 0;
endfunction


function [31:0] get_imm(input f);
   case(get_type(0))
      I_TYPE:  get_imm = { { 20{ ir[31:31] } }, ir[31:20] };                                         // I
      S_TYPE:  get_imm = { { 20{ ir[31:31] } }, ir[31:25], ir[11:7] };                               // S
      B_TYPE:  get_imm = { { 19{ ir[31:31] } }, ir[31:31], ir[7:7], ir[30:25], ir[11:8], 1'b0 };     // B
      U_TYPE:  get_imm = { ir[31:12], 12'b0 };                                                       // U
      J_TYPE:  get_imm = { { 10{ ir[31:31] } }, ir[31:31], ir[19:12], ir[20:20], ir[30:21], 2'b0 }; // J
      default: get_imm = 0;
   endcase
endfunction


function [3:0] get_alu_ctl(input f);
   if ( cstate == EX ) begin
      if      ( opcode == OP_LUI                                                 ) get_alu_ctl = 4'b0000; // LUI
      else if ( opcode == OP_REGCALC && funct3 == 3'b010                         ) get_alu_ctl = 4'b0011; // レジスタ演算 SLT
      else if ( opcode == OP_REGCALC && funct3 == 3'b011                         ) get_alu_ctl = 4'b0101; // レジスタ演算 SLTU
      else if ( opcode == OP_REGCALC && funct3 == 3'b000 && funct7 == 7'b0000000 ) get_alu_ctl = 4'b1000; // レジスタ演算 ADD
      else if ( opcode == OP_REGCALC && funct3 == 3'b000 && funct7 == 7'b0100000 ) get_alu_ctl = 4'b1001; // レジスタ演算 SUB
      else if ( opcode == OP_REGCALC && funct3 == 3'b100                         ) get_alu_ctl = 4'b1010; // レジスタ演算 XOR
      else if ( opcode == OP_REGCALC && funct3 == 3'b110                         ) get_alu_ctl = 4'b1011; // レジスタ演算 OR
      else if ( opcode == OP_REGCALC && funct3 == 3'b111                         ) get_alu_ctl = 4'b1100; // レジスタ演算 AND
      else if ( opcode == OP_REGCALC && funct3 == 3'b001                         ) get_alu_ctl = 4'b1101; // レジスタ演算 SLL
      else if ( opcode == OP_REGCALC && funct3 == 3'b101 && funct7 == 7'b0000000 ) get_alu_ctl = 4'b1110; // レジスタ演算 SRL
      else if ( opcode == OP_REGCALC && funct3 == 3'b101 && funct7 == 7'b0100000 ) get_alu_ctl = 4'b1111; // レジスタ演算 SRA
      else if ( opcode == OP_IMMCALC && funct3 == 3'b010                         ) get_alu_ctl = 4'b0011; // 即値演算     SLTI
      else if ( opcode == OP_IMMCALC && funct3 == 3'b011                         ) get_alu_ctl = 4'b0101; // 即値演算     SLTIU
      else if ( opcode == OP_IMMCALC && funct3 == 3'b000                         ) get_alu_ctl = 4'b1000; // 即値演算     ADDI
      else if ( opcode == OP_IMMCALC && funct3 == 3'b100                         ) get_alu_ctl = 4'b1010; // 即値演算     XORI
      else if ( opcode == OP_IMMCALC && funct3 == 3'b110                         ) get_alu_ctl = 4'b1011; // 即値演算     ORI
      else if ( opcode == OP_IMMCALC && funct3 == 3'b111                         ) get_alu_ctl = 4'b1100; // 即値演算     ANDI
      else if ( opcode == OP_IMMCALC && funct3 == 3'b001                         ) get_alu_ctl = 4'b1101; // 即値演算     SLLI
      else if ( opcode == OP_IMMCALC && funct3 == 3'b101 && funct7 == 7'b0000000 ) get_alu_ctl = 4'b1110; // 即値演算     SRLI
      else if ( opcode == OP_IMMCALC && funct3 == 3'b101 && funct7 == 7'b0100000 ) get_alu_ctl = 4'b1111; // 即値演算     SRAI
      else                                                                         get_alu_ctl = 4'b1000; // それ以外は足しとく(分岐アドレス計算用)
   end 
   else begin // WBの条件判定用
      if      ( opcode == OP_BRANCH  && funct3 == 3'b000                          ) get_alu_ctl = 4'b0010; // BEQ
      else if ( opcode == OP_BRANCH  && funct3 == 3'b001                          ) get_alu_ctl = 4'b0011; // BNE
      else if ( opcode == OP_BRANCH  && funct3 == 3'b100                          ) get_alu_ctl = 4'b0100; // BLT
      else if ( opcode == OP_REGCALC && funct3 == 3'b010                          ) get_alu_ctl = 4'b0100; // SLT
      else if ( opcode == OP_IMMCALC && funct3 == 3'b010                          ) get_alu_ctl = 4'b0100; // SLTI
      else if ( opcode == OP_BRANCH  && funct3 == 3'b101                          ) get_alu_ctl = 4'b0101; // BGE
      else if ( opcode == OP_BRANCH  && funct3 == 3'b110                          ) get_alu_ctl = 4'b0110; // BLTU
      else if ( opcode == OP_REGCALC && funct3 == 3'b011                          ) get_alu_ctl = 4'b0110; // SLTU
      else if ( opcode == OP_IMMCALC && funct3 == 3'b011                          ) get_alu_ctl = 4'b0110; // SLTIU
      else if ( opcode == OP_BRANCH  && funct3 == 3'b111                          ) get_alu_ctl = 4'b0111; // BGEU
      else                                                                          get_alu_ctl = 4'b1000; // それ以外は足しとく
   end
endfunction

// 0: PC + 4 を用いる
// 1: C レジスタの値を用いる
assign pc_sel     = (cstate == WB && (opcode == OP_JAL || opcode == OP_JALR || opcode == OP_BRANCH) );
assign pc_ld      = (
                       ( cstate == IF ) || 
                       ( cstate == WB && (opcode == OP_JAL || opcode == OP_JALR) ) || 
                       ( cstate == WB && opcode == OP_BRANCH && alu_out == 32'b1 )
                    );
assign mem_sel    = (cstate == WB && (opcode == OP_LOAD || opcode == OP_STORE));
assign mem_read   = (cstate == WB && opcode == OP_LOAD);
assign mem_write  = (cstate == WB && opcode == OP_STORE);
assign mem_wrbits = get_mem_wrbits(0);
assign ir_ld      = (cstate == IF);
assign rs1_addr   = ir[19:15];
assign rs2_addr   = ir[24:20];
assign rd_addr    = ir[11:7];

// 0: メモリの出力を用いる
// 1: PC レジスタの値を用いる
// 2: C レジスタの値を用いる
// 3: CSR の出力を用いる(KAPPA3-RV32I のみ)
assign rd_sel     = (
                       (opcode == OP_LOAD                                                                     ) ? 0: // mem
                       (opcode == OP_JAL     || opcode == OP_JALR                                             ) ? 1: // PC
                       (opcode == OP_IMMCALC || opcode == OP_REGCALC || opcode == OP_LUI || opcode == OP_AUIPC) ? 2: // C
                    3);                                                                                              // その他

// レジスタ書き込み
assign rd_ld      = (cstate == WB && (
                       opcode == OP_IMMCALC || // 即値演算
                       opcode == OP_REGCALC || // レジスタ演算
                       opcode == OP_LUI     || // LUI
                       opcode == OP_AUIPC   || // AUIPC
                       opcode == OP_LOAD    || // Load
                       opcode == OP_JAL     || // JAL
                       opcode == OP_JALR       // JALR
                    ));

// A,B書き込み
assign a_ld       = (cstate == DE);
assign b_ld       = (cstate == DE);

// 0:Aレジスタ  1:PC
assign a_sel      = (cstate == EX && (
                       opcode == OP_AUIPC  || // AUIPC
                       opcode == OP_JAL    || // JAL
                       opcode == OP_BRANCH    // 分岐
                    ));
// 0:Bレジスタ  1:imm
assign b_sel      = (cstate == EX && (opcode != OP_REGCALC));

// 即値
assign imm        = get_imm(0);
// ALU_CTL
assign alu_ctl    = get_alu_ctl(0);
// C書き込み
assign c_ld       = (cstate == EX);

endmodule // controller
