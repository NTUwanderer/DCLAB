module(
	input i_clk,
	input i_rst,
	input i_start,
	input[15:0] i_SRAM_DATA,
	output o_SRAM_OE,
	output o_SRAM_WE,
	output[19:0] o_SRAM_ADDR,
	output[15:0] o_SRAM_DATA
);
	logic[31:0] counter_r, counter_w;
	logic[19:0] addr_r, addr_w;
	enum {S_IDLE, S_RUN} state_r, state_w;

	assign o_SRAM_DATA = i_SRAM_DATA;
	assign o_SRAM_ADDR = addr_r;
	assign o_SRAM_WE = (state_r == S_RUN);
	assign o_SRAM_OE = (state_r != S_RUN);

always_comb begin
	counter_w = counter_r + 1;
	addr_w = addr_r;
	state_w = state_r;

	case(state_r)
		S_IDLE: begin
			if(i_start) begin
				state_w = S_RUN;
			end
		end
		S_RUN: begin
			if(counter_r[22:0] == 0) begin
				addr_w = addr_r + 1;
			end
			if(!i_start) begin
				state_w = S_IDLE;
			end
		end
	endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		counter_r <= 0;
		addr_r <= 0;
		state_r <= S_IDLE;
	end else begin
		counter_r <= counter_w;
		addr_r <= addr_w;
		state_r <= state_w;
	end
end

endmodule