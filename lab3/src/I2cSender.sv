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
// 0011 010 0 W
// 000_0000_0_1001_0111
// 000_0001_0_1001_0111
// 000_0010_0_0111_1001
// 000_0011_0_0111_1001
// 000_0100_0_0001_0101
// 000_0101_0_0000_0000
// 000_0110_0_0000_0000
// 000_0111_0_0100_0010
// 000_1000_0_0001_1001
// 000_1001_0_0000_0001
//
// 000_1111_0_0000_0000 Reset
localparam INITIAL_STATE = 0;
localparam TRANSIT_STATE = 1;
localparam DATAPAS_STATE = 2;
localparam FINAL_STATE   = 3;

logic o_sclk_r, o_sclk_w, o_finished_r, o_finished_w, o_sdat_r, o_sdat_w;
logic [1:0] state_w;
logic [1:0] state_r;
logic oe_r, oe_w;
logic [BYTE * 8 - 1 : 0] data_r;
logic [BYTE * 8 - 1 : 0] data_w;

logic [3:0] total_count_r;
logic [3:0] total_count_w;
logic [1:0] clk_count_r;
logic [1:0] clk_count_w;
logic [1:0] bytes_count_r;
logic [1:0] bytes_count_w;

assign o_finished = o_finished_r;
assign o_sclk = o_sclk_r;
assign o_sdat = oe_r ? o_sdat_r : 1'bz;

always_comb begin
    state_w       = state_r;
    o_finished_w  = o_finished_r;
    o_sclk_w      = o_sclk_r;
    o_sdat_w      = o_sdat_r;
    total_count_w = total_count_r;
    clk_count_w   = clk_count_r;
    oe_w          = oe_r;
    data_w        = data_r;
    bytes_count_w = bytes_count_r;
    if(i_start == 1 && state_r == INITIAL_STATE) begin
        state_w      = 2'b01;
        o_sdat_w     = 0;
        o_finished_w = 0;
		total_count_w = 4'b0;
		clk_count_w   = 2'b0;
		bytes_count_w = 2'b0;
        data_w        = i_dat;
    end
    else if(state_r == TRANSIT_STATE) begin
        if(o_sclk_r == 1) begin
            o_sclk_w = 0;
        end
        else begin
            state_w  = 2'b10;
            o_sdat_w = data_r[BYTE * 8 - 1];
            data_w[BYTE * 8 - 1 : 1] = data_r[BYTE * 8 - 2 : 0];
        end
    end
    else if(state_r == DATAPAS_STATE) begin
        if(clk_count_r == 0) begin
            clk_count_w = clk_count_r + 1;
            o_sclk_w    = 1;
        end
        else if(clk_count_r == 1) begin
            clk_count_w = clk_count_r + 1;
            o_sclk_w    = 0;
        end
        else if(clk_count_r == 2) begin
            clk_count_w = 0;
        end
        
        if(clk_count_r == 2 && total_count_r == 4'b1000 && bytes_count_r == BYTE - 1) begin
            o_sdat_w = 0;
			oe_w     = 1;
            state_w  = 2'b11;
        end
        else if(clk_count_r == 2 && total_count_r < 4'b0111) begin
            o_sdat_w                 = data_r[BYTE * 8 - 1];
            data_w[BYTE * 8 - 1 : 1] = data_r[BYTE * 8 - 2 : 0];
            total_count_w            = total_count_r + 1;
        end
        else if(clk_count_r == 2 && total_count_r == 4'b0111) begin
            oe_w          = 0;
            total_count_w = total_count_r + 1;
        end
        else if(clk_count_r == 2 && total_count_r == 4'b1000) begin
            oe_w          = 1;
            total_count_w = 4'b0;
            bytes_count_w = bytes_count_r + 1; 
            o_sdat_w                 = data_r[BYTE * 8 - 1];
            data_w[BYTE * 8 - 1 : 1] = data_r[BYTE * 8 - 2 : 0];
        end 
    end
    else if(state_r == FINAL_STATE) begin
        if(o_sclk_r == 0) begin
            o_sclk_w = 1;
        end
        else begin
            o_sdat_w     = 1;
            state_w      = 2'b0;
            o_finished_w = 1;
        end
    end 
end

always_ff @(posedge i_clk, i_rst) begin
    if(!i_rst) begin
        state_r       <= 2'b0;
        o_finished_r  <= 1;
        o_sclk_r      <= 1;
        o_sdat_r      <= 1;
        total_count_r <= 4'b0;
        clk_count_r   <= 2'b0;
        bytes_count_r <= 2'b0;
        oe_r          <= 1;
        data_r        <= i_dat;
    end
    else begin
        state_r       <= state_w;
        o_finished_r  <= o_finished_w;
        o_sclk_r      <= o_sclk_w;
        o_sdat_r      <= o_sdat_w;
        total_count_r <= total_count_w;
        clk_count_r   <= clk_count_w;
        bytes_count_r <= bytes_count_w;
        oe_r          <= oe_w;
        data_r        <= data_w;
    end
end


endmodule 
