module top(
	input i_start, //KEY[3], after debounce
	input i_stop,
	input i_up,
	input i_down, //KEY[0]
	// input SW02, // 0:normal, 1:change speed ?
	input ADCLRCK,
	input ADCDAT,
	input DACLRCK,
	input i_clk, //BCLK
	input i_rst, //SW00?
	input i_switch, // 0:record, 1:play

	inout I2C_SDAT,
	inout [15:0] SRAM_DQ,

	output I2C_SCLK,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	output SRAM_OE_N,
	output SRAM_WE_N,
	output SRAM_UB_N,
	output SRAM_LB_N,
	output DACDAT,
	output [4:0] timer
);

	enum { S_INIT, S_IDLE, S_PLAY, S_RECORD, S_PAUSE } state_r, state_w;
	enum { S_NORMAL, S_FAST, S_SLOW } speed_stat_r, speed_stat_w;

	logic startI_r, startI_w;
	logic startR_r, startR_w;
	logic startP_r, startP_w;
	logic doneI, doneP, doneR;
	logic[3:0] speed_r, speed_w;
	logic[19:0] pos_r, pos_w;
	logic[19:0] maxPos_r, maxPos_w;

	assign timer = pos_r[18:15];
	assign SRAM_CE_N = 0;
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;

	I2CSender i2(

	);

	Record adc(

	);

	Play dac(

	);

always_comb begin
	state_w = state_r;
	speed_stat_w = speed_stat_w;
	startI_w = startI_r;
	startR_w = startR_r;
	startP_w = startP_r;
	speed_w = speed_r;
	pos_w = pos_r;
	maxPos_w = maxPos_r;

	case(state_r)
		S_INIT: begin 
			startI_w = 1;
			//call I2CSender

			if(doneI) begin
				state_w = S_IDLE;
				startI_w = 0;
			end
		end

		S_IDLE: begin
			startI_w = 0;
			startR_w = 0;
			startP_w = 0;
			pos_w = 0;
			if(i_start) begin
				if(SW01) begin
					state_w = S_PLAY;
				end else begin
					state_w = S_RECORD;
				end
			end
		end

		S_RECORD: begin
			startR_w = 1;
			pos_w = SRAM_ADDR;
			maxPos_w = SRAM_ADDR;
			// call adc

			if(i_stop || doneR) begin
				state_w = S_IDLE;
				startR_w = 0;
			end
		end

		S_PLAY: begin
			startP_w = 1;
			pos_w = SRAM_ADDR;
			// call dac

			if(i_start) begin
				state_w = S_PAUSE;
				startP_w = 0;
			end else if(i_stop || doneP) begin
				state_w = S_IDLE;
				startP_w = 0;
			end
		end

		S_PAUSE: begin
			startP_w = 0;
			if(i_start) begin
				state_w = S_PLAY;
				startP_w = 1;
			end else if(i_stop) begin
				state_w = S_IDLE;
			end
		end
	endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		state_r <= S_INIT;
		speed_stat_r <= S_NORMAL;
		startI_r <= 0;
		startP_r <= 0;
		startR_r <= 0;
		speed_r <= 1;
		pos_r <= 0;
		maxPos_r <= 0;
	end else begin
		state_r <= state_w;
		speed_stat_r <= speed_stat_w;
		startI_r <= startI_w;
		startP_r <= startP_w;
		startR_r <= startP_r;
		speed_r <= speed_w;
		pos_r <= pos_w;
		maxPos_r <= maxPos_w;
	end
end

endmodule