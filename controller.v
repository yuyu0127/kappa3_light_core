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
parameter OP_BEQ     = 7'b1100011;
parameter OP_BNE     = 7'b1100011;
parameter OP_BLT     = 7'b1100011;
parameter OP_BGE     = 7'b1100011;
parameter OP_BLTU    = 7'b1100011;
parameter OP_BGEU    = 7'b1100011;
parameter OP_LOAD    = 7'b0000011;
parameter OP_LB      = 7'b0000011;
parameter OP_LH      = 7'b0000011;
parameter OP_LW      = 7'b0000011;
parameter OP_LBU     = 7'b0000011;
parameter OP_LHU     = 7'b0000011;
parameter OP_STORE   = 7'b0100011;
parameter OP_SB      = 7'b0100011;
parameter OP_SH      = 7'b0100011;
parameter OP_SW      = 7'b0100011;
parameter OP_IMMCALC = 7'b0010011;
parameter OP_ADDI    = 7'b0010011;
parameter OP_SLTI    = 7'b0010011;
parameter OP_SLTIU   = 7'b0010011;
parameter OP_XORI    = 7'b0010011;
parameter OP_ORI     = 7'b0010011;
parameter OP_ANDI    = 7'b0010011;
parameter OP_SLLI    = 7'b0010011;
parameter OP_SRLI    = 7'b0010011;
parameter OP_SRAI    = 7'b0010011;
parameter OP_REGCALC = 7'b0110011;
parameter OP_ADD     = 7'b0110011;
parameter OP_SUB     = 7'b0110011;
parameter OP_SLL     = 7'b0110011;
parameter OP_SLT     = 7'b0110011;
parameter OP_SLTU    = 7'b0110011;
parameter OP_XOR     = 7'b0110011;
parameter OP_SRL     = 7'b0110011;
parameter OP_SRA     = 7'b0110011;
parameter OP_OR      = 7'b0110011;
parameter OP_AND     = 7'b0110011;
parameter OP_MRET    = 7'b1110011;
parameter OP_CSRRW   = 7'b1110011;
parameter OP_CSRRS   = 7'b1110011;
parameter OP_CSRRC   = 7'b1110011;
parameter OP_CSRRWI  = 7'b1110011;
parameter OP_CSRRSI  = 7'b1110011;
parameter OP_CSRRCI  = 7'b1110011;


wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [6:0] funct7 = ir[31:25];


