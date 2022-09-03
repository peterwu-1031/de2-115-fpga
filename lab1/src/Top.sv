module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out,
    output [3:0] memory_out
);

// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;
// ===== Seed =====
parameter seed   = 16'b1111011100110001;
// ===== Registers & Wires =====
logic state_r, state_w;
logic started, started_next;
logic [26:0]counter, counter_next;
logic [15:0]o_random_out_r, o_random_out_w;
logic [ 5:0]interval, interval_next;
logic [ 3:0]prolonged, prolonged_next;
logic [ 3:0]memory, memory_next;
// ===== Output Assignments =====
assign o_random_out = o_random_out_r[3:0];
assign memory_out   = memory;

// ===== Combinational Circuits =====
always_comb begin
	if (i_start) begin
        state_w        = S_PROC;
        o_random_out_w = started ? {(o_random_out_r[7:4] ^ o_random_out_r[3:0]), o_random_out_r[15:4]} : seed;
        started_next   = 1;
        counter_next   = 1;
        prolonged_next = 1;
        interval_next  = 1;
        memory_next    = o_random_out_r[3:0];
    end
    else begin
        case(state_r)
            S_PROC: begin
                if (counter[26:21] <= interval) begin
                    state_w        = (counter[26]) ? S_IDLE : S_PROC;
                    o_random_out_w = o_random_out_r;
                    started_next   = started;
                    counter_next   = counter + 1;
                    prolonged_next = prolonged;
                    interval_next  = interval;
                    memory_next    = memory;
                end
                else begin
                    state_w        = S_PROC;
                    o_random_out_w = {(o_random_out_r[7:4] ^ o_random_out_r[3:0]), o_random_out_r[15:4]};
                    started_next   = started;
                    counter_next   = 1;
                    if (prolonged >= 4'd13) begin
                        interval_next  = interval << 1;
                        prolonged_next = prolonged;
                    end
                    else begin
                        interval_next  = interval;
                        prolonged_next = prolonged + 1;
                    end
                    memory_next    = memory;
                end
            end
            default: begin
                state_w        = S_IDLE;
                o_random_out_w = o_random_out_r;
                started_next   = started;
                counter_next   = 1;
                prolonged_next = 1;
                interval_next  = 1;
                memory_next    = memory;
            end
        endcase
    end
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		o_random_out_r <= {o_random_out_w[15:4], 4'b0};
		state_r        <= S_IDLE;
        started        <= 0;
        counter        <= 1;
        prolonged      <= 1;
        interval       <= 1;
        memory         <= 0;
	end
	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
        started        <= started_next;
        counter        <= counter_next;
        prolonged <= prolonged_next;
        interval       <= interval_next;
        memory         <= memory_next;
	end
end

endmodule
