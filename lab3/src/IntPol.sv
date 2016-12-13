module FirstIntPol (
    input i_bclk,
    input i_next,
    input i_reset,
    input i_first,
    input [2:0] i_speed,
    input [31:0] i_prev_dat,
    input [31:0] i_dat,
    output [31:0] o_intpol_dat
);
    typedef enum {
        S_INIT,
        S_CALC,
        S_IDLE
    } State;
    State state_r, state_w;
    logic [31:0] intpol_dat_r, intpol_dat_w;

    logic [2:0] speed_r, speed_w;
    logic [2:0] counter_r, counter_w;
    logic greaterL_r, greaterL_w;
    logic greaterR_r, greaterR_w;
    logic [31:0] temp;
    logic [31:0] delta_r, delta_w;

    task Compare;
        input [15:0] prev;
        input [15:0] now;
        output greater;
        begin
            if (prev[15] == 1'b1 && now[15] == 1'b0)        greater = 1'b1;
            else if (prev[15] == 1'b0 && now[15] == 1'b1)   greater = 1'b0;
            else if (now > prev)                            greater = 1'b1;
            else                                            greater = 1'b0;
        end
    endtask

    assign o_intpol_dat = intpol_dat_r;

    always_comb begin
        intpol_dat_w = intpol_dat_r;
        speed_w = speed_r;
        greaterL_w = greaterL_r;
        greaterR_w = greaterR_r;
        temp = 0;
        delta_w = delta_r;

        case (state_r)
            S_INIT: begin
                speed_w = i_speed;
                state_w = S_CALC;
                counter_w = 0;

                intpol_dat_w = i_prev_dat;

                if (i_first) begin
                    Compare(i_prev_dat[31:16], i_dat[31:16], greaterL_w);
                    Compare(i_prev_dat[15:0], i_dat[15:0], greaterR_w);
                    
                    if (greaterL_w)     temp[31:16] = i_dat[31:16] - i_prev_dat[31:16];
                    else                temp[31:16] = i_prev_dat[31:16] - i_dat[31:16];

                    if (greaterR_w)     temp[15:0]  = i_dat[15:0]  - i_prev_dat[15:0];
                    else                temp[15:0]  = i_prev_dat[15:0]  - i_dat[15:0];

                    case (i_speed):
                        0: begin
                            delta_w = temp;
                            state_w = S_INIT;
                        end
                        1: begin
                            delta_w[31:16] = temp[31:16] / 2;
                            delta_w[15:0]  = temp[15:0]  / 2;
                        end
                        2: begin
                            delta_w[31:16] = temp[31:16] / 3;
                            delta_w[15:0]  = temp[15:0]  / 3;
                        end
                        3: begin
                            delta_w[31:16] = temp[31:16] / 4;
                            delta_w[15:0]  = temp[15:0]  / 4;
                        end
                        4: begin
                            delta_w[31:16] = temp[31:16] / 5;
                            delta_w[15:0]  = temp[15:0]  / 5;
                        end
                        5: begin
                            delta_w[31:16] = temp[31:16] / 6;
                            delta_w[15:0]  = temp[15:0]  / 6;
                        end
                        6: begin
                            delta_w[31:16] = temp[31:16] / 7;
                            delta_w[15:0]  = temp[15:0]  / 7;
                        end
                        7: begin
                            delta_w[31:16] = temp[31:16] / 8;
                            delta_w[15:0]  = temp[15:0]  / 8;
                        end
                    endcase
                end else begin
                    delta = 31'b0;
                end
            end

            case S_CALC: begin
                if (i_next) begin
                    counter_w = counter_r + 1;

                    if (greaterL_r == 1'b1) intpol_dat_w[31:16] = intpol_dat_r[31:16] + delta_r[31:16];
                    else                    intpol_dat_w[31:16] = intpol_dat_r[31:16] - delta_r[31:16];

                    if (greaterR_r == 1'b1) intpol_dat_w[15:0]  = intpol_dat_r[15:0]  + delta_r[15:0];
                    else                    intpol_dat_w[15:0]  = intpol_dat_r[15:0]  - delta_r[15:0];

                    if (counter_r == (speed_r - 1)) begin
                        state_w = S_IDLE;
                        counter_w = 0;
                    end
                end
            end

            case S_IDLE: begin
                // intpol_dat_w    = 0; remain last output
                speed_w         = 0;
                counter_w       = 0;
                greaterL_w      = 0;
                greaterR_w      = 0;
                delta_w         = 0;
            end
        endcase
    end

    always_ff @(posedge i_bclk, posedge i_reset) begin
        if (i_reset) begin
            state_r         <= S_INIT;
            intpol_dat_r    <= 0;
            speed_r         <= 0;
            counter_r       <= 0;
            greaterL_r      <= 0;
            greaterR_r      <= 0;
            delta_r         <= 0;
        end else begin
            state_r         <= state_w;
            intpol_dat_r    <= intpol_dat_w;
            speed_r         <= speed_w;
            counter_r       <= counter_w;
            greaterL_r      <= greaterL_w;
            greaterR_r      <= greaterR_w;
            delta_r         <= delta_w;
        end
    end

endmodule