function f_pc_sel(input f);
   if ( cstate == IF )
      f_pc_sel = 0;
   else if (
      ( cstate == WB && (opcode == OP_JAL || opcode == OP_JALR) ) ||
      ( cstate == WB && opcode == OP_BRANCH && alu_out == 32'b1 )
   )
      f_pc_sel = 1;
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


function [3:0] get_type(input f);
   if      (opcode == OP_LUI                       ) get_type = U_TYPE; // lui
   else if (opcode == OP_AUIPC                     ) get_type = U_TYPE; // auipc
   else if (opcode == OP_JAL                       ) get_type = J_TYPE; // jal
   else if (opcode == OP_JALR   && funct3 == 3'b000) get_type = I_TYPE; // jalr
   else if (opcode == OP_BEQ    && funct3 == 3'b000) get_type = B_TYPE; // beq
   else if (opcode == OP_BNE    && funct3 == 3'b001) get_type = B_TYPE; // bne
   else if (opcode == OP_BLT    && funct3 == 3'b100) get_type = B_TYPE; // blt
   else if (opcode == OP_BGE    && funct3 == 3'b101) get_type = B_TYPE; // bge
   else if (opcode == OP_BLTU   && funct3 == 3'b110) get_type = B_TYPE; // bltu
   else if (opcode == OP_BGEU   && funct3 == 3'b111) get_type = B_TYPE; // bgeu
   else if (opcode == OP_LB     && funct3 == 3'b000) get_type = I_TYPE; // lb
   else if (opcode == OP_LH     && funct3 == 3'b001) get_type = I_TYPE; // lh
   else if (opcode == OP_LW     && funct3 == 3'b010) get_type = I_TYPE; // lw
   else if (opcode == OP_LBU    && funct3 == 3'b100) get_type = I_TYPE; // lbu
   else if (opcode == OP_LHU    && funct3 == 3'b101) get_type = I_TYPE; // lhu
   else if (opcode == OP_SB     && funct3 == 3'b000) get_type = S_TYPE; // sb
   else if (opcode == OP_SH     && funct3 == 3'b001) get_type = S_TYPE; // sh
   else if (opcode == OP_SW     && funct3 == 3'b010) get_type = S_TYPE; // sw
   else if (opcode == OP_ADDI   && funct3 == 3'b000) get_type = I_TYPE; // addi
   else if (opcode == OP_SLTI   && funct3 == 3'b010) get_type = I_TYPE; // slti
   else if (opcode == OP_SLTIU  && funct3 == 3'b011) get_type = I_TYPE; // sltiu
   else if (opcode == OP_XORI   && funct3 == 3'b100) get_type = I_TYPE; // xori
   else if (opcode == OP_ORI    && funct3 == 3'b110) get_type = I_TYPE; // ori
   else if (opcode == OP_ANDI   && funct3 == 3'b111) get_type = I_TYPE; // andi
   else if (opcode == OP_SLLI   && funct3 == 3'b001) get_type = I_TYPE; // slli
   else if (opcode == OP_SRLI   && funct3 == 3'b101) get_type = I_TYPE; // srli
   else if (opcode == OP_SRAI   && funct3 == 3'b101) get_type = I_TYPE; // srai
   else if (opcode == OP_ADD    && funct3 == 3'b000) get_type = R_TYPE; // add
   else if (opcode == OP_SUB    && funct3 == 3'b000) get_type = R_TYPE; // sub
   else if (opcode == OP_SLL    && funct3 == 3'b001) get_type = R_TYPE; // sll
   else if (opcode == OP_SLT    && funct3 == 3'b010) get_type = R_TYPE; // slt
   else if (opcode == OP_SLTU   && funct3 == 3'b011) get_type = R_TYPE; // sltu
   else if (opcode == OP_XOR    && funct3 == 3'b100) get_type = R_TYPE; // xor
   else if (opcode == OP_SRL    && funct3 == 3'b101) get_type = R_TYPE; // srl
   else if (opcode == OP_SRA    && funct3 == 3'b101) get_type = R_TYPE; // sra
   else if (opcode == OP_OR     && funct3 == 3'b110) get_type = R_TYPE; // or
   else if (opcode == OP_AND    && funct3 == 3'b111) get_type = R_TYPE; // and
   else if (opcode == OP_MRET   && funct3 == 3'b000) get_type = R_TYPE; // mret
   else if (opcode == OP_CSRRW  && funct3 == 3'b001) get_type = I_TYPE; // csrrw
   else if (opcode == OP_CSRRS  && funct3 == 3'b010) get_type = I_TYPE; // csrrs
   else if (opcode == OP_CSRRC  && funct3 == 3'b011) get_type = I_TYPE; // csrrc
   else if (opcode == OP_CSRRWI && funct3 == 3'b101) get_type = I_TYPE; // csrrwi
   else if (opcode == OP_CSRRSI && funct3 == 3'b110) get_type = I_TYPE; // csrrsi
   else if (opcode == OP_CSRRCI && funct3 == 3'b111) get_type = I_TYPE; // csrrci
endfunction


function [31:0] f_imm(input f);
   case(get_type(0))
      I_TYPE:  f_imm = { { 20{ ir[31:31] } }, ir[31:20] };                                         // I
      S_TYPE:  f_imm = { { 20{ ir[31:31] } }, ir[31:25], ir[11:7] };                               // S
      B_TYPE:  f_imm = { { 19{ ir[31:31] } }, ir[31:31], ir[7:7], ir[30:25], ir[11:8] };           // B
      U_TYPE:  f_imm = { ir[31:12], 12'b0 };                                                       // U
      J_TYPE:  f_imm = { { 10{ ir[31:31] } }, ir[31:31], ir[19:12], ir[20:20], ir[30:21], 10'b0 }; // J
      default: f_imm = 0;
   endcase
endfunction


function [3:0] f_alu_ctl(input f);
   if (cstate == EX) begin
      if      (opcode == OP_LUI                                                ) f_alu_ctl = 4'b0000; // LUI
      else if (opcode == OP_REGCALC && funct3 == 3'b010                        ) f_alu_ctl = 4'b0011; // SLT
      else if (opcode == OP_REGCALC && funct3 == 3'b011                        ) f_alu_ctl = 4'b0101; // SLTU
      else if (opcode == OP_REGCALC && funct3 == 3'b000 && funct7 == 7'b0000000) f_alu_ctl = 4'b1000; // ADD
      else if (opcode == OP_REGCALC && funct3 == 3'b000 && funct7 == 7'b0100000) f_alu_ctl = 4'b1001; // SUB
      else if (opcode == OP_REGCALC && funct3 == 3'b100                        ) f_alu_ctl = 4'b1010; // XOR
      else if (opcode == OP_REGCALC && funct3 == 3'b110                        ) f_alu_ctl = 4'b1011; // OR
      else if (opcode == OP_REGCALC && funct3 == 3'b111                        ) f_alu_ctl = 4'b1100; // AND
      else if (opcode == OP_REGCALC && funct3 == 3'b001                        ) f_alu_ctl = 4'b1101; // SLL
      else if (opcode == OP_REGCALC && funct3 == 3'b101 && funct7 == 7'b0000000) f_alu_ctl = 4'b1110; // SRL
      else if (opcode == OP_REGCALC && funct3 == 3'b101 && funct7 == 7'b0100000) f_alu_ctl = 4'b1111; // SRA
      else                                                                       f_alu_ctl = 4'b1000; // とりあえず足しとけ
   end
   else if (cstate == WB) begin
      if      (opcode == OP_BRANCH && funct3 == 3'b000                         ) f_alu_ctl = 4'b0010; // BEQ
      else if (opcode == OP_BRANCH && funct3 == 3'b100                         ) f_alu_ctl = 4'b0011; // BLT
      else if (opcode == OP_BRANCH && funct3 == 3'b101                         ) f_alu_ctl = 4'b0100; // BGE
      else if (opcode == OP_BRANCH && funct3 == 3'b110                         ) f_alu_ctl = 4'b0101; // BLTU
      else if (opcode == OP_BRANCH && funct3 == 3'b111                         ) f_alu_ctl = 4'b0110; // BGEU
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
assign mem_wrbits = f_mem_wrbits(0);
assign ir_ld      = (cstate == IF);
assign rs1_addr   = ir[19:15];
assign rs2_addr   = ir[24:20];
assign rd_addr    = ir[11:7];

// 0: メモリの出力を用いる
// 1: PC レジスタの値を用いる
// 2: C レジスタの値を用いる
// 3: CSR の出力を用いる(KAPPA3-RV32I のみ)
assign rd_sel     = cstate == WB ? (
                       (opcode == OP_IMMCALC || opcode == OP_REGCALC || opcode == OP_LUI || opcode == OP_AUIPC) ? 2 :
                       (opcode == OP_LOAD) ? 0:
                       (opcode == OP_JAL || opcode == OP_JALR) ? 1:
                    0) : 0;

// レジスタ書き込み
assign rd_ld      = (cstate == WB && (
                       opcode == OP_IMMCALC || // 演算
                       opcode == OP_REGCALC || // 演算
                       opcode == OP_LUI || // LUI
                       opcode == OP_AUIPC || // AUIPC
                       opcode == OP_LOAD || // Load
                       opcode == OP_JAL || // JAL
                       opcode == OP_JALR    // JALR
                    ));

// A,B書き込み
assign a_ld       = (cstate == DE);
assign b_ld       = (cstate == DE);

// 0:Aレジスタ  1:PC
assign a_sel      = cstate == DE ? (
                       opcode == OP_AUIPC || // AUIPC
                       opcode == OP_JAL || // JAL
                       opcode == OP_BRANCH    // 分岐
                    ) : 0;
// 0:Bレジスタ  1:imm
assign b_sel      = cstate == DE ? (
                    !( opcode == OP_REGCALC && funct3 == 3'b000 )
                    ): 0;

// 即値
assign imm        = f_imm(0);
// ALU_CTL
assign alu_ctl    = f_alu_ctl(0);
// C書き込み
assign c_ld       = (cstate == EX);

endmodule // controller
