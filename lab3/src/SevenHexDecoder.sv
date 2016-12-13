module SevenHexDecoder(
	input [4:0] timer,
	input [2:0] state,
	input [1:0] speedStat,
	input [3:0] speed,
	output logic [6:0] o_s0,
	output logic [6:0] o_s1,
	output logic [6:0] o_s2,
	output logic [6:0] o_s3,
	output logic [6:0] o_s4,
	output logic [6:0] o_s5,
	output logic [6:0] o_s6,
	output logic [6:0] o_s7
);
	/* The layout of seven segment display, 1: dark
	 *    00
	 *   5  1
	 *    66
	 *   4  2
	 *    33
	 */
	parameter D0 = 7'b1000000;
	parameter D1 = 7'b1111001;
	parameter D2 = 7'b0100100;
	parameter D3 = 7'b0110000;
	parameter D4 = 7'b0011001;
	parameter D5 = 7'b0010010;
	parameter D6 = 7'b0000010;
	parameter D7 = 7'b1011000;
	parameter D8 = 7'b0000000;
	parameter D9 = 7'b0010000;
	parameter A  = 7'b0001000;
	parameter C  = 7'b1000110;
	parameter E  = 7'b0000110;
	parameter L  = 7'b1000111;
	parameter P  = 7'b0001100;
	parameter R  = 7'b1001110;
	parameter S  = 7'b0010010;
	parameter U  = 7'b1000001;
	parameter Y  = 7'b0011001;
	parameter NE = 7'b0111111;
	parameter DK = 7'b1111111;

	always_comb begin
		o_s0 = DK;
		o_s1 = DK;
		o_s2 = DK;
		o_s3 = DK;
		o_s4 = DK;
		o_s5 = DK;
		o_s6 = DK;
		o_s7 = DK;

		case(timer)
			0 : begin o_s1 = D0; o_s0 = D0; end
			1 : begin o_s1 = D0; o_s0 = D1; end
			2 : begin o_s1 = D0; o_s0 = D2; end
			3 : begin o_s1 = D0; o_s0 = D3; end
			4 : begin o_s1 = D0; o_s0 = D4; end
			5 : begin o_s1 = D0; o_s0 = D5; end
			6 : begin o_s1 = D0; o_s0 = D6; end
			7 : begin o_s1 = D0; o_s0 = D7; end
			8 : begin o_s1 = D0; o_s0 = D8; end
			9 : begin o_s1 = D0; o_s0 = D9; end
			10: begin o_s1 = D1; o_s0 = D0; end
			11: begin o_s1 = D1; o_s0 = D1; end
			12: begin o_s1 = D1; o_s0 = D2; end
			13: begin o_s1 = D1; o_s0 = D3; end
			14: begin o_s1 = D1; o_s0 = D4; end
			15: begin o_s1 = D1; o_s0 = D5; end
			16: begin o_s1 = D1; o_s0 = D6; end
			17: begin o_s1 = D1; o_s0 = D7; end
			18: begin o_s1 = D1; o_s0 = D8; end
			19: begin o_s1 = D1; o_s0 = D9; end
			20: begin o_s1 = D2; o_s0 = D0; end
			21: begin o_s1 = D2; o_s0 = D1; end
			22: begin o_s1 = D2; o_s0 = D2; end
			23: begin o_s1 = D2; o_s0 = D3; end
			24: begin o_s1 = D2; o_s0 = D4; end
			25: begin o_s1 = D2; o_s0 = D5; end
			26: begin o_s1 = D2; o_s0 = D6; end
			27: begin o_s1 = D2; o_s0 = D7; end
			28: begin o_s1 = D2; o_s0 = D8; end
			29: begin o_s1 = D2; o_s0 = D9; end
			30: begin o_s1 = D3; o_s0 = D0; end
			31: begin o_s1 = D3; o_s0 = D1; end
		endcase

		case(state)
			1: begin // IDLE
				o_s7 = D1;
				o_s6 = D0;
				o_s5 = L;
				o_s4 = E;
				o_s1 = DK;
				o_s0 = DK;
			end
			2: begin // PLAY
				o_s7 = P;
				if(speedStat == 0) begin
					o_s6 = L;
					o_s5 = A;
					o_s4 = Y;
				end else begin
					case(speed)
						2: begin o_s3 = D2; end
						3: begin o_s3 = D3; end
						4: begin o_s3 = D4; end
						5: begin o_s3 = D5; end
						6: begin o_s3 = D6; end
						7: begin o_s3 = D7; end
						8: begin o_s3 = D8; end
						default: begin end
					endcase
					o_s5 = S;
					if(speedStat == 2) begin o_s4 = NE; end
				end
			end
			3: begin // RECORD
				o_s7 = R;
				o_s6 = E;
				o_s5 = C;
			end
			4: begin // PAUSE
				o_s7 = P;
				o_s6 = A;
				o_s5 = U;
				o_s4 = S;
				o_s3 = E;
				o_s1 = DK;
				o_s0 = DK;
			end
			default: begin end
		endcase
	end
endmodule
