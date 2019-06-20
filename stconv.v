// @file stconv.v
// @breif stconv(ストアデータ変換器)
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// ストア命令用のデータ変換を行う．
// wrbits が1のビットの部分のみ書き込みを行う．
// 具体的には以下の処理を行う．
//
// * B(byte) タイプ
//   in の下位8ビットを4つ複製する．
// * H(half word) タイプ
//   in の下位16ビットを2つ複製する．
// * W(word) タイプ
//   out は in をそのまま．
//
// B, H, W タイプの判別は IR レジスタの内容で行う．
//
// [入出力]
// in:     入力(32ビット)
// ir:     IRレジスタの値
// out:    出力(32ビット)
module stconv(input [31:0]    in,
              input [31:0]    ir,
              output [31:0]   out);


function [31:0] converter;
   input [31:0] in;
   input [31:0] ir;

   case (ir[14:12])
      3'b000:  converter = {4{in[7:0]}};  // SB
      3'b001:  converter = {2{in[15:0]}}; // SH
      3'b010:  converter = in[31:0];      // SW 
      default: converter = in[31:0];      // SW 
   endcase
   
endfunction


assign out = converter(in, ir);

endmodule // stconv
