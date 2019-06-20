// @file kappa3_light_core_dp.v
// @breif KAPPA3-LIGHT のデータパス
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// KAPPA3-LIGHT のデータパス(正確にはレジスタとメモリ)のみのモジュール
// debugger で各レジスタにアクセスすることを目的としている．
//
// [入出力]
// clock:         クロック
// clock2:        clock を2分周したもの
// reset:         リセット
// run:           実行開始
// step_phase:    フェイズごとの実行
// step_inst:     命令ごとの実行
// cstate:        制御状態信号
// running:       実行中を示すフラグ
// dbg_in:        デバッグ用の書込みデータ
// dbg_pc_ld:     デバッグ用のPCの書込みイネーブル
// dbg_ir_ld:     デバッグ用のIRの書込みイネーブル
// dbg_reg_ld:    デバッグ用のレジスタファイルの書込みイネーブル
// dbg_reg_addr:  デバッグ用のレジスタファイルのアドレス
// dbg_a_ld:      デバッグ用のAレジスタの書込みイネーブル
// dbg_b_ld:      デバッグ用のBレジスタの書込みイネーブル
// dbg_c_ld:      デバッグ用のCレジスタの書込みイネーブル
// dbg_mem_addr:  デバッグ用のメモリアドレス
// dbg_mem_read:  デバッグ用のメモリ読み出しイネーブル
// dbg_mem_write: デバッグ用のメモリ書込みイネーブル
// dbg_pc_out:    デバッグ用のPC出力
// dbg_ir_out:    デバッグ用のIR出力
// dbg_reg_out:   デバッグ用のレジスタファイル出力
// dbg_a_out:     デバッグ用のAレジスタ出力
// dbg_b_out:     デバッグ用のBレジスタ出力
// dbg_c_out:     デバッグ用のCレジスタ出力
// dbg_mem_out:   デバッグ用のメモリ出力
module kappa3_light_core(input            clock,
                         input            clock2,
                         input            reset,

                         // 実行制御
                         input            run,
                         input            step_phase,
                         input            step_inst,

                         output [3:0]     cstate,
                         output           running,

                         // デバッグ関係
                         input [31:0]     dbg_in,
                         input            dbg_pc_ld,
                         input            dbg_ir_ld,
                         input            dbg_reg_ld,
                         input [4:0]      dbg_reg_addr,
                         input            dbg_a_ld,
                         input            dbg_b_ld,
                         input            dbg_c_ld,
                         input [31:0]     dbg_mem_addr,
                         input            dbg_mem_read,
                         input            dbg_mem_write,
                         output [31:0]    dbg_pc_out,
                         output [31:0]    dbg_ir_out,
                         output [31:0]    dbg_reg_out,
                         output [31:0]    dbg_a_out,
                         output [31:0]    dbg_b_out,
                         output [31:0]    dbg_c_out,
                         output [31:0]    dbg_mem_out,
                         output [63:0]    dbg_seg7_dot64);

// デバッグモードの信号
wire     dbg_mode;
assign   dbg_mode = !running;

// PC
wire [31:0]          pc_in;      // PC の書き込みデータ
wire                 pc_ld;      // PC の書き込みイネーブル信号
wire [31:0]          pc_out;     // PC の出力
wire                 pc_sel;

assign pc_in = pc_sel ? c_out : pc_out + 4;
assign pc_ld = ctl_pc_ld;

reg32 pc_inst(.clock(clock2),
              .reset(reset),
              .in(pc_in),
              .ld(pc_ld),
              .out(pc_out),
              .dbg_mode(dbg_mode),
              .dbg_in(dbg_in),
              .dbg_ld(dbg_pc_ld));

assign dbg_pc_out = pc_out;

// IR
wire [31:0]       ir_in;      // IR の書き込みデータ
wire              ir_ld;      // IR の書き込みイネーブル信号
wire [31:0]       ir_out;     // IRの値

assign ir_in = mem_rddata;
assign ir_ld = ctl_ir_ld;

reg32 ir_inst(.clock(clock2),
              .reset(reset),
              .in(ir_in),
              .ld(ir_ld),
              .out(ir_out),
              .dbg_mode(dbg_mode),
              .dbg_in(dbg_in),
              .dbg_ld(dbg_ir_ld));
