// @file decode_7seg.v
// @breif 7SEG-LED のデコーダ回路
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// 7SEG-LED に 0-9, A-F のパタンを表示するためのデコーダ
//
// [入出力]
// in:  入力(4ビット)
// out: 出力(8ビット)
module decode_7seg(input [3:0] in,
		   output [7:0] out);
			
function [7:0] decoder;
input [3:0] f_in;
	begin
		case (f_in)
		4'h0: decoder = 8'b1111_1100;
		4'h1: decoder = 8'b0110_0000;
		4'h2: decoder = 8'b1101_1010;
		4'h3: decoder = 8'b1111_0010;
		4'h4: decoder = 8'b0110_0110;
		4'h5: decoder = 8'b1011_0110;
		4'h6: decoder = 8'b1011_1110;
		4'h7: decoder = 8'b1110_0000;
		4'h8: decoder = 8'b1111_1110;
		4'h9: decoder = 8'b1111_0110;
		4'ha: decoder = 8'b1110_1110;
		4'hb: decoder = 8'b0011_1110;
		4'hc: decoder = 8'b0001_1010;
		4'hd: decoder = 8'b0111_1010;
		4'he: decoder = 8'b1001_1110;
		4'hf: decoder = 8'b1000_1110;
		endcase
	end
endfunction

assign out = decoder(in);

endmodule // decode_7seg
