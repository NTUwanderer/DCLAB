module montMul(
	input i_clk,
	input i_rst,
	input i_start,
	input[255:0] i_a,
	input[255:0] i_b,
	input[256:0] i_n,
	output[255:0] o_abmodn,
	output o_finished
);

	logic[257:0] result_r, result_w;
	logic[8:0] count_r, count_w;
	logic state_r, state_w;
	logic[257:0] temp1, temp2;
	logic[257:0] a_r, a_w, b_r, b_w;
	logic of_r, of_w;

	localparam S_IDLE = 0, S_RUN = 1;

	assign o_abmodn = result_r;
	assign o_finished = of_r;
	assign temp1 = (a_r[count_r] == 1)?(result_r + b_r):result_r;

	always_comb begin
		// if(o_finished) begin 
		// 	$display("f %0t",$time);
		// end
		// o_abmodn = result_r;
		//o_finished = 0;
		// if($time < 10000) begin
		// 	$display("res %64x %0t",result_r,$time);
		// end
		state_w = state_r;
		result_w = result_r;
		count_w = count_r;
		a_w = a_r;
		b_w = b_r;
		of_w = of_r;
		if(state_r == S_IDLE) begin
			count_w = 0;
			of_w = 0;
			// o_finished = 1;
			if(i_start) begin
				result_w = 0;
				state_w = S_RUN;
				a_w = i_a;
				b_w = i_b;
				// $display("state %d start %d", state_r, i_start);
				// $display("get  %64x\n%64x %0t",i_a,i_b,$time);
				// o_finished = 0;
			end
		end else begin // S_RUN
			//$display("mul %d ", count_r);
			if(count_r == 256) begin // terminate
				if(result_r >= i_n) begin
					result_w = result_r - i_n;
				end 
				of_w = 1;
				count_w = count_r + 1;
			end else if(count_r == 257) begin
				of_w = 0;
				state_w = S_IDLE;
			end else begin
				// if(a_r[count_r] == 1) begin
				// 	temp1 = result_r + b_r;
				// end
				// if($time < 10000) begin
				// 	$display("tp1 %64x %0t",temp1,$time);
				// end
				if(temp1[0] == 1) begin //odd
					result_w = (temp1 + i_n) >> 1;
				end else begin
					result_w = temp1 >> 1;
				end

				// o_finished = 0;
				count_w = count_r + 1;
			end
		end
		// if(state_r == S_IDLE) begin
		// 	$display("state_w %d",state_w);
		// end
	end

	always_ff @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
			state_r <= S_IDLE;
			result_r <= 0;
			count_r <= count_w;
		end else begin
			result_r <= result_w;
			state_r <= state_w;
			count_r <= count_w;
			a_r <= a_w;
			b_r <= b_w;
			of_r <= of_w;
		end
	end

endmodule
