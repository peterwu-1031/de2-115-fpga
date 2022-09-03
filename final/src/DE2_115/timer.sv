module timer (
	 input i_clk_25,
	 input i_rst_n,
    input signed [15:0] sx,
    input signed [15:0] sy,
    input line, 
    input [3:0] ten,
    input [3:0] one,
    output ten_drawing_r,
    output one_drawing_r,
    output [11:0] ten_colr,
    output [11:0] one_colr
);

    logic [11:0] ten_sec_colr[0:9], one_sec_colr[0:9];
	 logic [3:0] ten_sec_pix[0:9], one_sec_pix[0:9];
    logic ten_sec_drawing_r[0:9], one_sec_drawing_r[0:9];
    logic ten_drawing_w, one_drawing_w;
    logic [11:0] ten_colr_w, one_colr_w;
    assign ten_drawing_r = ten_drawing_w;
    assign one_drawing_r = one_drawing_w;
    assign ten_colr = ten_colr_w;
    assign one_colr = one_colr_w;
	 item #(
		.FILE("0.mem"), 
		.PALETTE_FILE("0_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten0 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[0]),
		.colr(ten_sec_colr[0]), 
		.drawing_r(ten_sec_drawing_r[0])
	 );
	 item #(
		.FILE("1.mem"), 
		.PALETTE_FILE("1_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten1 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[1]),	
		.colr(ten_sec_colr[1]), 
		.drawing_r(ten_sec_drawing_r[1])
	 );
	 item #(
		.FILE("2.mem"), 
		.PALETTE_FILE("2_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten2 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[2]),	
		.colr(ten_sec_colr[2]), 
		.drawing_r(ten_sec_drawing_r[2])
	 );
	 item #(
		.FILE("3.mem"), 
		.PALETTE_FILE("3_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten3 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[3]),	
		.colr(ten_sec_colr[3]), 
		.drawing_r(ten_sec_drawing_r[3])
	 );
	 item #(
		.FILE("4.mem"), 
		.PALETTE_FILE("4_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten4 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[4]),	
		.colr(ten_sec_colr[4]), 
		.drawing_r(ten_sec_drawing_r[4])
	 );
	 item #(
		.FILE("5.mem"), 
		.PALETTE_FILE("5_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten5 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[5]),	
		.colr(ten_sec_colr[5]), 
		.drawing_r(ten_sec_drawing_r[5])
	 );
	 item #(
		.FILE("6.mem"), 
		.PALETTE_FILE("6_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten6 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[6]),	
		.colr(ten_sec_colr[6]), 
		.drawing_r(ten_sec_drawing_r[6])
	 );
	 item #(
		.FILE("7.mem"), 
		.PALETTE_FILE("7_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten7 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[7]),	
		.colr(ten_sec_colr[7]), 
		.drawing_r(ten_sec_drawing_r[7])
	 );
	 item #(
		.FILE("8.mem"), 
		.PALETTE_FILE("8_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten8 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line),
		.pix(ten_sec_pix[8]),	
		.colr(ten_sec_colr[8]), 
		.drawing_r(ten_sec_drawing_r[8])
	 );
	 item #(
		.FILE("9.mem"), 
		.PALETTE_FILE("9_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_ten9 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(0), 
		.y_init(0), 
		.line(line), 
		.pix(ten_sec_pix[9]),
		.colr(ten_sec_colr[9]), 
		.drawing_r(ten_sec_drawing_r[9])
	 );
	 item #(
		.FILE("0.mem"), 
		.PALETTE_FILE("0_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one0 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[0]),	
	   .colr(one_sec_colr[0]), 
		.drawing_r(one_sec_drawing_r[0])
	 );
	 item #(
		.FILE("1.mem"), 
		.PALETTE_FILE("1_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one1 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[1]),	
	   .colr(one_sec_colr[1]), 
		.drawing_r(one_sec_drawing_r[1])
	 );
	 item #(
		.FILE("2.mem"), 
		.PALETTE_FILE("2_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one2 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line), 
		.pix(one_sec_pix[2]),
	   .colr(one_sec_colr[2]), 
		.drawing_r(one_sec_drawing_r[2])
	 );
	 item #(
		.FILE("3.mem"), 
		.PALETTE_FILE("3_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one3 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[3]),	
	   .colr(one_sec_colr[3]), 
		.drawing_r(one_sec_drawing_r[3])
	 );
	 item #(
		.FILE("4.mem"), 
		.PALETTE_FILE("4_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one4 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[4]),	
	   .colr(one_sec_colr[4]), 
		.drawing_r(one_sec_drawing_r[4])
	 );
	 item #(
		.FILE("5.mem"), 
		.PALETTE_FILE("5_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one5 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[5]),	
	   .colr(one_sec_colr[5]), 
		.drawing_r(one_sec_drawing_r[5])
	 );
	 item #(
		.FILE("6.mem"), 
		.PALETTE_FILE("6_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one6 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[6]),	
	   .colr(one_sec_colr[6]), 
		.drawing_r(one_sec_drawing_r[6])
	 );
	 item #(
		.FILE("7.mem"), 
		.PALETTE_FILE("7_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one7 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[7]),	
	   .colr(one_sec_colr[7]), 
		.drawing_r(one_sec_drawing_r[7])
	 );
	 item #(
		.FILE("8.mem"), 
		.PALETTE_FILE("8_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one8 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[8]),	
	   .colr(one_sec_colr[8]), 
		.drawing_r(one_sec_drawing_r[8])
	 );
	 item #(
		.FILE("9.mem"), 
		.PALETTE_FILE("9_palette.mem"), 
		.WIDTH(80), 
		.HEIGHT(86)
	 ) sec_one9 (
		.i_clk_25(i_clk_25), 
		.i_rst_n(i_rst_n), 
		.sx(sx), 
		.sy(sy), 
		.x_init(80), 
		.y_init(0), 
		.line(line),
		.pix(one_sec_pix[9]),	
	   .colr(one_sec_colr[9]), 
		.drawing_r(one_sec_drawing_r[9])
	 );
	 
    always_comb begin
        case(ten)
            4'd0: begin
                ten_drawing_w = ten_sec_drawing_r[0];
                ten_colr_w = ten_sec_colr[0];
            end
            4'd1: begin
                ten_drawing_w = ten_sec_drawing_r[1];
                ten_colr_w = ten_sec_colr[1];
            end
            4'd2: begin
                ten_drawing_w = ten_sec_drawing_r[2];
                ten_colr_w = ten_sec_colr[2];
            end
            4'd3: begin
                ten_drawing_w = ten_sec_drawing_r[3];
                ten_colr_w = ten_sec_colr[3];
            end
            4'd4: begin
                ten_drawing_w = ten_sec_drawing_r[4];
                ten_colr_w = ten_sec_colr[4];
            end
            4'd5: begin
                ten_drawing_w = ten_sec_drawing_r[5];
                ten_colr_w = ten_sec_colr[5];
            end
            4'd6: begin
                ten_drawing_w = ten_sec_drawing_r[6];
                ten_colr_w = ten_sec_colr[6];
            end
            4'd7: begin
                ten_drawing_w = ten_sec_drawing_r[7];
                ten_colr_w = ten_sec_colr[7];
            end
            4'd8: begin
                ten_drawing_w = ten_sec_drawing_r[8];
                ten_colr_w = ten_sec_colr[8];
            end
            4'd9: begin
                ten_drawing_w = ten_sec_drawing_r[9];
                ten_colr_w = ten_sec_colr[9];
            end
				default: begin
					 ten_drawing_w = 0;
                ten_colr_w = 0;
				end
        endcase
    end
    always_comb begin
        case(one)
            4'd0: begin
                one_drawing_w = one_sec_drawing_r[0];
                one_colr_w = one_sec_colr[0];
            end
            4'd1: begin
                one_drawing_w = one_sec_drawing_r[1];
                one_colr_w = one_sec_colr[1];
            end
            4'd2: begin
                one_drawing_w = one_sec_drawing_r[2];
                one_colr_w = one_sec_colr[2];
            end
            4'd3: begin
                one_drawing_w = one_sec_drawing_r[3];
                one_colr_w = one_sec_colr[3];
            end
            4'd4: begin
                one_drawing_w = one_sec_drawing_r[4];
                one_colr_w = one_sec_colr[4];
            end
            4'd5: begin
                one_drawing_w = one_sec_drawing_r[5];
                one_colr_w = one_sec_colr[5];
            end
            4'd6: begin
                one_drawing_w = one_sec_drawing_r[6];
                one_colr_w = one_sec_colr[6];
            end
            4'd7: begin
                one_drawing_w = one_sec_drawing_r[7];
                one_colr_w = one_sec_colr[7];
            end
            4'd8: begin
                one_drawing_w = one_sec_drawing_r[8];
                one_colr_w = one_sec_colr[8];
            end
            4'd9: begin
                one_drawing_w = one_sec_drawing_r[9];
                one_colr_w = one_sec_colr[9];
            end
				default: begin
					 one_drawing_w = 0;
                one_colr_w = 0;
				end
        endcase
    end
endmodule