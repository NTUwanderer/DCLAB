module Player(
	// parameters
	input i_play,
	input [19:0] i_start_pos,
	input [19:0] i_end_pos,
	input [3:0] i_speed,
	// Chip wires
	input i_DACLRCK,
	input i_BCLK,
	input [15:0] i_SRAM_DATA,

	output o_SRAM_OE,
	output [19:0] o_SRAM_ADDR,
	output o_DACDAT,
	output o_done
);
	typedef enum {
		S_IDLE,
		S_READ,
		S_WAIT,
		S_WRITE_LEFT,
		S_WRITE_RIGHT,
		S_DONE
	} State;

	State state_r, state_w;
	logic [19:0] position_r, position_w;
	logic [31:0] next_data_r, next_data_w;
	logic [31:0] curr_data_r, curr_data_w;
	logic [3:0] bitnum_r, bitnum_w;
	logic done_r, done_w;
	logic pre_LRCLK_r, pre_LRCLK_w;
	logic dacdat_r, dacdat_w;
	logic pre_fetched_r, pre_fetched_w;
	logic is_inter_r, is_inter_w;

	assign o_SRAM_OE = ~(state_r == S_READ);
	assign o_SRAM_ADDR = position_r;
	assign o_DACDAT = dacdat_r;
	assign o_done = done_r;

	always_ff @( posedge i_BCLK ) begin 
		pre_LRCLK_r <= pre_LRCLK_w;
		position_r <= position_w;
		state_r <= state_w;
		next_data_r <= next_data_w;
		curr_data_r <= curr_data_w;
		bitnum_r <= bitnum_w;
		done_r <= done_w;
		dacdat_r <= dacdat_w;
		pre_fetched_r <= pre_LRCLK_w;
		is_inter_r <= is_inter_w;
	end
	
	always_comb begin
		pre_LRCLK_w = i_DACLRCK;
		position_w = position_r;
		state_w = state_r;
		next_data_w = next_data_r;
		curr_data_w = curr_data_r;
		bitnum_w = bitnum_r;
		done_w = done_r;
		dacdat_w = dacdat_r;
		pre_fetched_w = pre_fetched_r;
		is_inter_w = is_inter_r;

		case (state_r)
			S_IDLE: begin 
				pre_fetched_w = 0;
				is_inter_w = 0;
				position_w = i_start_pos;
				done_w = 0;
				bitnum_w = 0;
				if(i_play) begin
					state_w = S_READ;
				end
			end

			S_READ: begin 
				pre_fetched_w = 1;
				is_inter_w = 0;
				curr_data_w = next_data_r;
				next_data_w[15:0] = i_SRAM_DATA;
				next_data_w[31:16] = i_SRAM_DATA;
				if(pre_fetched_r) 	state_w = S_WAIT;			
				else 				state_w = S_READ; // Read again
				position_w = position_r + 1;
				if((position_r - 1 == i_end_pos) && pre_fetched_r) begin
					done_w = 1;
					state_w = S_DONE;
					position_w = position_r;
				end
			end

			S_WAIT: begin
				bitnum_w = 0;
				if(pre_LRCLK_r == 1 && i_DACLRCK == 0)		state_w = S_WRITE_LEFT;
				else if(pre_LRCLK_r == 0 && i_DACLRCK == 1)	state_w = S_WRITE_RIGHT;
			end

			S_WRITE_LEFT: begin 
				if(i_play == 0) begin 
					state_w = S_IDLE;
				end else begin
					dacdat_w = curr_data_r[bitnum_r];
					bitnum_w = bitnum_r + 1;
					if(bitnum_r == 15) state_w = S_WAIT;
				end
			end

			S_WRITE_RIGHT: begin 
				if(i_play == 0) begin 
					state_w = S_IDLE;
				end else begin
					dacdat_w = curr_data_r[16 + bitnum_r];
					bitnum_w = bitnum_r + 1;
					if(bitnum_r == 15) state_w = S_READ;
				end
			end
		
			S_DONE: begin 
				state_w = S_IDLE;
			end
		endcase
	end

endmodule
