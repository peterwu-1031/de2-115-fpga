module Lfsr (
	input        i_clk,
	input        i_rst_n,
	input  [2:0] state,
	output       o_random_out
);

// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;
// ===== Seed =====
parameter seed   = 16'b1111011100110011;
// ===== Registers & Wires =====
logic [15:0] lfsr_w, lfsr_r;
// ===== Output Assignments =====
assign o_random_out = (state == 3'd2) ? lfsr_r[0] : 0;
// ===== Combinational Circuits =====
always_comb begin
    if (state == 3'd2) begin
		lfsr_w = lfsr_r;
	 end
    else begin
		lfsr_w	= {lfsr_r[8] ^ (lfsr_r[6] ^ (lfsr_r[5] ^ lfsr_r[3])), 
                lfsr_r[7] ^ (lfsr_r[5] ^ (lfsr_r[4] ^ lfsr_r[2])), 
                lfsr_r[6] ^ (lfsr_r[4] ^ (lfsr_r[3] ^ lfsr_r[1])), 
                lfsr_r[5] ^ (lfsr_r[3] ^ (lfsr_r[2] ^ lfsr_r[0])), 
                lfsr_r[15:4]}; 
	 end
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		lfsr_r <= seed;
	end
	else begin
		lfsr_r <= lfsr_w;
	end
end

endmodule
