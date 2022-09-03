module AudTop (
	input i_rst_n,
	input i_clk,
	input i_key_0,
	input i_key_1,
	input i_key_2,
	// AudDSP and SRAM
	///
	input [2:0] i_speed, // design how user can decide mode on your own
	input       i_fast,
	input       i_slow_0,
	input       i_slow_1,
	input [1:0] sound_index,
	output [3:0] state,
	output music_stop,
	output [19:0] addr,
	///
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	output [5:0] o_record_time
);

// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;
// sound index map to start and finish addr

//// MUSIC
// GAME
parameter START_ADDR_0    = 20'b0;
parameter FINISH_ADDR_0   = {20'h24FD7};
// KILL
parameter START_ADDR_1    = {20'h24FD8};
parameter FINISH_ADDR_1   = {20'h599CF};
// WIN
parameter START_ADDR_2    = {20'h599D0};
parameter FINISH_ADDR_2   = {20'h7E056};
// DIE
parameter START_ADDR_3    = {20'h7E057};
parameter FINISH_ADDR_3   = {20'h97D8F};

logic [19:0] start_addr;
logic [19:0] finish_addr;
always_comb begin
	case(sound_index)
		2'b00 : begin
			start_addr  = START_ADDR_0;
			finish_addr = FINISH_ADDR_0;
		end
		2'b01 : begin
			start_addr  = START_ADDR_1;
			finish_addr = FINISH_ADDR_1;
		end
		2'b10 : begin
			start_addr  = START_ADDR_2;
			finish_addr = FINISH_ADDR_2;
		end
		2'b11 : begin
			start_addr  = START_ADDR_3;
			finish_addr = FINISH_ADDR_3;
		end
		default: begin
			start_addr  = 20'b0;
			finish_addr = {20{1'b1}};
		end
	endcase
end


logic i2c_oen;
wire i2c_sdat;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;
logic [ 2:0] state_r, state_w;

logic i2c_start, i2c_finished;
logic dsp_start, dsp_stop, dsp_pause;
logic player_en;
logic recorder_start, recorder_pause, recorder_stop;
logic stop;

assign addr = addr_play;
assign state = {1'b0,state_r};
assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input
assign music_stop = stop;

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign i2c_start      = 1'b1;
assign dsp_start      = (i_key_0 & (state_r == S_IDLE)) | (i_key_1 & (state_r == S_PLAY_PAUSE));
assign dsp_pause      = 0;//i_key_0 & (state_r == S_PLAY);
assign dsp_stop       = (i_key_2 | stop) & ((state_r == S_PLAY) | (state_r == S_PLAY_PAUSE));
assign player_en      = (state_r == S_PLAY);
assign recorder_start = i_key_1 & ((state_r == S_IDLE) | (state_r == S_RECD_PAUSE));
assign recorder_pause = i_key_0 & (state_r == S_RECD);
assign recorder_stop  = i_key_2 & ((state_r == S_RECD) | (state_r == S_RECD_PAUSE));
// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_start),
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(dsp_start),
	.i_pause(dsp_pause),
	.i_stop(dsp_stop),
	.i_speed(i_speed),
	.i_fast(i_fast),
	.i_slow_0(i_slow_0), // constant interpolation
	.i_slow_1(i_slow_1), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.i_start_addr(start_addr),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(player_en), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recorder_start),
	.i_pause(recorder_pause),
	.i_stop(recorder_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record)
);
//stop
always_comb begin
	if((state_r == S_PLAY) & (addr_play >= finish_addr)) begin
		stop = 1;
	end
	else begin
		stop = 0;
	end
end
// FSM
always_comb begin
	// design your control here
	case(state_r)
		S_I2C : begin
			if(i2c_finished)begin
				state_w = S_IDLE;
			end
			else begin
				state_w = state_r;
			end
		end
		S_IDLE : begin
			if(i_key_0) begin
				state_w = S_PLAY;
			end
//			else if (i_key_1) begin
//				state_w = S_RECD;
//			end
			else begin
				state_w = state_r;
			end
		end
		S_RECD : begin
			if(i_key_0) begin
				state_w = S_RECD_PAUSE;
			end
			else if(i_key_2) begin
				state_w = S_IDLE;
			end
			else begin
				state_w = state_r;
			end
		end
		S_RECD_PAUSE : begin
			if(i_key_1) begin
				state_w = S_RECD;
			end
			else if(i_key_2) begin
				state_w = S_IDLE;
			end
			else begin
				state_w = state_r;
			end
		end
		S_PLAY : begin
			if(i_key_2 | stop) begin
				state_w = S_IDLE;
			end
			else begin
				state_w = state_r;
			end
		end
		S_PLAY_PAUSE : begin
			if(i_key_1) begin
				state_w = S_PLAY;
			end
			else if(i_key_2) begin
				state_w = S_IDLE;
			end
			else begin
				state_w = state_r; 
			end
		end
		default: begin
			state_w = S_I2C;
		end
	endcase
end
assign o_record_time = (state_r == S_PLAY || state_r == S_PLAY_PAUSE) ? addr_play[19:15] % 60:
						(state_r == S_RECD || state_r == S_RECD_PAUSE) ? addr_record[19:15] % 60: '1;

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_I2C;
	end
	else begin
		state_r <= state_w;
	end
end

endmodule