assign dbg_ir_out = ir_out;

// メモリ
wire [31:0]       mem_addr;
wire [31:0]       mem_wrdata;
wire [3:0]        mem_wrbits;
wire              mem_read;
wire              mem_write;
wire [31:0]       mem_rddata;

assign mem_addr   = ctl_mem_sel ? c_out : pc_out;
assign mem_wrdata = stconv_out;
assign mem_wrbits = ctl_mem_wrbits;
assign mem_read   = ctl_mem_read;
assign mem_write  = ctl_mem_write;

memory mem_inst(.clock(clock),
                .address(mem_addr),
                .read(mem_read),
                .write(mem_write),
                .wrdata(mem_wrdata),
                .wrbits(mem_wrbits),
                .rddata(mem_rddata),
                .dbg_address(dbg_mem_addr),
                .dbg_read(dbg_mem_read),
                .dbg_write(dbg_mem_write),
                .dbg_in(dbg_in),
                .dbg_out(dbg_mem_out));

// reg-file
wire [4:0]        rs1_addr;     // rs1 のアドレス
wire [4:0]        rs2_addr;     // rs2 のアドレス
wire [4:0]        rd_addr;      // rd のアドレス
wire [31:0]       rd_in;        // rd に書き込む値
wire              rd_ld;        // rd の書込みイネーブル信号
wire [31:0]       rs1;          // rs1 の値
wire [31:0]       rs2;          // rs2 の値

assign rs1_addr = ctl_rs1_addr;
assign rs2_addr = ctl_rs2_addr;
assign rd_addr  = ctl_rd_addr;
assign rd_in    = ctl_rd_sel == 0 ? ldconv_out : (ctl_rd_sel == 1 ? pc_out : (ctl_rd_sel == 2 ? c_out : (ctl_rd_sel == 3 ? ctl_csr_out : 0 ) ) );
assign rd_ld    = ctl_rd_ld;

regfile regfile_inst(.clock(clock2),
                     .reset(reset),
                     .rs1_addr(rs1_addr),
                     .rs2_addr(rs2_addr),
                     .rd_addr(rd_addr),
                     .in(rd_in),
                     .ld(rd_ld),
                     .rs1_out(rs1),
                     .rs2_out(rs2),
                     .dbg_mode(dbg_mode),
                     .dbg_in(dbg_in),
                     .dbg_addr(dbg_reg_addr),
                     .dbg_ld(dbg_reg_ld),
                     .dbg_out(dbg_reg_out));

// A-reg
wire [31:0]       a_in;
wire              a_ld;         // A-reg の書込みイネーブル信号
wire [31:0]       a_out;         // A-reg の値

assign a_in = rs1;
assign a_ld = ctl_a_ld;

reg32 areg_inst(.clock(clock2),
                .reset(reset),
                .in(a_in),
                .ld(a_ld),
                .out(a_out),
                .dbg_mode(dbg_mode),
                .dbg_in(dbg_in),
                .dbg_ld(dbg_a_ld));
assign dbg_a_out = a_out;
//assign dbg_a_out = alu_in1;

// B-reg
wire [31:0]       b_in;
wire              b_ld;         // B-reg の書込みイネーブル信号
wire [31:0]       b_out;         // B-reg の値

assign b_in = rs2;
assign b_ld = ctl_b_ld;

reg32 breg_inst(.clock(clock2),
                .reset(reset),
                .in(b_in),
                .ld(b_ld),
                .out(b_out),
                .dbg_mode(dbg_mode),
                .dbg_in(dbg_in),
                .dbg_ld(dbg_b_ld));
assign dbg_b_out = b_out;
//assign dbg_b_out = alu_in2;

// ALU
wire [31:0]       alu_in1;
wire [31:0]       alu_in2;
wire [31:0]       alu_out;      // ALU の出力

assign alu_in1 = (ctl_a_sel ? pc_out : a_out);
assign alu_in2 = (ctl_b_sel ? ctl_imm : b_out);

alu alu_inst(.in1(alu_in1),
             .in2(alu_in2),
             .ctl(ctl_alu_ctl),
             .out(alu_out));

