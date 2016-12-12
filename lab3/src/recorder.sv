module Recorder(
	input i_record,
	input i_ADCLRCK,
	input i_ADCDAT,
	input i_BCLK,
	output o_SRAM_WE,
	output [15:0] o_SRAM_DATA,
	output o_done,
	output o_position
);
	enum { S_IDLE, S_WRITE, S_DONE } state_r, state_w;
	// logic state_r, state_w;
	logic pre_RCK_r, pre_RCK_w;
	logic done_r, done_w;
	logic [3:0] bitnum_r, bitnum_w;
	logic [15:0] data_r, data_w;
	logic [19:0] position_r, position_w

	assign o_SRAM_WE = ~state_r;
	assign o_SRAM_DATA = data_r;
	assign o_done = done_r;
	assign o_position = position_r;

	// Assignments
	always_ff @( posedge i_BCLK ) begin
		state_r <= state_w;
		max_position_r <= max_position_w;
		data_r <= data_w;
		bitnum_r <= bitnum_w;
		done_r <= done_w;
		pre_RCK_r <= pre_RCK_w;
	end

	always_comb begin
		pre_RCK_w = i_ADCLRCK;
		data_w = data_r;
		case (state_r)
			S_IDLE: begin
				position_w = 0;
				bitnum_w = 0;
				done_w = 0;
				if (i_record && (pre_RCK_r == 1 && i_ADCLRCK == 0)) begin
					state_w = S_WRITE;
				end
			end

			S_WRITE: begin
				data_w[bitnum_r] = i_ADCDAT;
				bitnum_w = bitnum_r + 1;
				if(i_record == 0 || bitnum_r == 15) begin
					state_w = S_IDLE;
					if(position_r == 1048575) begin
						state_w = S_DONE;
						done_w = 1;
					end
				end
			end

			S_DONE: begin 
				state_w = S_IDLE;
			end
		endcase

	end

endmodule
