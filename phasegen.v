// @file phasegen.v
// @breif フェーズジェネレータ
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// 命令フェイズを生成する．
//
// cstate = {cs_wb, cs_ex, cs_de, cs_if}
// で，常に1つのビットのみ1になっている．
// cs_wb = cstate[3], cs_if = cstate[0]
// であることに注意．
// 各ビットの意味は以下の通り．
// cs_if: IF フェーズ
// cs_de: DE フェーズ
// cs_ex: EX フェーズ
// cs_wb: WB フェーズ
//
// [入出力]
// clock:      クロック信号(立ち上がりエッジ)
// reset:      リセット信号(0でリセット)
// run:        実行開始
// step_phase: 1フェイズ実行
// step_inst:  1命令実行
// cstate:     命令実行フェーズを表すビットベクタ
// running:    実行中を表す信号
module phasegen(input  	     clock,
		input 	     reset,
		input 	     run,
		input 	     step_phase,
		input 	     step_inst,
		output reg [3:0] cstate,
		output      running);
		
parameter IF         = 4'b0001;
parameter DE         = 4'b0010;
parameter EX         = 4'b0100;
parameter WB         = 4'b1000;

parameter STOP       = 2'b00;
parameter RUN        = 2'b01;
parameter STEP_INST  = 2'b10;
parameter STEP_PHASE = 2'b11;
		
reg [1:0] state;


function [3:0] next_phase(input [3:0] phase);
	case ( phase )
		IF: next_phase = DE;
		DE: next_phase = EX;
		EX: next_phase = WB;
		WB: next_phase = IF;
		default: next_phase = IF;
	endcase
endfunction


always @ ( posedge clock ) begin
	if ( !reset ) begin
		// reset が0 のときphase をIF にし，内部状態をStop にする．
		cstate = IF;
		state = STOP;
	end
	else begin
		case ( state )
			STOP: begin
				if ( run ) state = RUN;
				if ( step_inst ) state = STEP_INST;
				if ( step_phase ) state = STEP_PHASE;
			end
			
			RUN: begin
				if ( run ) state = STOP;
				cstate = next_phase(cstate);
			end
			
			STEP_INST: begin
				if ( cstate == WB ) begin
					cstate = IF;
					state = STOP;
				end 
				else begin
					cstate = next_phase(cstate);
				end
			end
			
			STEP_PHASE: begin
				cstate = next_phase(cstate);
				state = STOP;
			end
		endcase
	end
end


assign running = (state != STOP);


endmodule // phasegen
