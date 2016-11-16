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
	output reg [255:0] o_a_pow_e,
	output reg [255:0] o_modcall1,
	output reg [255:0] o_modcall2,
	output reg o_finished,
	output reg o_start_trans,
	output reg o_start_mul
);
	logic[2:0] state_r, state_w;
	logic[255:0] result_r, result_w;
	logic[255:0] mont_const_r, mont_const_w;
	logic[8:0] count_r, count_w;
	localparam S_IDLE = 0, S_PRECALC = 1, S_CALC = 2, S_WAIT_PRECALC = 3, 
		S_WAIT_CALC1 = 4, S_WAIT_CALC2 = 5; 

	always_comb begin
		o_a_pow_e = result_r;
		o_modcall1 = result_r;
		o_modcall2 = mont_const_r;
		o_finished = 0;
		o_start_trans = 0;
		o_start_mul = 0;

		state_w = state_r;
		case(state_r)
			S_IDLE: begin
				result_w = 1;
				count_w = 0;
				o_finished = 0;
				o_start_trans = 0;
				o_start_mul = 0;
				if(i_start) begin
					state_w = S_PRECALC;
				end
			end
			S_PRECALC: begin
				o_start_trans = 1;
				o_modcall1 = i_a;
				state_w = S_WAIT_PRECALC;
			end
			S_WAIT_PRECALC: begin
				o_start_trans = 0;
				if(i_trans_done) begin
					mont_const_w = i_transreturn;
					state_w = S_CALC;
				end
			end
			S_CALC: begin
				if(count_r == 256) begin
					o_finished = 1;
					o_a_pow_e = result_r;
					state_w = S_IDLE;
				end else begin
					if(i_e[count_r] == 1) begin
						o_start_mul = 1;
						o_modcall1 = result_r;
						o_modcall2 = mont_const_r;
						state_w = S_WAIT_CALC1;
					end else begin
						o_start_mul = 1;
						o_modcall1 = mont_const_r;
						o_modcall2 = mont_const_r;
						state_w = S_WAIT_CALC2;
					end
				end
			end
			S_WAIT_CALC1: begin
				if(i_mul_done) begin
					result_w = i_mulreturn;
					o_start_mul = 1;
					o_modcall1 = mont_const_r;
					o_modcall2 = mont_const_r;
					state_w = S_WAIT_CALC2;
				end else begin
					o_start_mul = 0;
				end
			end
			S_WAIT_CALC2: begin
				o_start_mul = 0;
				if(i_mul_done) begin
					mont_const_w = i_mulreturn;
					state_w = S_CALC;
				end
				count_w = count_r + 1;
			end
			default: begin
			end
		endcase
	end

	always_ff @(posedge i_clk posedge i_rst) begin
		result_r <= result_w;
		mont_const_r <= mont_const_w;
		count_r <= count_w;
		if(i_rst) begin
			state_r <= S_IDLE;
		end else begin
			state_r <= state_w;
		end
	end
endmodule
