module LCD1602 (
    input        clk,
    input        i_rst_n,
    input  [2:0] i_state,
    output       LCD_EN,
    output       LCD_RS,
    output [7:0] LCD_DATA
);

localparam TIME_20MS = 1_000_000; //初始化
logic [19:0] cnt_20ms;
logic        delay_done;
always@(posedge clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        cnt_20ms <= 1'b0;
    end
    else if (cnt_20ms == TIME_20MS-1'b1) begin
        cnt_20ms <= cnt_20ms;
    end
    else begin 
        cnt_20ms <= cnt_20ms + 1'b1 ;
    end
end
assign delay_done = (cnt_20ms == TIME_20MS - 1'b1) ? 1'b1 : 1'b0;

localparam TIME_500HZ = 100_000; //工作周期
logic [19:0] cnt_500hz;
logic        write_flag;
always@(posedge clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        cnt_500hz <= 1'b0;
    end
    else if (delay_done) begin
        if(cnt_500hz == TIME_500HZ-1'b1) begin
            cnt_500hz <= 1'b0;
        end
        else begin
            cnt_500hz <= cnt_500hz + 1'b1;
        end
    end
    else begin
        cnt_500hz <= 1'b0;
    end
end
assign LCD_EN     = (cnt_500hz > (TIME_500HZ - 1'b1) / 2) ? 1'b0 : 1'b1;
assign write_flag = (cnt_500hz == TIME_500HZ - 1'b1) ? 1'b1 : 1'b0;

localparam IDLE         = 8'd1;
localparam SET_FUNCTION = 8'd2;
localparam DISP_OFF     = 8'd3;
localparam DISP_CLEAR   = 8'd4;
localparam ENTRY_MODE   = 8'd5;
localparam DISP_ON      = 8'd6;
localparam ROW1_ADDR    = 8'd7;
localparam ROW1_0       = 8'd8;
localparam ROW1_1       = 8'd9;
localparam ROW1_2       = 8'd10;
localparam ROW1_3       = 8'd11;
localparam ROW1_4       = 8'd12;
localparam ROW1_5       = 8'd13;
localparam ROW1_6       = 8'd14;
localparam ROW1_7       = 8'd15;
localparam ROW1_8       = 8'd16;
localparam ROW1_9       = 8'd17;
localparam ROW1_A       = 8'd18;
localparam ROW1_B       = 8'd19;
localparam ROW1_C       = 8'd20;
localparam ROW1_D       = 8'd21;
localparam ROW1_E       = 8'd22;
localparam ROW1_F       = 8'd23;
localparam ROW2_ADDR    = 8'd24;
localparam ROW2_0       = 8'd25;
localparam ROW2_1       = 8'd26;
localparam ROW2_2       = 8'd27;
localparam ROW2_3       = 8'd28;
localparam ROW2_4       = 8'd29;
localparam ROW2_5       = 8'd30;
localparam ROW2_6       = 8'd31;
localparam ROW2_7       = 8'd32;
localparam ROW2_8       = 8'd33;
localparam ROW2_9       = 8'd34;
localparam ROW2_A       = 8'd35;
localparam ROW2_B       = 8'd36;
localparam ROW2_C       = 8'd37;
localparam ROW2_D       = 8'd38;
localparam ROW2_E       = 8'd39;
localparam ROW2_F       = 8'd40;

logic [5:0] state, state_next;
always_comb begin
	  if (state == ROW2_F) begin
			state_next = ROW1_ADDR;
	  end
	  else begin
			state_next = state + 1;
	  end
end
always@(posedge clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        state <= IDLE;
    end
    else if (write_flag) begin
        state <= state_next;
    end
    else begin
        state <= state;
    end
end

always@(posedge clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        LCD_RS <= 1'b0; //為0時輸入指令,為1時輸入數據
    end
    else if (write_flag) begin
        if(((state >= SET_FUNCTION) & (state <= DISP_ON)) | (state == ROW1_ADDR) | (state == ROW2_ADDR)) begin
            LCD_RS <= 1'b0; 
        end
        else begin
            LCD_RS <= 1'b1;
        end
    end
    else begin
        LCD_RS <= LCD_RS;
    end
end

logic [127:0] row_1;
logic [127:0] row_2;
localparam S_IDLE       = 3'd0;
localparam S_I2C        = 3'd1;
localparam S_RECD       = 3'd2;
localparam S_RECD_PAUSE = 3'd3;
localparam S_PLAY       = 3'd4;
localparam S_PLAY_PAUSE = 3'd5;
always_comb begin
    case (i_state)
        S_I2C: begin
            row_1 = "     TEAM09     ";
            row_2 = "  WAIT TO START ";
        end
        S_PLAY: begin 
            row_1 = "   KEY0: PAUSE  ";
            row_2 = "   KEY2: STOP   "; 
        end
        S_RECD: begin
            row_1 = "   KEY0: PAUSE  ";
            row_2 = "   KEY2: STOP   "; 
        end
        S_RECD_PAUSE: begin
            row_1 = " KEY1: CONTINUE ";
            row_2 = " KEY2: STOP     ";
        end
        S_PLAY_PAUSE: begin
            row_1 = " KEY1: CONTINUE ";
            row_2 = " KEY2: STOP     ";
        end
        default: begin
            row_1 = "  KEY0: PLAY    ";
            row_2 = "  KEY1: RECORD  ";
        end
    endcase
end

always@(posedge clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        LCD_DATA <= 1'b0;
    end
    else if (write_flag) begin
        case (state)
            IDLE:         begin LCD_DATA <= 8'hxx; end
            SET_FUNCTION: begin LCD_DATA <= 8'h38; end
            DISP_OFF:     begin LCD_DATA <= 8'h08; end
            DISP_CLEAR:   begin LCD_DATA <= 8'h01; end
            ENTRY_MODE:   begin LCD_DATA <= 8'h06; end
            DISP_ON:      begin LCD_DATA <= 8'h0c; end
            ROW1_ADDR:    begin LCD_DATA <= 8'h80; end
            //將輸入的row以每8-bit拆分
            ROW1_0:       begin LCD_DATA <= row_1[127:120]; end
            ROW1_1:       begin LCD_DATA <= row_1[119:112]; end
            ROW1_2:       begin LCD_DATA <= row_1[111:104]; end
            ROW1_3:       begin LCD_DATA <= row_1[103: 96]; end
            ROW1_4:       begin LCD_DATA <= row_1[ 95: 88]; end
            ROW1_5:       begin LCD_DATA <= row_1[ 87: 80]; end
            ROW1_6:       begin LCD_DATA <= row_1[ 79: 72]; end
            ROW1_7:       begin LCD_DATA <= row_1[ 71: 64]; end
            ROW1_8:       begin LCD_DATA <= row_1[ 63: 56]; end
            ROW1_9:       begin LCD_DATA <= row_1[ 55: 48]; end
            ROW1_A:       begin LCD_DATA <= row_1[ 47: 40]; end
            ROW1_B:       begin LCD_DATA <= row_1[ 39: 32]; end
            ROW1_C:       begin LCD_DATA <= row_1[ 31: 24]; end
            ROW1_D:       begin LCD_DATA <= row_1[ 23: 16]; end
            ROW1_E:       begin LCD_DATA <= row_1[ 15:  8]; end
            ROW1_F:       begin LCD_DATA <= row_1[  7:  0]; end
            ROW2_ADDR:    begin LCD_DATA <= 8'hc0;          end
            ROW2_0:       begin LCD_DATA <= row_2[127:120]; end
            ROW2_1:       begin LCD_DATA <= row_2[119:112]; end
            ROW2_2:       begin LCD_DATA <= row_2[111:104]; end
            ROW2_3:       begin LCD_DATA <= row_2[103: 96]; end
            ROW2_4:       begin LCD_DATA <= row_2[ 95: 88]; end
            ROW2_5:       begin LCD_DATA <= row_2[ 87: 80]; end
            ROW2_6:       begin LCD_DATA <= row_2[ 79: 72]; end
            ROW2_7:       begin LCD_DATA <= row_2[ 71: 64]; end
            ROW2_8:       begin LCD_DATA <= row_2[ 63: 56]; end
            ROW2_9:       begin LCD_DATA <= row_2[ 55: 48]; end
            ROW2_A:       begin LCD_DATA <= row_2[ 47: 40]; end
            ROW2_B:       begin LCD_DATA <= row_2[ 39: 32]; end
            ROW2_C:       begin LCD_DATA <= row_2[ 31: 24]; end
            ROW2_D:       begin LCD_DATA <= row_2[ 23: 16]; end
            ROW2_E:       begin LCD_DATA <= row_2[ 15:  8]; end
            ROW2_F:       begin LCD_DATA <= row_2[  7:  0]; end
        endcase
    end
    else begin 
        LCD_DATA <= LCD_DATA;
    end
end
endmodule