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
	input i_switch, // 0:record, 1:play, SW01
	input i_intpol, // 0 or 1 order, SW02

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
	output [4:0] o_timer,
	output [2:0] o_state,
	output [1:0] o_speedStat,
	output [3:0] o_speed
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
	logic[4:0] speedtoDac;

	assign o_timer = pos_r[18:15]; //32k ~ 2^15
	assign o_state = state_r;
	assign o_speedStat = speed_stat_r;
	assign o_speed = speed_r;
	assign SRAM_CE_N = 0;
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;
	assign speedtoDac = {speed_stat_r[1],(speed_r-1)[2:0]};

	I2CManager i2cM(
		.i_input(startI_r),
		.i_clk(i_clk),
		.i_rst(i_rst),
		.o_finished(doneI),
		.o_sclk(I2C_SCLK),
		.o_sdat(I2C_SDAT)
	);

	Record adc(
		.i_record(startR_r),
		.i_ADCLRCK(ADCLRCK),
		.i_ADCDAT(ADCDAT),
		.i_BCLK(i_clk),
		.o_SRAM_WE(SRAM_WE_N),
		.o_SRAM_DATA(SRAM_DQ),
		.o_done(doneR),
		.o_sram_addr(SRAM_ADDR)
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
			//call I2CManager

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

			if(i_up) begin
				if(speed_stat_r == S_NORMAL) begin
					speed_stat_w = S_FAST;
					speed_w = 2;
				end else if(speed_r < 8) begin
					speed_w = speed_r + 1;
				end else if(S_SLOW && speed_r == 2) begin
					speed_stat_w = S_NORMAL;
					speed_w = 1;
				end
			end else if(i_down) begin
				if(speed_stat_r == S_NORMAL) begin
					speed_stat_w = S_SLOW;
					speed_w = 2;
				end else if(speed_r < 8) begin
					speed_w = speed_r + 1;
				end else if(S_FAST && speed_r == 2) begin
					speed_stat_w = S_NORMAL;
					speed_w = 1;
				end
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