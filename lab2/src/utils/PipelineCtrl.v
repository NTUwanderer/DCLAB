module PPForward(
	input      clk,
	input      rst,
	input      src_rdy,
	output reg src_ack,
	output reg dst_rdy,
	input      dst_ack
);

reg dst_rdy_w;
always@* begin
	src_ack = src_rdy && (dst_ack || !dst_rdy);
	dst_rdy_w = src_rdy || (dst_rdy && !dst_ack);
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		dst_rdy <= 1'b0;
	end else if (dst_rdy != dst_rdy_w) begin
		dst_rdy <= dst_rdy_w;
	end
end

endmodule

//////////

module PPTwoSrc(
	input      src1_rdy,
	output reg src1_ack,
	input      src2_rdy,
	output reg src2_ack
);

reg ack;
always@* begin
	ack = src1_ack && src2_ack;
	src1_ack = ack;
	src2_ack = ack;
end

endmodule
