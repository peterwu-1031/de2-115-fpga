module sprite_1 #(
    parameter WIDTH = 8, 
    parameter HEIGHT = 8, 
    parameter SCALE_X = 1, 
    parameter SCALE_Y = 1, 
    parameter COLR_BITS = 4, 
    parameter CORDW = 16, 
    parameter ADDRW = 6
    )(
    input clk, 
    input rst_n,  
    input start, 
    input signed [15:0] sx, // horizontal screen position
    input signed [15:0] sprx, // horizontal sprite position
    input [COLR_BITS-1:0] data_in, 
    output [ADDRW-1:0] pos, 
    output [COLR_BITS-1:0] pix, 
    output drawing 
    );

    logic [COLR_BITS-1:0] pix_r, pix_w;
    logic drawing_r, drawing_w;
    logic [ADDRW-1:0] pos_r, pos_w;
    logic [$clog2(WIDTH)-1:0] ox_r, ox_w;
    logic [$clog2(HEIGHT)-1:0] oy_r, oy_w;
    logic [$clog2(SCALE_X)-1:0] cnt_x_r, cnt_x_w;
    logic [$clog2(SCALE_Y)-1:0] cnt_y_r, cnt_y_w;
    assign pos = pos_r;
    assign pix = pix_r;

    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam AWAIT_POS = 3'd2;
    localparam DRAW = 3'd3;
    localparam NEXT_LINE = 3'd4;
    localparam DONE = 3'd5;
    logic [3:0] state, state_next;
    logic last_pixel, last_line;

    // output pixel color when drawing
    always_comb pix_w = (state == DRAW) ? data_in : 0;

    // create status signals
    always_comb begin
        last_pixel = (ox_r == WIDTH - 1 && cnt_x_r == SCALE_X - 1);
        last_line  = (oy_r == HEIGHT - 1 && cnt_y_r == SCALE_Y - 1);
        drawing = (state == DRAW);
    end

    // FSM
    always_comb begin
        case (state)
            IDLE:      state_next = start ? START : IDLE;
            START:     state_next = AWAIT_POS;
            AWAIT_POS: state_next = (sx == sprx-2) ? DRAW : AWAIT_POS;
            DRAW:      state_next = !last_pixel ? DRAW : 
                                    (!last_line) ? NEXT_LINE : DONE;
            NEXT_LINE: state_next = AWAIT_POS;
            DONE:      state_next = IDLE;
            default:   state_next = IDLE;
        endcase
    end

    always_comb begin
        ox_w = ox_r;
        oy_w = oy_r;
        cnt_x_w = cnt_x_r;
        cnt_y_w = cnt_y_r;
        pos_w = pos_r;
        case (state)
            START: begin
                oy_w = 0;
                cnt_y_w = 0;
                pos_w = 0;
            end
            AWAIT_POS: begin
                ox_w = 0;
                cnt_x_w = 0;
            end
            DRAW: begin
                if (SCALE_X == 1 || cnt_x_r == SCALE_X - 1) begin
                    ox_w = ox_r + 1;
                    cnt_x_w = 0;
                    pos_w = pos_r + 1;
                end
                else cnt_x_w = cnt_x_r + 1;
            end
            NEXT_LINE: begin
                if (SCALE_Y == 1 || cnt_y_r == SCALE_Y - 1) begin
                    oy_w = oy_r + 1;
                    cnt_y_w = 0;
                end
                else begin
                    cnt_y_w = cnt_y_r + 1;
                    pos_w = pos_r - WIDTH;
                end
            end
        endcase
        
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pix_r <= 0;
            ox_r <= 0;
            oy_r <= 0;
            cnt_x_r <= 0;
            cnt_y_r <= 0;
            pos_r <= 0;
        end
        else begin
            state <= state_next;
            pix_r <= pix_w;
            ox_r <= ox_w;
            oy_r <= oy_w;
            cnt_x_r <= cnt_x_w;
            cnt_y_r <= cnt_y_w;
            pos_r <= pos_w;
        end
    end

endmodule