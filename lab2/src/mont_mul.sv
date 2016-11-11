module montMul(
	input i_clk,
	input i_rst,
	input i_start,
	input[255:0] i_a,
	input[255:0] i_b,
	input[255:0] i_n,
	output[255:0] o_abmodn,
	output o_finished
);

	logic[256:0] result_r, result_w;
	logic[8:0] count_r, count_w;
	logic state_r, state_w;
	lgoic[256:0] temp1, temp2;

	localparam S_IDLE = 0, S_RUN = 1;

	always_comb
		o_abmodn = result_r;
		o_finished = 0;

		state_w = state_r;
		result_w = result_r;
		if(state_r = S_IDLE) begin
			count_w = 0;
			result_w = 0;
			o_finished = 0;
			if(i_start) begin
				state_w = S_RUN;
			end
		end else begin // S_RUN
			if(count_r == 256) begin // terminate
				o_finished = 1;
				o_abmodn = result_r;
				state_w = S_IDLE;
			end else begin
				if(i_a[i] == 1) begin
					temp1 = result_r + i_b;
				end
				if(temp1[0] == 1) begin //odd
					temp2 = (temp1 + i_n) >> 1;
				end else begin
					temp2 = temp1 >> 1;
				end
				if(temp2 >= i_n >> 1) begin
					result_w = temp2 - i_n;
				end else begin
					result_w = temp2;
				end
			end
			count_w = count_r + 1;
		end

	end

	always_ff @(posedge i_clk or negedge i_rst)
		if(i_rst) begin
			state_r <= S_IDLE;
			result_r <= 0;
		end else begin
			result_r <= result_w;
			state_r <= state_w;
			count_r <= count_w;
		end
	end

endmodule