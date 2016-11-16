module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start_cal, fin, rst;
	initial clk = 0;
	always #HCLK clk = ~clk;
	logic [255:0] encrypted_data, decrypted_data;
	logic [247:0] decrypted_data_gold;
	integer fp_e, fp_d;

	logic[255:0] modcall1, modcall2, transret, mulret, n; 
	logic strans, smul, ftrans, fmul;

	Rsa256Core core(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(start_cal),
		.i_trans_done(ftrans),
	 	.i_mul_done(fmul),
		.i_a(encrypted_data),
		// .i_a(256'h0000000000000000000000000000000000000000000000000000000000000002),
		.i_e(256'hB6ACE0B14720169839B15FD13326CF1A1829BEAFC37BB937BEC8802FBCF46BD9),
		.i_n(256'hCA3586E7EA485F3B0A222A4C79F7DD12E85388ECCDEE4035940D774C029CF831),
		.i_transreturn(transret),
		.i_mulreturn(mulret),
		.o_a_pow_e(decrypted_data),
		.o_modcall1(modcall1),
		.o_modcall2(modcall2),
		.o_finished(fin),
		.o_start_trans(strans),
		.o_start_mul(smul),
		.o_n(n)
	);

	montTrans trans0(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(strans),
		.i_a(modcall1),
		.i_n(n),
		.o_a_mont(transret),
		.o_finished(ftrans)
	);

	montMul mul0(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(smul),
		.i_a(modcall1),
		.i_b(modcall2),
		.i_n(n),
		.o_abmodn(mulret),
		.o_finished(fmul)
	);

	initial begin
		$fsdbDumpfile("core.fsdb");
		$fsdbDumpvars;
		fp_e = $fopen("../pc_sw/golden/enc2.bin", "rb");
		fp_d = $fopen("../pc_sw/golden/dec2.txt", "rb");
		rst = 1;
		#(2*CLK)
		rst = 0;
		for (int i = 0; i < 5; i++) begin
			for (int j = 0; j < 10; j++) begin
				@(posedge clk);
			end
			$fread(encrypted_data, fp_e);
			$fread(decrypted_data_gold, fp_d);
			$display("=========");
			$display("enc  %2d = %64x", i, encrypted_data);
			$display("=========");
			start_cal <= 1;
			@(posedge clk)
			encrypted_data <= 'x;
			start_cal <= 0;
			@(posedge fin)
			$display("=========");
			$display("dec  %2d = %64x", i, decrypted_data);
			$display("gold %2d = %64x", i, decrypted_data_gold);
			$display("=========");
		end
		$finish;
	end

	initial begin
		#(50000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
