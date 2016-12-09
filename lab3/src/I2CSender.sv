`timescale 1ns/100ps
module I2cSender #(parameter BYTE=1) (
	input i_start,
	input [BYTE*8-1:0] i_dat,
	input i_clk,
	input i_rst,
	output o_finished,
	output o_sclk,
	inout o_sdat
);

	typedef enum { 
		S_INITIAL,
		S_TRANSIT,
		S_DATAPAS, 
		S_FINAL
	} MainState;

	MainState state_r, state_w;

	always_comb begin
		state_w = state_r;


	end

	always_ff @(posedge i_clk, i_rst) begin
	    if(!i_rst) begin
	        state_r <= S_INITIAL;
	    end
	    else begin
	        state_r <= state_w;
	    end
	end


endmodule
