module Top (
    input i_clk, 
    input i_rst_n,
	 input [2:0] i_pos,
	 output[2:0] o_angle,

    // VGA
    input i_clk_25, 
    output [7:0] VGA_R, 
    output [7:0] VGA_G, 
    output [7:0] VGA_B, 
    output VGA_CLK, 
    output VGA_BLANK_N, 
    output VGA_HS, 
    output VGA_VS, 
    output VGA_SYNC_N,

    // Game
    output [2:0] state,
    input i_next,
    input i_finish_key,
	 input i_music_stop,
	 input detect,
	 //input music_finish
	 output [1:0] music_ind,
	 output play_music

);
    // display sync signals and coordinates
    logic [7:0] r_r, r_w, g_r, g_w, b_r, b_w;

    logic [24:0] sec_count_w, sec_count_r;
    logic [2:0] state_r, state_w, angle_r, angle_w;
    logic [6:0] deadline_r, deadline_w;
	 logic [3:0] sec_ten, sec_one;
	 logic [7:0] count_r, count_w;
	 logic [2:0] sec_modet_r, sec_modet_w;
    logic [3:0] game1_pix, game2_pix, start_pix, win_pix, die_pix, squid_pix, rule_pix;
    logic [11:0] game1_colr, game2_colr, ten_colr, one_colr, start_colr, win_colr, die_colr, squid_colr, rule_colr;
    logic game1_drawing_r, game2_drawing_r, ten_drawing_r, one_drawing_r, start_drawing_r, win_drawing_r, die_drawing_r, squid_drawing_r, rule_drawing_r;
    localparam CORDW = 16; // screen coordinate width
    parameter COLR_BITS = 4;
    parameter H_RES = 640;
    logic signed [CORDW-1:0] sx, sy;
    logic de, line;
    assign VGA_R = r_r;
    assign VGA_G = g_r;
    assign VGA_B = b_r;
	 assign VGA_CLK = i_clk_25;
	 
    assign state = state_r;
	 assign sec_one = deadline_r % 10;
	 assign sec_ten = deadline_r / 10;
    
	 assign music_ind = music_index;
	 assign play_music = (count_r > 0);
	 assign o_angle = angle_r;

	always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            r_r <= 8'b0;
            g_r <= 8'b0;
            b_r <= 8'b0;
        end
		else begin
            r_r <= r_w;
            g_r <= g_w;
            b_r <= b_w;
        end
    end


 timer timer0(
	  .i_clk_25(i_clk_25), 
	  .i_rst_n(i_rst_n),
	  .sx(sx),
	  .sy(sy),
	  .line(line), 
	  .ten(sec_ten),
	  .one(sec_one),
	  .ten_drawing_r(ten_drawing_r),
	  .one_drawing_r(one_drawing_r),
	  .ten_colr(ten_colr),
	  .one_colr(one_colr)
 );
item #(
     .FILE("game1.mem"), 
     .PALETTE_FILE("game1_palette.mem"), 
     .WIDTH(640), 
     .HEIGHT(480)
 ) game1 (
     .i_clk_25(i_clk_25), 
     .i_rst_n(i_rst_n), 
     .sx(sx), 
     .sy(sy), 
     .x_init(0), 
     .y_init(0), 
     .line(line), 
     .pix(game1_pix), 
     .colr(game1_colr), 
     .drawing_r(game1_drawing_r)
 );
