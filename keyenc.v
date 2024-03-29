// @file keyenc.v
// @brief キー入力用のエンコーダ
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// 16個のキー入力用のプライオリティ付きエンコーダ
//
// [入出力]
// keys: キー入力の値
// key_in: いずれかのキーが押された時に1となる出力
// key_val: キーの値(0 - 15)
module keyenc(input [15:0] keys,
              output       key_in,
              output [3:0] key_val);
         
function [3:0] encoder;
input [15:0] f_in;
   begin
      casex (f_in)
      16'bxxxx_xxxx_xxxx_xxx1: encoder = 4'h0;
      16'bxxxx_xxxx_xxxx_xx1x: encoder = 4'h1;
      16'bxxxx_xxxx_xxxx_x1xx: encoder = 4'h2;
      16'bxxxx_xxxx_xxxx_1xxx: encoder = 4'h3;
      16'bxxxx_xxxx_xxx1_xxxx: encoder = 4'h4;
      16'bxxxx_xxxx_xx1x_xxxx: encoder = 4'h5;
      16'bxxxx_xxxx_x1xx_xxxx: encoder = 4'h6;
      16'bxxxx_xxxx_1xxx_xxxx: encoder = 4'h7;
      16'bxxxx_xxx1_xxxx_xxxx: encoder = 4'h8;
      16'bxxxx_xx1x_xxxx_xxxx: encoder = 4'h9;
      16'bxxxx_x1xx_xxxx_xxxx: encoder = 4'ha;
      16'bxxxx_1xxx_xxxx_xxxx: encoder = 4'hb;
      16'bxxx1_xxxx_xxxx_xxxx: encoder = 4'hc;
      16'bxx1x_xxxx_xxxx_xxxx: encoder = 4'hd;
      16'bx1xx_xxxx_xxxx_xxxx: encoder = 4'he;
      16'b1xxx_xxxx_xxxx_xxxx: encoder = 4'hf;
      endcase
   end
endfunction

assign key_in = |keys;
assign key_val = encoder(keys);

endmodule // keyenc
