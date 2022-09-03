module AudPlayer(
	input           i_rst_n,
	input           i_bclk,
	input           i_daclrck,
	input           i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0]    i_dac_data, //dac_data
	output          o_aud_dacdat
);

localparam S_IDLE = 1'd0;
localparam S_PLAY = 1'd1;


logic        LRC, LRC_next;
logic        state, state_next;
logic [ 3:0] counter, counter_next;
assign o_aud_dacdat = (state == S_PLAY) ? i_dac_data[counter] : 1'b0;

always_comb begin
	LRC_next = i_daclrck;
	if (i_en) begin
		case(state)
			S_IDLE: begin
				if (LRC != i_daclrck) begin
					state_next   = S_PLAY;
					counter_next = counter;
				end
				else begin
					state_next   = S_IDLE;
					counter_next = counter;
				end
			end
			S_PLAY: begin
				state_next   = (counter == 0) ? S_IDLE : state;
				counter_next = (counter == 0) ? 4'd15 : (counter - 1);
			end
			default: begin
				state_next   = S_IDLE;
				counter_next = counter;
			end
		endcase
	end
	else begin
		state_next   = state;
		counter_next = counter;
	end
end

always_ff @(negedge i_bclk or negedge i_rst_n) begin
	if (~i_rst_n) begin
		counter <= 15;
		state   <= S_IDLE;
	   LRC     <= i_daclrck;
	end 
    else begin
		counter <= counter_next;
		state   <= state_next;
	   LRC     <= LRC_next;
	end
end

endmodule