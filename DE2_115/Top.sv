module Top(
	input i_clk,
	input i_start,
	output [3:0] o_random_out
);
	logic [4:0] globalcounter_r;
	logic [4:0] globalcounter_w;
	logic [4:0] current_output_r, current_output_w;
	logic [31:0] counter_r;
	logic [31:0] counter_w;
	logic state_r;
	logic state_w;
	localparam S_IDLE = 0, S_RUN = 1;
	//todo: initialize state(reset?)
	initial begin
		globalcounter_r = 0;
		globalcounter_w = 0;
		current_output_r = 0;
		current_output_w = 0;
		counter_r = 0;
		counter_w = 0;
		state_r = S_IDLE;
		state_w = S_IDLE;
		o_random_out = 0;
	end

	always_comb begin
		state_w = state_r;
		if(state_r == S_IDLE) begin
			current_output_w = current_output_r;
			counter_w = 0;
		end else begin
			counter_w = counter_r + 1;
			case(counter_r)
				5000000,
				10000000,
				15000000,
				20000000,
				25000000,
				30000000,
				35000000,
				40000000,
				45000000,
				50000000,
				60000000,
				70000000,
				80000000,
				100000000,
				120000000,
				150000000: current_output_w = current_output_r + globalcounter_r;
				200000000: begin
					current_output_w = current_outuput_r + globalcounter_r;
					state_w = S_IDLE;
				end
				default: current_output_w = current_output_r; // do nothing
			endcase
		end
		if(i_start) begin
			state_w = S_RUN;
			counter_w = 0;
		end
		o_random_out = current_output_w;
		if(globalcounter_r == 30) begin
			globalcounter_w = globalcounter_r + 2;
		end else begin
			globalcounter_w = globalcounter_r + 1;
		end
	end

	always_ff @(posedge i_clk) begin
		globalcounter_r <= globalcounter_w;
		counter_r <= counter_w;
		state_r <= state_w;
		current_output_r <= current_output_w;
	end
endmodule
