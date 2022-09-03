module AudDSP(
	input         i_rst_n,
	input         i_clk,
    input         i_start,
    input         i_pause,
    input         i_stop,
    input  [2:0]  i_speed,  // design how user can decide mode on your own
    input         i_fast,
    input         i_slow_0, // constant interpolation
    input         i_slow_1, // linear interpolation
	input         i_daclrck,
    input  [15:0] i_sram_data,
	input  [19:0] i_start_addr,
    output [15:0] o_dac_data,
	output [19:0] o_sram_addr
);
// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player
localparam S_IDLE  = 2'd0;
localparam S_PLAY  = 2'd1;
localparam S_PAUSE = 2'd2;

logic signed  [16:0]  data_diff, data_step, data_inc;
logic 	[19:0]	o_sram_addr_r, o_sram_addr_w, start_addr_temp;
logic 	[15:0]	o_dac_data_r, o_dac_data_w, prev_sram_data_r, prev_sram_data_w;
logic 	[1:0]	state_r, state_w;
logic			o_valid_r, o_valid_w, new_data_r, new_data_w, finish_r, finish_w;
logic 	[2:0]	data_counter_r, data_counter_w;

assign o_sram_addr = o_sram_addr_r;
assign o_dac_data = o_dac_data_r;
//assign o_valid = o_valid_r;

//for linear interpolation
assign data_diff = $signed(i_sram_data) - $signed(prev_sram_data_r);
assign data_inc = data_step*data_counter_r;

// data_step
always_comb begin
	case(i_speed)
        3'b000: data_step = data_diff;
        3'b001: data_step = data_diff>>>1;
        3'b010: data_step = (data_diff>>>2) + (data_diff>>>4) + (data_diff>>>6) + (data_diff>>>8) + (data_diff>>>10) + (data_diff>>>12);
        3'b011: data_step = data_diff>>>2;
        3'b100: data_step = (data_diff>>>3) + (data_diff>>>4) + (data_diff>>>7) + (data_diff>>>8) + (data_diff>>>11) + (data_diff>>>12);
        3'b101: data_step = (data_diff>>>3) + (data_diff>>>5) + (data_diff>>>7) + (data_diff>>>9) + (data_diff>>>11) + (data_diff>>>13);
        3'b110: data_step = (data_diff>>>3) + (data_diff>>>6) + (data_diff>>>9) + (data_diff>>>12) + (data_diff>>>15);
        3'b111: data_step = data_diff>>>3;
        default:data_step = data_diff;
    endcase
