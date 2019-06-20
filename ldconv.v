// @file ldconv.v
// @breif ldconv(ロードデータ変換器)
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// ロードのデータタイプに応じてデータを変換する．
// 具体的には以下の処理を行う．
//
// * B(byte) タイプ
//   オフセットに応じたバイトを取り出し，符号拡張を行う．
// * BU(byte unsigned) タイプ
//   オフセットに応じたバイトを取り出し，上位に0を詰める．
// * H(half word) タイプ
//   オフセットに応じたハーフワード(16ビット)を取り出し，符号拡張を行う．
// * HU(half word unsigned) タイプ
//   オフセットに応じたハーフワード(16ビット)を取り出し，上位に0を詰める．
// * W(word) タイプ
//   そのままの値を返す．
//
// B, BU, H, HU, W タイプの判別は IR レジスタの内容で行う．
//
// [入出力]
// in:     入力(32ビット)
// ir:     IRレジスタの値
// offset: アドレスオフセット
// out:    出力(32ビット)
module ldconv(input [31:0]  in,
              input [31:0]  ir,
              input [1:0]   offset,
              output [31:0] out);
              

function [31:0] converter;
   input [31:0] in;
   input [31:0] ir;
   input [1:0]  offset;
   
   case (ir[14:12])
      3'b000:  converter = { { 24{ in[(offset<<3)+ 7] } }, in[(offset<<3)+ 7-: 8] }; // LB
      3'b100:  converter = {   24'b0                     , in[(offset<<3)+ 7-: 8] }; // LBU
      3'b001:  converter = { { 16{ in[(offset<<4)+15] } }, in[(offset<<4)+15-:16] }; // LH
      3'b101:  converter = {   16'b0                     , in[(offset<<4)+15-:16] }; // LHU
      3'b010:  converter = in[31:0];                                                 // LW
		default: converter = in[31:0];
	endcase

endfunction


assign out = converter(in, ir, offset);

endmodule // ldconv