// C-reg
wire [31:0]       c_in;
wire              c_ld;         // C-reg の書込みイネーブル信号
wire [31:0]       c_out;         // C-reg の値

assign c_in = alu_out;
assign c_ld = ctl_c_ld;

reg32 creg_inst(.clock(clock2),
                .reset(reset),
                .in(c_in),
                .ld(c_ld),
                .out(c_out),
                .dbg_mode(dbg_mode),
                .dbg_in(dbg_in),
                .dbg_ld(dbg_c_ld));
assign dbg_c_out = c_out;

// ST_CONV
wire [31:0]       stconv_in;
wire [31:0]       stconv_ir;
wire [31:0]       stconv_out;
assign stconv_in = b_out;
assign stconv_ir = ir_out;

stconv stconv_inst(.in(stconv_in),
                   .ir(stconv_ir),
                   .out(stconv_out));

// LD_CONV
wire [31:0]       ldconv_in;
wire [31:0]       ldconv_ir;
wire [1:0]        ldconv_offset;
wire [31:0]       ldconv_out;
assign ldconv_in     = mem_rddata;
assign ldconv_ir     = ir_out;
assign ldconv_offset = mem_addr[1:0];

ldconv ldconv_inst(.in(ldconv_in),
                   .ir(ldconv_ir),
                   .offset(ldconv_offset),
                   .out(ldconv_out));

// 制御信号
wire              ctl_pc_ld;
wire              ctl_mem_sel;
wire              ctl_mem_read;
wire              ctl_mem_write;
wire [ 3:0]       ctl_mem_wrbits;
wire              ctl_ir_ld;
wire [ 4:0]       ctl_rs1_addr;
wire [ 4:0]       ctl_rs2_addr;
wire [ 4:0]       ctl_rd_addr;
wire [ 1:0]       ctl_rd_sel;
wire              ctl_rd_ld;
wire              ctl_a_ld;
wire              ctl_b_ld;
wire              ctl_a_sel;
wire              ctl_b_sel;
wire [31:0]       ctl_imm;
wire [ 3:0]       ctl_alu_ctl;
wire              ctl_c_ld;
wire [31:0]       ctl_csr_out;
assign ctl_csr_out = 0;

controller controller_inst(.cstate(cstate),
                           .ir(ir_out),
                           .addr(mem_addr),
                           .alu_out(alu_out),
                           .pc_sel(pc_sel),
                           .pc_ld(ctl_pc_ld),
                           .mem_sel(ctl_mem_sel),
                           .mem_read(ctl_mem_read),
                           .mem_write(ctl_mem_write),
                           .mem_wrbits(ctl_mem_wrbits),
                           .ir_ld(ctl_ir_ld),
                           .rs1_addr(ctl_rs1_addr),
                           .rs2_addr(ctl_rs2_addr),
                           .rd_addr(ctl_rd_addr),
                           .rd_sel(ctl_rd_sel),
                           .rd_ld(ctl_rd_ld),
                           .a_ld(ctl_a_ld),
                           .b_ld(ctl_b_ld),
                           .a_sel(ctl_a_sel),
                           .b_sel(ctl_b_sel),
                           .imm(ctl_imm),
                           .alu_ctl(ctl_alu_ctl),
                           .c_ld(ctl_c_ld));
									
controller_debugger ctl_dbg_inst(pc_sel,
                                 ctl_pc_ld,
                                 ctl_mem_sel,
                                 ctl_mem_read,
                                 ctl_mem_write,
                                 ctl_mem_wrbits,
                                 ctl_ir_ld,
                                 ctl_rs1_addr,
                                 ctl_rs2_addr,
                                 ctl_rd_addr,
                                 ctl_rd_sel,
                                 ctl_rd_ld,
                                 ctl_a_ld,
                                 ctl_b_ld,
                                 ctl_a_sel,
                                 ctl_b_sel,
                                 ctl_alu_ctl,
                                 ctl_c_ld,
                                 dbg_seg7_dot64);

// running は実際には phasegen の出力を用いる．
phasegen phasegen_inst(.clock(clock2),
                       .reset(reset),
                       .run(run),
                       .step_phase(step_phase),
                       .step_inst(step_inst),
                       .cstate(cstate),
                       .running(running));

endmodule // kappa3_light_core