end
// o_sram_addr_w, finish_w
always_comb begin
	o_sram_addr_w = o_sram_addr_r;
	finish_w = finish_r;
	case(state_r)
		S_IDLE: begin
			o_sram_addr_w = i_start_addr;
			finish_w = 1'b0;
		end
		S_PLAY: begin
			if (i_start_addr != start_addr_temp) begin
				o_sram_addr_w = i_start_addr;
			end
			else begin
				if (i_speed==3'b000 || i_fast) begin
					if (!o_valid_r && o_valid_w) begin
						// only change once
						if (o_sram_addr_r > {{19{1'b1}}, 1'b0}-i_speed) begin
							// finish play
							o_sram_addr_w = i_start_addr;
							finish_w = 1'b1;
						end
						else begin
							o_sram_addr_w = o_sram_addr_r + 1'b1 + i_speed;
							finish_w = 1'b0;
						end 
					end 
					else begin
						o_sram_addr_w = o_sram_addr_r;
					end
				end
				else begin
					if (!o_valid_r && o_valid_w) begin
						if (data_counter_r==4'b0) begin
							if (o_sram_addr_r == {20{1'b1}}) begin
								// finish play
								o_sram_addr_w = i_start_addr;
								finish_w = 1'b1;
							end 
							else begin
								o_sram_addr_w = o_sram_addr_r + 1'b1;
								finish_w = 1'b0;
							end
						end
						else begin
							o_sram_addr_w = o_sram_addr_r;
						end
					end 
					else begin
						o_sram_addr_w = o_sram_addr_r;
					end
				end
			end
		end
		S_PAUSE:begin
			o_sram_addr_w = o_sram_addr_r;
			finish_w = 1'b0;
		end
		default: begin
			o_sram_addr_w = i_start_addr;
			finish_w = 1'b0;
		end
	endcase
end
// o_dac_data_w, o_valid_w
always_comb begin
	case(state_r)
		S_PLAY: begin
			if (!new_data_r && new_data_w) begin
				if (i_speed==3'b0 || i_fast) begin
					o_dac_data_w = i_sram_data;
				end
				else begin
					// slow
					if (data_counter_r==0) begin
						o_dac_data_w = i_sram_data;
					end
					else o_dac_data_w = i_slow_0 ? prev_sram_data_r : prev_sram_data_r + data_inc;
				end
				o_valid_w = 1'b1;
			end 
			else if (new_data_r && !new_data_w) begin
				o_dac_data_w = o_dac_data_r;
				o_valid_w = 1'b0;
			end 
			else begin
				o_dac_data_w = o_dac_data_r;
				o_valid_w = o_valid_r;
			end
		end
		default: begin
			o_dac_data_w = 16'b0;
			o_valid_w = 1'b0;
		end
	endcase
end
// prev_sram_data_w
always_comb begin
	case(state_r)
		S_IDLE: prev_sram_data_w = 16'b0;
		S_PLAY: begin
			if (!o_valid_r && o_valid_w) begin
				prev_sram_data_w = (data_counter_r==4'b0) ? i_sram_data : prev_sram_data_r;
			end
			else prev_sram_data_w = prev_sram_data_r;
		end
		S_PAUSE: prev_sram_data_w = prev_sram_data_r;
	endcase
end
// new_data_w
assign new_data_w = !i_daclrck; // left channel
// data_counter_w
always_comb begin
	case(state_r)
		S_IDLE: data_counter_w = 3'b0;
		S_PLAY: begin
			if (!o_valid_r && o_valid_w) begin
				data_counter_w = (data_counter_r==i_speed) ? 4'b0 : data_counter_r + 1;
			end 
			else data_counter_w = data_counter_r;
		end
		S_PAUSE: data_counter_w = data_counter_r;
	endcase
end
// FSM
always_comb begin
	case(state_r)
		S_IDLE: begin
			state_w = i_start ? S_PLAY : S_IDLE;
		end
		S_PLAY: begin
			if (i_stop || finish_r) begin
				state_w = S_IDLE;
			end
			else if (i_pause) begin
				state_w = S_PAUSE;
			end
			else begin
				state_w = S_PLAY;
			end
		end
		S_PAUSE: begin
			if (i_stop || finish_r) begin
				state_w = S_IDLE;
			end
			else if (i_start) begin
				state_w = S_PLAY;
			end
			else begin
				state_w = S_PAUSE;
			end
		end
		default:state_w = S_IDLE;
	endcase
end

// Sequential
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		o_sram_addr_r <= i_start_addr;
		o_dac_data_r <= 16'b0;
		prev_sram_data_r <= 16'b0;
		state_r <= 2'b0;
		o_valid_r <= 1'b0;
		new_data_r <= 1'b1;
		data_counter_r <= 4'b0;
		finish_r <= 1'b0;
		start_addr_temp <= 20'd0;
	end
	else begin
		o_sram_addr_r <= o_sram_addr_w;
		o_dac_data_r <= o_dac_data_w;
		prev_sram_data_r <= prev_sram_data_w;
		state_r <= state_w;
		o_valid_r <= o_valid_w;
		new_data_r <= new_data_w;
		data_counter_r <= data_counter_w;
		finish_r <= finish_w;
		start_addr_temp <= i_start_addr;
	end
end

endmodule