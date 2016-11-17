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

	// localparam S_GET_KEY = 0;
	// localparam S_GET_DATA = 1;
	// localparam S_WAIT_CALCULATE = 2;
	// localparam S_SEND_DATA = 3;

	typedef enum {
		S_IDLE,
		S_READ_N,
		S_READ_E,
		S_READ_DATA,
		S_CALC_BEGIN,
		S_CALC_WAIT,
		S_WRITE
	} State;

	typedef enum {
		IO_IDLE,
		IO_CHECK_RX,
		IO_TO_RECEIVE,
		IO_RECEIVE_ONE_BYTE,
		IO_CHECK_TX,
		IO_TO_SEND,
		IO_SEND_ONE_BYTE
	} IO_State;

	typedef enum {
		RW_IDLE,
		RW_READ,
		RW_WRITE
	} RW_Flag;

	logic[255:0] modcall1, modcall2, transret, mulret, n2; 
	logic strans, smul, ftrans, fmul;

	logic rsa_start_r, rsa_start_w, rsa_finished;
	logic[255:0] rsa_dec;
	logic[255:0] enc_r, enc_w, e_r, e_w, n_r, n_w;
	logic[255:0] read_buffer_r, read_buffer_w, write_buffer_r, write_buffer_w;
	State state_r, state_w;
	IO_State io_state_r, io_state_w;
	RW_Flag flag_r, flag_w;

	logic [4:0] avm_address_r, avm_address_w;
	logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

	logic [4:0] bytes_counter_r, bytes_counter_w;

	assign avm_address = avm_address_r;
	assign avm_read = avm_read_r;
	assign avm_write = avm_write_r;
	assign avm_writedata = write_buffer_r[255-:8];

	Rsa256Core core0(
		.i_clk(avm_clk),
		.i_rst(avm_rst),
	 	.i_start(rsa_start_r),
		.i_trans_done(ftrans),
	 	.i_mul_done(fmul),
		.i_a(enc_r),
		.i_e(e_r),
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

	always_comb begin

		// $display("read %d %d wait %d ios %d state_r %d flag_r %d t %0t",
		// 	avm_read,avm_address,avm_waitrequest,io_state_r,state_r,flag_r,$time);
		state_w = state_r;
		io_state_w = io_state_r;
		flag_w = flag_r;
		rsa_start_w = rsa_start_r;
		enc_w = enc_r;
		e_w = e_r;
		n_w = n_r;
		avm_address_w = avm_address_r;
		avm_read_w = avm_read_r;
		avm_write_w = avm_write_r;
		bytes_counter_w = bytes_counter_r;
		read_buffer_w = read_buffer_r;
		write_buffer_w = write_buffer_r;

		case (io_state_r)
			IO_IDLE: begin
				DoNothing();
				case (flag_r)
					RW_IDLE: io_state_w = IO_IDLE;
					RW_READ: io_state_w = IO_CHECK_RX;
					RW_WRITE: io_state_w = IO_CHECK_TX;
				endcase
				bytes_counter_w = 0;
			end
			IO_CHECK_RX: begin
				StartRead(STATUS_BASE);
				io_state_w = IO_TO_RECEIVE;
			end
			IO_TO_RECEIVE: begin
				if (avm_waitrequest == 0) begin
					if (avm_readdata[RX_OK_BIT]) begin
						StartRead(RX_BASE);
						io_state_w = IO_RECEIVE_ONE_BYTE;
					end else begin
						DoNothing();
						io_state_w = IO_CHECK_RX;
					end
				end
			end
			IO_RECEIVE_ONE_BYTE: begin
				if (avm_waitrequest == 0) begin
					DoNothing();
					read_buffer_w = (read_buffer_r << 8) + avm_readdata[7:0];
					bytes_counter_w = bytes_counter_r + 1;
					if (bytes_counter_r == 31) begin
						io_state_w = IO_IDLE;
						flag_w = RW_IDLE;
					end else begin
						io_state_w = IO_CHECK_RX;
						flag_w = RW_READ;
					end
				end
			end
			IO_CHECK_TX: begin
				StartRead(STATUS_BASE);
				io_state_w = IO_TO_SEND;
			end
			IO_TO_SEND: begin
				if (avm_waitrequest == 0) begin
					if (avm_readdata[TX_OK_BIT]) begin
						StartRead(TX_BASE);
						io_state_w = IO_SEND_ONE_BYTE;
					end else begin
						DoNothing();
						io_state_w = IO_CHECK_TX;
					end
				end
			end
			IO_SEND_ONE_BYTE: begin
				if (avm_waitrequest == 0) begin
					DoNothing();
					write_buffer_w = (write_buffer_r << 8);
					bytes_counter_w = bytes_counter_r + 1;
					if (bytes_counter_r == 31) begin
						io_state_w = IO_IDLE;
						flag_w = RW_IDLE;
					end else begin
						io_state_w = IO_CHECK_TX;
						flag_w = RW_WRITE;
						// flag_w = RW_IDLE; ...?
					end
				end
			end
		endcase

		case (state_r)
			S_IDLE: begin
				state_w = S_READ_N;
				flag_w = RW_READ;
			end
			S_READ_N: begin
				if (flag_r != RW_READ) begin
					state_w = S_READ_E;
					n_w = read_buffer_r;
					flag_w = RW_READ;
				end
			end
			S_READ_E: begin
				if (flag_r != RW_READ) begin
					state_w = S_READ_DATA;
					e_w = read_buffer_r;
					flag_w = RW_READ;
				end
			end
			S_READ_DATA: begin
				if (flag_r != RW_READ) begin
					state_w = S_CALC_BEGIN;
					enc_w = read_buffer_r;
					rsa_start_w = 1;
				end
			end
			S_CALC_BEGIN: begin
				rsa_start_w = 0;
				state_w = S_CALC_WAIT;
			end
			S_CALC_WAIT: begin
				if (rsa_finished) begin
					flag_w = RW_WRITE;
					write_buffer_w = rsa_dec;
					state_w = S_WRITE;
				end
			end
			S_WRITE: begin
				if (flag_r != RW_WRITE) begin
					state_w = S_IDLE;
					flag_w = RW_READ;
				end
			end
		endcase
		// if(avm_readdata[7] == 1) begin
		// 	$display("avm_readdata 1 time %0t",$time);
		// end
		// if(state_w != state_r) begin
		// 	$display("read %d %d wait %d iow %d state_w %d flag_w %d t %0t",
		// 	avm_read,avm_address,avm_waitrequest,io_state_w,state_w,flag_w,$time);
		// end
	end

	always_ff @(posedge avm_clk or negedge avm_rst) begin
		if (avm_rst) begin
			state_r <= S_IDLE;
			io_state_r <= IO_IDLE;
			flag_r <= RW_IDLE;
			rsa_start_r <= 0;
			enc_r <= 0;
			e_r <= 0;
			n_r <= 0;
			avm_address_r <= STATUS_BASE;
			avm_read_r <= 1;
			avm_write_r <= 0;
			bytes_counter_r <= 0;
			read_buffer_r <= '0;
			write_buffer_r <= '0;
		end else begin
			state_r <= state_w;
			io_state_r <= io_state_w;
			flag_r <= flag_w;
			rsa_start_r <= rsa_start_w;
			enc_r <= enc_w;
			e_r <= e_w;
			n_r <= n_w;
			avm_address_r <= avm_address_w;
			avm_read_r <= avm_read_w;
			avm_write_r <= avm_write_w;
			bytes_counter_r <= bytes_counter_w;
			read_buffer_r <= read_buffer_w;
			write_buffer_r <= write_buffer_w;
		end
	end
endmodule
