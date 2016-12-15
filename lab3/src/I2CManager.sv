module I2CManager (
    input i_start,
    input i_clk,
    input i_rst,
    output o_finished,
    output o_sclk,
    output[1:0] o_ini_state,
    inout o_sdat
);

    logic done_r, done_w;
    logic i_start_r, i_start_w;
    logic get_finish_i;
    logic [23:0] i2c_data_r, i2c_data_w;
    logic o_finished_r, o_finished_w;


    I2cSender #(.BYTE(3)) a3(
        .i_start(i_start_r),
        .i_dat(i2c_data_r),
        .i_clk(i_clk),
        .i_rst(i_rst),
        .o_finished(get_finish_i),
        .o_sclk(o_sclk),
        .o_sdat(o_sdat)
    );

    assign o_finished = o_finished_r;
    assign o_ini_state = {done_r, get_finish_i};

    always_comb begin
        if(i_start && done_r == 0) begin
            if(counter_r[7:0] <= 5) begin
                i_start_w = 1;
                counter_w[7:0] = counter_r[7:0] + 1;
                o_finished_w = 0;
            end
            else if(counter_r == 6) begin
                i_start_w = 0;
                counter_w[7:0] = counter_r[7:0] + 1;
            end
            else if(get_finish_i == 1) begin
                counter_w[23:20] = counter_r[23:20] + 1;
                counter_w[7:0] = 8'b0;
                if(counter_r[23:20] == 0) begin
                    i2c_data_w[12:9] = 4'b0100;
                    i2c_data_w[4:0]  = 5'b10101;
                end
                else if(counter_r[23:20] == 1) begin
                    i2c_data_w[12:9] = i2c_data_r[12:9] + 1;
                    i2c_data_w[4:0]  = 5'b00000;
                end
                else if(counter_r[23:20] == 2) begin
                    i2c_data_w[12:9] = i2c_data_r[12:9] + 1;
                end
                else if(counter_r[23:20] == 3) begin
                    i2c_data_w[12:9] = i2c_data_r[12:9] + 1;
                    i2c_data_w[6:0]  = 7'b100_0010;
                end
                else if(counter_r[23:20] == 4) begin
                    i2c_data_w[12:9] = i2c_data_r[12:9] + 1;
                    i2c_data_w[4:0]  = 5'b11001;
                end
                else if(counter_r[23:20] == 5) begin
                    i2c_data_w[12:9] = i2c_data_r[12:9] + 1;
                    i2c_data_w[4:0]  = 5'b00001;
                end
                else if(counter_r[23:20] == 6) begin
                    counter_w        = 24'b0;
                    i_start_w        = 0;
                    i2c_data_w       = 24'b0011_0100_000_1111_0_0000_0000;
                    o_finished_w     = 1;
                    done_w           = 1;
                end
    // 000_0100_0_0001_0101
    // 000_0101_0_0000_0000
    // 000_0110_0_0000_0000
    // 000_0111_0_0100_0010
    // 000_1000_0_0001_1001
    // 000_1001_0_0000_0001
            end
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            done_r <= 0;
            i_start_r <= 0;
            i2c_data_r <= 24'b0011_0100_000_1111_0_0000_0000;
            o_finished_r <= 0;

        end else begin
            done_r <= done_w;
            i_start_r <= i_start_w;
            i2c_data_r <= i2c_data_w;
            o_finished_r <= o_finished_w;
        end
    end

endmodule
