module montTrans(
	input i_clk,
	input i_rst,
	input i_start,
	input[255:0] i_a,
	input[256:0] i_n,
	output[255:0] o_a_mont,
	output o_finished
);

	logic[256:0] result_r, result_w;
	logic[8:0] count_r, count_w;
	logic state_r, state_w;
	logic[256:0] temp1, temp2;
	logic[256:0] mont_const;
	logic[256:0] a_r, a_w, n_r, n_w;

	localparam S_IDLE = 0, S_RUN = 1;
	// localparam mont_const = 2**256;
	assign o_a_mont = result_r;
	assign o_finished = (count_r == 256);
	// assign mont_const = 2*256;
	assign temp1 = (result_r << 1 > i_n)?((result_r << 1) - i_n):(result_r << 1);
	assign temp2 = temp1 + mont_const - i_n;

	always_comb begin
		// $display("res %64x %0t", result_r, $time);
		// o_a_mont = result_r;
		// o_finished = 0;
		mont_const = 0;
		mont_const[256] = 1;
		state_w = state_r;
		result_w = result_r;
		count_w = count_r;
		a_w = a_r;
		n_w = n_r;
		if(state_r == S_IDLE) begin
			count_w = 0;
			// o_finished = 1;
			if(i_start) begin
				// o_finished = 0;
				result_w = 0;
				a_w = i_a;
				n_w = i_n;
				state_w = S_RUN;
				// $display("i_n %64x", i_n);
			end
		end else begin // S_RUN
			if(count_r == 256) begin // terminate
				// o_finished = 1;
				// o_a_mont = result_r;
				state_w = S_IDLE;
			end else begin 
				// if(result_r << 1 > i_n) begin // a*2 mod n
				// 	temp1 = result_r << 1 - i_n;
				// end else begin
				// 	temp1 = result_r << 1;
				// end
				// $display("tp1 %64x %0t", temp1, $time);
				// $display("nr2 %64x %0t", n_r, $time);
				if(a_r[255-count_r]) begin // a*2 + a_(255-i)*2^256 mod n
					// temp2 = temp1 + mont_const - i_n;
					// $display("tp2 %64x %0t", temp2, $time);
					if(temp2 > i_n) begin
						result_w = temp2 - i_n;
					end else begin
						result_w = temp2;
					end
				end else begin
					result_w = temp1;
				end
				count_w = count_r + 1;
				// o_finished = 0;
			end
		end
	end

	always_ff @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
			state_r <= S_IDLE;
			result_r <= 0;
			count_r <= 0;
			a_r <= a_w;
			n_r <= n_w;
		end else begin
			result_r <= result_w;
			state_r <= state_w;
			count_r <= count_w;
			a_r <= a_w;
			n_r <= n_w;
		end
	end

endmodule
