module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm
parameter S_IDLE = 2'd0;
parameter S_PREP = 2'd1;
parameter S_MONT = 2'd2;
parameter S_CALC = 2'd3;
logic [  1:0] state, state_next;
logic [  8:0] calc, calc_next;
logic [255:0] m, m_next;
logic [255:0] t, t_next;
logic [256:0] prep_out; // y * 2^256
logic [255:0] o_mont_m, o_mont_t;
logic         prep_finished;
logic         mont_finished_m, mont_finished_t;
logic         finished;
assign o_a_pow_d  = m;
assign o_finished = finished;

RsaPrep prep (
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_start(i_start),
	.state(state),
	.i_y(i_a),
	.i_n(i_n),
	.o_prep(prep_out),
	.o_finished(prep_finished)
);

RsaMont mont0 (
	.i_clk(i_clk),
	.i_rst(i_rst),
	.state(state),
	.i_a(m_next),
	.i_b(t_next),
	.i_n(i_n),
	.o_mont(o_mont_m),
	.o_finished(mont_finished_m)
);

RsaMont mont1 (
	.i_clk(i_clk),
	.i_rst(i_rst),
	.state(state),
	.i_a(t_next),
	.i_b(t_next),
	.i_n(i_n),
	.o_mont(o_mont_t),
	.o_finished(mont_finished_t)
);
// FSM
always_comb begin
	if (i_start) begin
		state_next = S_PREP;
	end
	else begin
		case (state)
			S_PREP: begin
				state_next = prep_finished ? S_MONT : state;
			end
			S_MONT: begin
				state_next = mont_finished_m ? S_CALC : state;
			end
			S_CALC: begin
				state_next = calc[8] ? S_IDLE : S_MONT;
			end
			default: begin
				state_next = S_IDLE;
			end
		endcase
	end	
end
// t
always_comb begin
	if (i_start) begin
		t_next = 0;
	end
	else if (prep_finished) begin
		t_next = prep_out[255:0];
	end
	else if (mont_finished_t) begin
		t_next = o_mont_t;
	end
	else begin
		t_next = t;
	end 
end
// m
always_comb begin
	if (i_start) begin
		m_next = 1;
	end
	else if (mont_finished_m & i_d[calc - 1]) begin
		m_next = o_mont_m;
	end
	else begin
		m_next = m;
	end 
end
// calc
always_comb begin
	if (i_start) begin
		calc_next = 1;
	end
	else if (state == S_CALC) begin
		calc_next = calc[8] ? 1 : (calc + 1);
	end
	else begin
		calc_next = calc;
	end
end
// finished?
always_comb begin
	if (state == S_CALC & calc[8]) begin
		finished = 1;
	end
	else begin
		finished = 0;
	end
end
// Sequential
always_ff @(posedge i_clk) begin
	// reset
	if (i_rst) begin
		state <= S_IDLE;
		t     <= 0;
		m     <= 1;
		calc  <= 1;
	end
	else begin
		state <= state_next;
		t     <= t_next;
		m     <= m_next;
		calc  <= calc_next;
	end
end

endmodule

// RsaPrep
module RsaPrep (
	input         i_clk,
	input         i_rst,
	input         i_start,
	input [  1:0] state,
	input [255:0] i_y, // cipher text
	input [255:0] i_n,
	output[256:0] o_prep,
	output        o_finished
);

logic [256:0] o_y, o_y_next;
logic [  8:0] counter, counter_next;
logic         finished;
parameter     S_IDLE = 2'd0;
parameter     S_PREP = 2'd1;
assign o_prep     = (o_y >= {1'b0, i_n}) ? (o_y - {1'b0, i_n}) : o_y;
assign o_finished = finished;
// y * 2^256
always_comb begin
	if (i_start) begin
		o_y_next = {1'b0, i_y};
	end
	else if (state == S_PREP & ~counter[8]) begin
		o_y_next = ((o_y << 1) >= {1'b0, i_n}) ? ((o_y << 1) - {1'b0, i_n}) : (o_y << 1);
	end
	else begin
		o_y_next = o_y;
	end	
end
// counter
always_comb begin
	if (state == S_PREP & ~i_start) begin
		counter_next = counter[8] ? 0 : (counter + 1);
	end
	else begin
		counter_next = 0;
	end
end
// prep finished?
always_comb begin
	if (counter[8]) begin
		finished = 1;
	end
	else begin
		finished = 0;
	end
end
// Sequential
always_ff @(posedge i_clk) begin
	// reset
	if (i_rst) begin
		o_y     <= 0;
		counter <= 0;
	end
	else begin
		o_y     <= o_y_next;
		counter <= counter_next;
	end
end

endmodule

// RsaMont
module RsaMont (
	input         i_clk,
	input         i_rst,
	input [  1:0] state,
	input [255:0] i_a,
	input [255:0] i_b,
	input [255:0] i_n,
	output[255:0] o_mont,
	output        o_finished
);
parameter S_MONT = 2'd2;
parameter S_CALC = 2'd3;
logic [259:0] m, m_next;
logic [  8:0] counter, counter_next;
logic         finished;
assign o_mont     = (m >= i_n) ? (m - i_n) : m;
assign o_finished = finished;
// counter
always_comb begin
	if (state == S_MONT) begin
		counter_next = counter[8] ? 0 : (counter + 1);
	end
	else begin
		counter_next = 0;
	end
end
// m
always_comb begin
	if (state == S_MONT) begin
		if (i_a[counter]) begin
			m_next = (m[0] ^ i_b[0]) ? ((m + i_b + i_n) >> 1) : ((m + i_b) >> 1);
		end
		else if (m[0]) begin
			m_next = (m + i_n) >> 1;
		end
		else begin
			m_next = m >> 1;
		end
	end
	else begin
		m_next = 0;
	end
end
// mont finished?
always_comb begin
	if (counter[8]) begin
		finished = 1;
	end
	else begin
		finished = 0;
	end
end
// Sequential
always_ff @(posedge i_clk) begin
	// reset
	if (i_rst) begin
		m       <= 0;
		counter <= 0;
	end
	else begin
		m       <= m_next;
		counter <= counter_next;
	end
end

endmodule





