module Rsa256Core(
	input i_clk,
	input i_rst,
	input i_start,
	input i_trans_done,
	input i_mul_done,
	input [255:0] i_a,
	input [255:0] i_e,
	input [255:0] i_n,
	input [255:0] i_transreturn,
	input [255:0] i_mulreturn,
	output [255:0] o_a_pow_e,
	output reg [255:0] o_modcall1,
	output reg [255:0] o_modcall2,
	output reg o_finished,
	output reg o_start_trans,
	output reg o_start_mul,
	output [256:0] o_n
);
	logic[2:0] state_r, state_w;
	logic[255:0] result_r, result_w;
	logic[255:0] mont_const_r, mont_const_w;
	logic[8:0] count_r, count_w;
	logic[256:0] a_r, a_w, e_r, e_w, n_r, n_w;
	logic op_r, op_w;
	localparam S_IDLE = 0, S_PRECALC = 1, S_CALC = 2, S_WAIT_PRECALC = 3, 
		S_WAIT_CALC1 = 4, S_CALC2 = 5, S_WAIT_CALC2 = 6; 

	assign o_a_pow_e = result_r;
	assign o_finished = (state_r == S_IDLE);
	assign o_n = n_r;
	assign o_start_mul = op_r|(state_r==S_WAIT_CALC2)|(state_r==S_CALC);
	always_comb begin
		// $display("a %64x\ne %64x\nn %64x",a_r, e_r, n_r);
		//$display("imuldone %d",i_mul_done);
		// $display("state %d time %0t",state_r, $time);

		// o_a_pow_e = result_r;
		o_modcall1 = a_r;
		o_modcall2 = mont_const_r;
		// o_finished = 0;
		o_start_trans = 0;
		// o_start_mul = 0;
		// $display("state_w0 %d time %0t %d", state_w, $time, i_mul_done);
		result_w = result_r;
		mont_const_w = mont_const_r;
		count_w = count_r;
		state_w = state_r;
		a_w = a_r;
		e_w = e_r;
		n_w = n_r;
		op_w = op_r;
		// $display("state_w1 %d time %0t %d", state_w, $time, i_mul_done);
		// if(o_finished) begin
		// 	$display("res %64x", result_r);
		// end
		case(state_r)
			S_IDLE: begin
				result_w = 1;
				count_w = 0;
				// o_finished = 0;
				o_start_trans = 0;
				// o_start_mul = 0;
				if(i_start) begin
					a_w = i_a;
					e_w = i_e;
					n_w = i_n;
					state_w = S_PRECALC;
					o_modcall1 = a_r;
				end
			end
			S_PRECALC: begin
				o_start_trans = 1;
				o_modcall1 = a_r;
				// $display("a_r %64x",a_r);
				// $display("n_r %64x",n_r);
				state_w = S_WAIT_PRECALC;
			end
			S_WAIT_PRECALC: begin
				o_start_trans = 0;
				if(i_trans_done) begin
					mont_const_w = i_transreturn;
					// $display("transret %64x",i_transreturn);
					state_w = S_CALC;
				end
			end
			S_CALC: begin
				//$display("calc %d", count_r);
				if(count_r == 256) begin
					// o_finished = 1;
					// o_a_pow_e = result_r;
					state_w = S_IDLE;
				end else begin
					op_w = 1;
					if(e_r[count_r] == 1) begin
						// o_start_mul = 1;
						// $display("send0 %64x\n%64x %0t",result_r, mont_const_r, $time);
						o_modcall1 = result_r;
						o_modcall2 = mont_const_r;
						state_w = S_WAIT_CALC1;
					end else begin
						// o_start_mul = 1;
						// $display("send1 %64x %0t",mont_const_r, $time);
						o_modcall1 = mont_const_r;
						o_modcall2 = mont_const_r;
						state_w = S_WAIT_CALC2;
					end
				end
			end
			S_WAIT_CALC1: begin
				//$display("calc1 %d\n", count_r);
				
				op_w = 0;
				if(i_mul_done) begin
					result_w = i_mulreturn;
					// o_start_mul = 1;
					state_w = S_CALC2;
				end else begin
					// o_start_mul = 0;
				end
			end
			S_CALC2: begin
				// $display("res %64x c %d",result_r, count_r);
				op_w = 1;
				// $display("send2 %64x %0t",mont_const_r, $time);
				o_modcall1 = mont_const_r;
				o_modcall2 = mont_const_r;
				state_w = S_WAIT_CALC2;
			end
			S_WAIT_CALC2: begin
				//$display("calc2 %d", count_r);
				op_w = 0;
				o_modcall1 = mont_const_r;
				o_modcall2 = mont_const_r;
				// o_start_mul = 0;
				if(i_mul_done) begin
					// $display("muldone");
					mont_const_w = i_mulreturn;
					// $display("mulres %64x %0t", i_mulreturn, $time);
					count_w = count_r + 1;
					state_w = S_CALC;
					// $display("state_w %d time %0t %d", state_w, $time, i_mul_done);
				end
			end

			default: begin
				// $display("error");
			end
		endcase
		// if(result_r != result_w) begin
		// 	$display("result_r %64x", result_r);
		// end
		// $display("state_w2 %d time %0t %d", state_w, $time, i_mul_done);
	end

	always_ff @(posedge i_clk or negedge i_rst) begin
		// if(state_w == S_CALC) begin
		// 	$display("123");
		// end
		// if($time < 6000) begin
		// 	$display("state_w_ff %d time %0t", state_w, $time);
		// end
		if(i_rst) begin
			result_r <= result_w;
			mont_const_r <= mont_const_w;
			count_r <= count_w;
			state_r <= S_IDLE;
		end else begin
			result_r <= result_w;
			mont_const_r <= mont_const_w;
			count_r <= count_w;
			state_r <= state_w;
			a_r <= a_w;
			e_r <= e_w;
			n_r <= n_w;
			op_r <= op_w;
		end
		//$display("stateff %d",state_r);
	end
endmodule
