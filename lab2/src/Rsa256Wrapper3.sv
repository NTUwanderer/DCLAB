module Rsa256Wrapper(
	input avm_rst,
	input avm_clk,
	output [4:0] avm_address,
	output avm_read,
	input [31:0] avm_readdata,
	output avm_write,
	output [31:0] avm_writedata,
	input avm_waitrequest
);
	localparam RX_BASE     = 0*4;
	localparam TX_BASE     = 1*4;
	localparam STATUS_BASE = 2*4;
	localparam TX_OK_BIT = 6;
	localparam RX_OK_BIT = 7;

	localparam S_GET_KEY = 0;
	localparam S_GET_DATA = 1;
	localparam S_WAIT_CALCULATE = 2;
	localparam S_SEND_DATA = 3;

	typedef enum { 
		S_BEGIN, 
		S_READ_N,
		S_READ_D, 
		S_READ_A, 
		S_CALC_BEGIN,
		S_CALC_WAIT, 
		S_WRITE_ANS
	} MainState;
	
	typedef enum {
		S_IDLE,
		S_CHECK_RX,
		S_TO_RECEIVE,
		S_RECEIVING,
		S_CHECK_TX,
		S_TO_SEND,
		S_SENDING
	} IOState;
	
	logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
	logic [4:0] avm_address_r, avm_address_w;
	logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

	logic rsa_start_r, rsa_start_w;
	logic rsa_finished;
	logic [255:0] rsa_dec;

	logic [3:0] counter_r, counter_w;
	logic [15:0] num_w, num_r;

	logic[255:0] modcall1, modcall2, transret, mulret, n2; 
	logic strans, smul, ftrans, fmul;


	// assign o_num = num_r;
	assign avm_address = avm_address_r;
	assign avm_read = avm_read_r;
	assign avm_write = avm_write_r;

	Rsa256Core core0(
		.i_clk(avm_clk),
		.i_rst(avm_rst),
		.i_start(rsa_start_r),
		.i_trans_done(ftrans),
		.i_mul_done(fmul),
		.i_a(enc_r),
		.i_e(d_r),
		.i_n(n_r),
		.i_transreturn(transret),
		.i_mulreturn(mulret),
		.o_a_pow_e(rsa_dec),
		.o_modcall1(modcall1),
		.o_modcall2(modcall2),
		.o_finished(rsa_finished),
		.o_start_trans(strans),
		.o_start_mul(smul),
		.o_n(n2)
	);

	montTrans trans0(
		.i_clk(avm_clk),
		.i_rst(avm_rst),
		.i_start(strans),
		.i_a(modcall1),
		.i_n(n2),
		.o_a_mont(transret),
		.o_finished(ftrans)
	);

	montMul mul0(
		.i_clk(avm_clk),
		.i_rst(avm_rst),
		.i_start(smul),
		.i_a(modcall1),
		.i_b(modcall2),
		.i_n(n2),
		.o_abmodn(mulret),
		.o_finished(fmul)
	);

	task StartRead;
		input [4:0] addr;
		begin
			avm_read_w = 1;
			avm_write_w = 0;
			avm_address_w = addr;
		end
	endtask

	task StartWrite;
		input [4:0] addr;
		begin
			avm_read_w = 0;
			avm_write_w = 1;
			avm_address_w = addr;
		end
	endtask

	task DoNothing;
		begin
			avm_read_w = 0;
			avm_write_w = 0;
			avm_address_w = 0;
		end
	endtask


	IOState io_state_r, io_state_w;
	logic [255:0] read_buffer_r, read_buffer_w;
	logic [255:0] write_buffer_r, write_buffer_w;
	byte bytes_counter_r, bytes_counter_w;

	logic write_flag_r, write_flag_w;
	logic read_flag_r, read_flag_w;
	byte real_buffer_r, real_buffer_w;
	// assign avm_writedata = real_buffer_r;
	assign avm_writedata = write_buffer_r[255-:8];
	
	MainState main_state_r, main_state_w;


	always_comb begin
		// dec_w[247-:8] = dec_r[247-:8];
		enc_w = enc_r;
		dec_w = dec_r;
		n_w = n_r;
		d_w = d_r;

		avm_read_w = avm_read_r;
		avm_write_w = avm_write_r;
		avm_address_w = avm_address_r;
		io_state_w = io_state_r;
		counter_w = counter_r;
		bytes_counter_w = bytes_counter_r;
		num_w = num_r;
		num_w[3:0] = main_state_r;
		num_w[7:4] = io_state_r;
		read_buffer_w = read_buffer_r;
		write_buffer_w = write_buffer_r;
		read_flag_w = read_flag_r;
		write_flag_w = write_flag_r;

		case (io_state_r)
			S_IDLE: begin
				io_state_w = write_flag_r ? S_CHECK_TX : (read_flag_r ? S_CHECK_RX : S_IDLE);
				bytes_counter_w = 0;
				DoNothing();
			end 
			S_CHECK_RX: begin
				StartRead(STATUS_BASE);
				io_state_w = S_TO_RECEIVE;
			end
			S_TO_RECEIVE: begin
				if (!avm_waitrequest) begin
					DoNothing();
					if (avm_readdata[RX_OK_BIT]) begin
						StartRead(RX_BASE);
						io_state_w = S_RECEIVING;
					end else begin
						io_state_w = S_CHECK_RX;
					end
				end
			end
			S_RECEIVING: begin
				if (!avm_waitrequest) begin
					DoNothing();
					read_buffer_w = (read_buffer_r << 8) + avm_readdata[7:0];
					bytes_counter_w = bytes_counter_r + 1;
					io_state_w = bytes_counter_r == 31 ? S_IDLE : S_CHECK_RX;
					read_flag_w = bytes_counter_r == 31 ? 0 : 1;
				end
			end
			S_CHECK_TX: begin
				StartRead(STATUS_BASE);
				io_state_w = S_TO_SEND;
			end
			S_TO_SEND: begin
				if(!avm_waitrequest) begin
					DoNothing();
					if(avm_readdata[TX_OK_BIT]) begin
						StartWrite(TX_BASE);
						io_state_w = S_SENDING;
					end else begin
						io_state_w = S_CHECK_TX;
					end
				end
			end
			S_SENDING: begin
				if(!avm_waitrequest) begin
					DoNothing();
					write_buffer_w = write_buffer_r << 8;
					bytes_counter_w = bytes_counter_r + 1;
					io_state_w = bytes_counter_r == 31 ? S_IDLE : S_CHECK_TX;
					write_flag_w = 0;
				end
			end
		endcase

		main_state_w = main_state_r;
		rsa_start_w = rsa_start_r;
		case (main_state_r)
			S_BEGIN: begin
				// read_flag_w = 1;
				main_state_w = S_READ_N;
				read_flag_w = 1;
			end
			S_READ_N: begin
				if (!read_flag_r) begin
					main_state_w = S_READ_D;
					n_w = read_buffer_r;
					read_flag_w = 1;
				end
			end
			S_READ_D: begin
				if (!read_flag_r) begin
					main_state_w = S_READ_A;
					d_w = read_buffer_r;
					read_flag_w = 1;
				end
			end
			S_READ_A: begin
				if (!read_flag_r) begin
					main_state_w = S_CALC_BEGIN;
					enc_w = read_buffer_r;
					rsa_start_w = 1;
				end
			end
			S_CALC_BEGIN: begin
				rsa_start_w = 0;
				main_state_w = S_CALC_WAIT;
			end
			S_CALC_WAIT: begin
				if (rsa_finished) begin
					write_flag_w = 1;
					write_buffer_w = rsa_dec;
					main_state_w = S_WRITE_ANS;
				end
			end
			S_WRITE_ANS: begin
				if (!write_flag_r) begin
					main_state_w = S_READ_A;
					read_flag_w = 1;
				end
			end
		endcase
	end

	always_ff @(posedge avm_clk or posedge avm_rst) begin
		if (avm_rst) begin
			n_r <= 0;
			d_r <= 0;
			enc_r <= 0;
			dec_r <= 0;
			avm_address_r <= STATUS_BASE;
			avm_read_r <= 1;
			avm_write_r <= 0;
			rsa_start_r <= 0;
			io_state_r <= S_IDLE;
			counter_r <= 0;
			num_r <= 0;
			write_buffer_r <= '0;
			read_buffer_r <= '0;
			bytes_counter_r <= 0;
			write_flag_r <= 0;
			read_flag_r <= 0;
			main_state_r <= S_BEGIN;
		end else begin
			n_r <= n_w;
			d_r <= d_w;
			enc_r <= enc_w;
			dec_r <= dec_w;
			avm_address_r <= avm_address_w;
			avm_read_r <= avm_read_w;
			avm_write_r <= avm_write_w;
			rsa_start_r <= rsa_start_w;
			io_state_r <= io_state_w;
			counter_r <= counter_w;
			num_r <= num_w;
			write_buffer_r <= write_buffer_w;
			read_buffer_r <= read_buffer_w;
			write_flag_r <= write_flag_w;
			read_flag_r <= read_flag_w;
			bytes_counter_r <= bytes_counter_w;
			main_state_r <= main_state_w;
		end
	end
endmodule
