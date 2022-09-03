module display (
    input clk_25M, 
    input rst_n, 
    output VGA_BLANK_N, 
    output VGA_HS, 
    output VGA_VS, 
    output VGA_SYNC_N, 
    output de, 
    output line, 
    output signed [15:0] sx, 
    output signed [15:0] sy, 
    input i_start_display
    );

    localparam H_FRONT  =   16;
    localparam H_SYNC   =   96;
    localparam H_BACK   =   80;
    localparam H_ACT    =   640;
    localparam signed H_START = 0 - H_FRONT - H_SYNC - H_BACK; // horizontal start
    localparam signed HS_START = H_START + H_FRONT; // sync start
    localparam signed HS_END = HS_START + H_SYNC; // sync end
    localparam signed HA_START = 0; // active start
    localparam signed HA_END = H_ACT; // active end
    localparam V_FRONT  =   10;
    localparam V_SYNC   =   2;
    localparam V_BACK   =   33;
    localparam V_ACT    =   480;
    localparam signed V_START = 0 - V_FRONT - V_SYNC - V_BACK; // vertical start
    localparam signed VS_START = V_START + V_FRONT; // sync start
    localparam signed VS_END = VS_START + V_SYNC; // sync end
    localparam signed VA_START = 0; // active start
    localparam signed VA_END = V_ACT; // active end

    localparam S_IDLE = 1'b0;
    localparam S_DISPLAY = 1'b1;

    logic signed [15:0] x, y; // screen position
    logic hs_r, hs_w, vs_r, vs_w, de_r, de_w, line_r, line_w;
    logic signed [15:0] sx_r, sx_w, sy_r, sy_w;
    logic state_r, state_w;

    assign VGA_SYNC_N = 1'b0;
    assign VGA_BLANK_N = de_r;
    assign VGA_HS = hs_r;
    assign VGA_VS = vs_r;
    assign line = line_r;
    assign de = de_r;
    assign sx = sx_r;
    assign sy = sy_r;

    always_comb begin
        if (i_start_display) state_w = S_DISPLAY;
        else state_w = state_r;
    end

    always_comb begin
        case (state_r)
            S_IDLE: begin
                hs_w = 1'b1;
                sx_w = H_START;
                sy_w = V_START;
                vs_w = 1'b1;
                de_w    = (sy_r >= VA_START && sx_r >= HA_START);
                line_w  = (sy_r >= VA_START && sx_r == H_START);
            end
            S_DISPLAY: begin
                hs_w = ~(sx_r >= H_START && sx_r < H_START+H_SYNC);
                vs_w = ~(sy_r >= V_START && sy_r < V_START+V_SYNC);
                de_w    = (sy_r >= VA_START-V_FRONT && sx_r >= HA_START-H_FRONT); // modified
                line_w  = (sy_r >= VA_START && sx_r == H_START);
                if (sx_r == HA_END) begin
                    sx_w = H_START;
                end
                else begin
                    sx_w = sx_r + 1;
                end
                if (sy_r == VA_END) begin
                    sy_w = V_START;
                end
                else if (sx_r == HA_END) begin
                    sy_w = sy_r + 1;
                end
                else begin
                    sy_w = sy_r;
                end
            end
        endcase
    end

    always_ff @(posedge clk_25M or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= S_IDLE;
            sx_r <= H_START;
            sy_r <= V_START; 
				hs_r <= 1'b1;
            vs_r <= 1'b1;
				line_r  <= 1'b0;
				de_r    <= 1'b0;
        end
        else begin
            state_r <= state_w;
            hs_r <= hs_w;
            vs_r <= vs_w;
            de_r    <= de_w;
            line_r  <= line_w;
            sx_r <= sx_w;
            sy_r <= sy_w; 
        end
    end

endmodule