item #(
     .FILE("game2.mem"), 
     .PALETTE_FILE("game2_palette.mem"), 
     .WIDTH(640), 
     .HEIGHT(480)
 ) game2 (
     .i_clk_25(i_clk_25), 
     .i_rst_n(i_rst_n), 
     .sx(sx), 
     .sy(sy), 
     .x_init(0), 
     .y_init(0), 
     .line(line), 
     .pix(game2_pix), 
     .colr(game2_colr), 
     .drawing_r(game2_drawing_r)
 );
 item #(
     .FILE("start.mem"), 
     .PALETTE_FILE("start_palette.mem"), 
     .WIDTH(300), 
     .HEIGHT(30)
 ) start0 (
     .i_clk_25(i_clk_25), 
     .i_rst_n(i_rst_n), 
     .sx(sx), 
     .sy(sy), 
     .x_init(170), 
     .y_init(350), 
     .line(line), 
     .pix(start_pix), 
     .colr(start_colr), 
     .drawing_r(start_drawing_r)
 );
  item #(
     .FILE("rule.mem"), 
     .PALETTE_FILE("rule_palette.mem"), 
     .WIDTH(257), 
     .HEIGHT(30)
 ) rule0 (
     .i_clk_25(i_clk_25), 
     .i_rst_n(i_rst_n), 
     .sx(sx), 
     .sy(sy), 
     .x_init(192), 
     .y_init(350), 
     .line(line), 
     .pix(rule_pix), 
     .colr(rule_colr), 
     .drawing_r(rule_drawing_r)
 );
 item #(
     .FILE("win.mem"), 
     .PALETTE_FILE("win_palette.mem"), 
     .WIDTH(270), 
     .HEIGHT(45)
 ) win0 (
     .i_clk_25(i_clk_25), 
     .i_rst_n(i_rst_n), 
     .sx(sx), 
     .sy(sy), 
     .x_init(185), 
     .y_init(240), 
     .line(line), 
     .pix(win_pix), 
     .colr(win_colr), 
     .drawing_r(win_drawing_r)
 );
 item #(
     .FILE("die.mem"), 
     .PALETTE_FILE("die_palette.mem"), 
     .WIDTH(270), 
     .HEIGHT(45)
 ) die0 (
     .i_clk_25(i_clk_25), 
     .i_rst_n(i_rst_n), 
     .sx(sx), 
     .sy(sy), 
     .x_init(185), 
     .y_init(240), 
     .line(line), 
     .pix(die_pix), 
     .colr(die_colr), 
     .drawing_r(die_drawing_r)
 );
  item #(
     .FILE("squid.mem"), 
     .PALETTE_FILE("squid_palette.mem"), 
     .WIDTH(348), 
     .HEIGHT(177)
 ) squid0 (
     .i_clk_25(i_clk_25), 
     .i_rst_n(i_rst_n), 
     .sx(sx), 
     .sy(sy), 
     .x_init(146), 
     .y_init(100), 
     .line(line), 
     .pix(squid_pix), 
     .colr(squid_colr), 
     .drawing_r(squid_drawing_r)
 );
    // monitor
    logic monitor_start_r, monitor_start_w;
    assign monitor_start_w = monitor_start_r;
	 always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
		if (!i_rst_n) begin
            monitor_start_r <= 1'b1;
        end
        else begin
            monitor_start_r <= monitor_start_w;       
        end
    end
    display display0(
        .clk_25M(i_clk_25), 
        .rst_n(i_rst_n), 
        .VGA_BLANK_N(VGA_BLANK_N), 
        .VGA_HS(VGA_HS), 
        .VGA_VS(VGA_VS), 
        .VGA_SYNC_N(VGA_SYNC_N), 
        .de(de),  
        .line(line), 
        .sx(sx), 
        .sy(sy), 
        .i_start_display(monitor_start_r)
    );
    logic [1:0] music_index;
    //Control Music
    always_comb begin
        case(state_r)
            S_GAME: begin
                music_index = 2'b00;
                
            end
            S_KILL: begin
                music_index = 2'b01;
                
            end
            S_WIN: begin
                music_index = 2'b10;
                
            end
            S_DIE: begin
                music_index = 2'b11;
                
            end
            default: begin
                music_index = 2'b00;
                
            end

        endcase
    end
    localparam S_IDLE = 3'd0;
    localparam S_INST = 3'd1;
    localparam S_GAME = 3'd2;
    localparam S_MODET = 3'd3;
    localparam S_DIE = 3'd4;
	 localparam S_KILL = 3'd5;
    localparam S_WIN = 3'd6;

    always_comb begin    
        sec_count_w = sec_count_r;
        deadline_w = deadline_r;
		  r_w = r_r;
		  g_w = g_r;
		  b_w = b_r;
		  angle_w = 3'd0;
		  sec_modet_w = 3'd6;
		  count_w = 8'd0;
        case(state_r)
            S_IDLE: begin
					 r_w = (squid_drawing_r && de) ? {squid_colr[11:8], 4'b0} : (start_drawing_r && de) ? {start_colr[11:8], 4'b0} : 8'b0;
					 g_w = (squid_drawing_r && de) ? {squid_colr[7:4], 4'b0} : (start_drawing_r && de) ? {start_colr[7:4], 4'b0} : 8'b0;
					 b_w = (squid_drawing_r && de) ? {squid_colr[3:0], 4'b0} : (start_drawing_r && de) ? {start_colr[3:0], 4'b0} : 8'b0;
                state_w = i_next ? S_INST : S_IDLE;
                sec_count_w = sec_count_r;
                deadline_w = deadline_r;
            end
            S_INST: begin
					 r_w = (ten_drawing_r && de) ? {ten_colr[11:8],4'b0} : (one_drawing_r && de) ? {one_colr[11:8],4'b0} : (squid_drawing_r && de) ? {squid_colr[11:8], 4'b0} : (rule_drawing_r && de) ? {rule_colr[11:8], 4'b0} : 8'b0;
					 g_w = (ten_drawing_r && de) ? {ten_colr[7:4],4'b0} : (one_drawing_r && de) ? {one_colr[7:4],4'b0} : (squid_drawing_r && de) ? {squid_colr[7:4], 4'b0} : (rule_drawing_r && de) ? {rule_colr[7:4], 4'b0} : 8'b0;
					 b_w = (ten_drawing_r && de) ? {ten_colr[3:0],4'b0} : (one_drawing_r && de) ? {one_colr[3:0],4'b0} : (squid_drawing_r && de) ? {squid_colr[3:0], 4'b0} : (rule_drawing_r && de) ? {rule_colr[3:0], 4'b0} : 8'b0;
                state_w = (deadline_r == 0) ? S_GAME : S_INST;
                sec_count_w = sec_count_r > 0 ? sec_count_r - 1 : 25'b1011111010111100001000000; //clk_25M
                deadline_w = (deadline_r == 0) ? 7'd30 : (sec_count_r == 0) ? deadline_r - 1 : deadline_r;
					 count_w = (deadline_r == 0) ? 8'd255 : 8'd0;				 
            end
            S_GAME: begin
					 r_w = (ten_drawing_r && de) ? {ten_colr[11:8],4'b0} : ((one_drawing_r && de) ? {one_colr[11:8],4'b0} : ((game1_drawing_r && de) ? {game1_colr[11:8], 4'b0} : 8'b0));
                g_w = (ten_drawing_r && de) ? {ten_colr[7:4],4'b0} : ((one_drawing_r && de) ? {one_colr[7:4],4'b0} : ((game1_drawing_r && de) ? {game1_colr[7:4], 4'b0} : 8'b0));
                b_w = (ten_drawing_r && de) ? {ten_colr[3:0],4'b0} : ((one_drawing_r && de) ? {one_colr[3:0],4'b0} : ((game1_drawing_r && de) ? {game1_colr[3:0], 4'b0} : 8'b0));
                sec_count_w = sec_count_r > 0 ? sec_count_r - 1 : 25'b1011111010111100001000000; //clk_25M
                deadline_w = (sec_count_r == 0) ? deadline_r - 1 : deadline_r;
					 count_w = count_r > 0 ? count_r - 1 : 0;
                if(i_music_stop) begin
                    state_w = S_MODET;
                end
                else begin
                    if(i_finish_key) begin
                        state_w = S_WIN;
								count_w = 8'd255;
                    end
                    else if(deadline_r == 0) begin
                        state_w = S_DIE;
								count_w = 8'd255;
                    end
                    else begin
                        state_w = S_GAME;
                    end
                end
            end
            S_MODET: begin
					 r_w = (ten_drawing_r && de) ? {ten_colr[11:8],4'b0} : ((one_drawing_r && de) ? {one_colr[11:8],4'b0} : ((game2_drawing_r && de) ? {game2_colr[11:8], 4'b0} : 8'b0));
                g_w = (ten_drawing_r && de) ? {ten_colr[7:4],4'b0} : ((one_drawing_r && de) ? {one_colr[7:4],4'b0} : ((game2_drawing_r && de) ? {game2_colr[7:4], 4'b0} : 8'b0));
                b_w = (ten_drawing_r && de) ? {ten_colr[3:0],4'b0} : ((one_drawing_r && de) ? {one_colr[3:0],4'b0} : ((game2_drawing_r && de) ? {game2_colr[3:0], 4'b0} : 8'b0));
                state_w = i_next ? S_GAME : S_MODET;
                sec_count_w = sec_count_r > 0 ? sec_count_r - 1 : 25'b1011111010111100001000000; //clk_25M
                deadline_w = deadline_r;
					 sec_modet_w = (sec_count_r == 0) ? sec_modet_r - 1 : sec_modet_r;
					 if(sec_modet_r == 0) begin
                    state_w = S_GAME;
						  count_w = 8'd255;
                end
					 else if(detect) begin
						  state_w = S_KILL;
                    count_w = 8'd255;
						  angle_w = i_pos;
					 end
                else begin
                    state_w = S_MODET;
                end
            end
            S_DIE: begin
					 r_w = (die_drawing_r && de) ? {die_colr[11:8], 4'b0} : (squid_drawing_r && de) ? {squid_colr[11:8], 4'b0} : (start_drawing_r && de) ? {start_colr[11:8], 4'b0} : 8'b0;
					 g_w = (die_drawing_r && de) ? {die_colr[7:4], 4'b0} : (squid_drawing_r && de) ? {squid_colr[7:4], 4'b0} : (start_drawing_r && de) ? {start_colr[7:4], 4'b0} : 8'b0;
					 b_w = (die_drawing_r && de) ? {die_colr[3:0], 4'b0} : (squid_drawing_r && de) ? {squid_colr[3:0], 4'b0} : (start_drawing_r && de) ? {start_colr[3:0], 4'b0} : 8'b0;
					 deadline_w = 7'd5;
					 count_w = count_r > 0 ? count_r - 1 : 0;
                if(i_next) begin
                    state_w = S_INST;
						  sec_count_w = 25'b1011111010111100001000000;
                end
                else begin
                    state_w = S_DIE;
                end
            end
				S_KILL: begin
					 r_w = (ten_drawing_r && de) ? {ten_colr[11:8],4'b0} : ((one_drawing_r && de) ? {one_colr[11:8],4'b0} : (~(game2_drawing_r && de) ? 8'b0 : (game2_pix == 4'd0 || game2_pix > 4'd8 || game2_pix==4'd2) ? {game2_colr[11:8], 4'b0} : 8'hD0));
                g_w = (ten_drawing_r && de) ? {ten_colr[7:4],4'b0} : ((one_drawing_r && de) ? {one_colr[7:4],4'b0} : (~(game2_drawing_r && de) ?  8'b0 : (game2_pix == 4'd0 || game2_pix > 4'd8 || game2_pix==4'd2) ? {game2_colr[7:4], 4'b0} : 8'b0));
                b_w = (ten_drawing_r && de) ? {ten_colr[3:0],4'b0} : ((one_drawing_r && de) ? {one_colr[3:0],4'b0} : (~(game2_drawing_r && de) ?  8'b0 : (game2_pix == 4'd0 || game2_pix > 4'd8 || game2_pix==4'd2) ? {game2_colr[3:0], 4'b0} : 8'b0));
                state_w = i_music_stop ? S_DIE : S_KILL ;
                sec_count_w = sec_count_r;
                deadline_w = deadline_r;
					 sec_modet_w = sec_modet_r;
					 count_w = i_music_stop ? 8'd255 : count_r > 0 ? count_r - 1 : 0;
					 angle_w = angle_r;
				end
            S_WIN: begin
					 r_w = (win_drawing_r && de) ? {win_colr[11:8], 4'b0} : (squid_drawing_r && de) ? {squid_colr[11:8], 4'b0} : (start_drawing_r && de) ? {start_colr[11:8], 4'b0} : 8'b0;
					 g_w = (win_drawing_r && de) ? {win_colr[7:4], 4'b0} : (squid_drawing_r && de) ? {squid_colr[7:4], 4'b0} : (start_drawing_r && de) ? {start_colr[7:4], 4'b0} : 8'b0;
					 b_w = (win_drawing_r && de) ? {win_colr[3:0], 4'b0} : (squid_drawing_r && de) ? {squid_colr[3:0], 4'b0} : (start_drawing_r && de) ? {start_colr[3:0], 4'b0} : 8'b0;
					 deadline_w = 7'd5;
					 count_w = count_r > 0 ? count_r - 1 : 0;
                if(i_next) begin
                    state_w = S_INST;
						  sec_count_w = 25'b1011111010111100001000000;
                end
                else begin
                    state_w = S_WIN;
                end
            end
        endcase
        
    end
    always_ff @(posedge i_clk_25 or negedge i_rst_n) begin
        if(!i_rst_n) begin
            state_r <= S_IDLE;
            sec_count_r <= 25'b1011111010111100001000000;
            deadline_r <= 7'd5;
				sec_modet_r <= 3'd6;
				count_r <= 0;
				angle_r <= 0;
        end
        else begin
            state_r <= state_w;
            sec_count_r <= sec_count_w;
            deadline_r <= deadline_w;
				sec_modet_r <= sec_modet_w;
				count_r <= count_w;
				angle_r <= angle_w;
        end
    end
endmodule