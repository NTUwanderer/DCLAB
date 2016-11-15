module montTrans(
	input i_clk,
	input i_rst,
	input i_start,
	input[255:0] i_a,
	input[255:0] i_n,
	output reg [255:0] o_a_mont,
	output reg o_finished
);

	logic[256:0] result_r, result_w;
	logic[8:0] count_r, count_w;
	logic state_r, state_w;
	logic[256:0] temp1, temp2;

	localparam S_IDLE = 0, S_RUN = 1;
	localparam mont_const = 2**256;

	always_comb begin
		o_a_mont = result_r;
		o_finished = 0;

		state_w = state_r;
		result_w = result_r;
		if(state_r == S_IDLE) begin
			count_w = 0;
			result_w = 0;
			o_finished = 0;
			if(i_start) begin
				state_w = S_RUN;
			end
		end else begin // S_RUN
			if(count_r == 256) begin // terminate
				o_finished = 1;
				o_a_mont = result_r;
				state_w = S_IDLE;
			end else begin 
				if(result_r << 1 > i_n) begin
					temp1 = result_r - i_n;
				end else begin
					temp1 = result_r;
				end
				if(i_a[255-count_r]) begin
					temp2 = temp1 + (mont_const - i_n);
					if(temp2 > i_n) begin
						result_w = temp2 - i_n;
					end else begin
						result_w = temp2;
					end
				end
				count_w = count_r + 1;
			end
		end
	end

	always_ff @(posedge i_clk or negedge i_rst) begin
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
