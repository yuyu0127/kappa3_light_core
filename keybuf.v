// @file keybuf.v
// @brief キー入力バッファ
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// 16個のキー入力用のプライオリティ付きエンコーダ
//
// [入出力]
// clock:   クロック
// reset:   リセット
// key_in:  いずれかのキーが押された時に1となる信号
// key_val: キーの値(0 - 15)
// clear:   クリア信号
// out:     バッファの値
module keybuf(input         clock,
         input        reset,
         input        key_in,
         input [3:0]   key_val,
         input        clear,
         output reg [31:0] out);


always @(posedge clock)
begin
   if (clear) begin
      out = 32'b0;
   end
   else begin
      if (key_in) begin
         out = (out << 4) + key_val;
      end
   end
end

endmodule // keyenc
