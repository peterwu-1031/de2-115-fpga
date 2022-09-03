/*
module Motion_Detection(
    input             iCLK,
    input             iRST_N,
    input      [9:0]  I_t,
    input      [9:0]  M_t,
    output     [9:0]  M_t_r,
    output reg [9:0]  oRed,
    output reg [9:0]  oGreen,
    output reg [9:0]  oBlue
);

reg  [9:0] diff;
always @(*) begin
    if (I_t > M_t) begin
        diff = (I_t - M_t);
    end
    else begin
        diff = (M_t - I_t);
    end
end

always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        oRed    <= 0;
        oGreen  <= 0;
        oBlue   <= 0;
    end
    else begin
        if (diff > 150) begin
            oRed    <= 0;
            oGreen  <= 0;
            oBlue   <= 0;
        end
        else begin
            oRed    <= diff;
            oGreen  <= diff;
            oBlue   <= diff;
        end
    end
end

endmodule
*/

module Motion_Detection(
    input             iCLK,
    input             iRST_N,
    input      [9:0]  I_t,
    input      [9:0]  M_t,
    input      [5:0]  V_t,
    output     [9:0]  M_t_o, // update M_t
    output     [5:0]  V_t_o, // update V_t
    output reg [9:0]  oRed,
    output reg [9:0]  oGreen,
    output reg [9:0]  oBlue
);

// wire and reg
wire [10:0] diff;
wire [10:0] diff_inv;
wire [1:0]  diff_most;
wire [15:0] diff_V;
wire [15:0] diff_V_inv;
wire [1:0]  diff_V_most;
wire [10:0] diff_E;
reg  [10:0] M_t_update;
reg  [6:0]  V_t_update;
reg  [5:0]  V_t_r;
reg  [10:0] O_t;
reg  [10:0] O_t_r;
wire [14:0] O_t_ex;
reg  [10:0] E_t;

assign M_t_o = M_t_update[9:0];
assign V_t_o = V_t_update[5:0];

assign diff = I_t - M_t;
assign diff_inv = M_t - I_t;
assign diff_most = {diff[10], diff_inv[10]};
// step 1:
always @(*) begin
    case(diff_most)
        2'b10:   M_t_update = (M_t > 1) ? (M_t - 1) : 0;
        2'b01:   M_t_update = M_t + 1;
        default: M_t_update = M_t;
    endcase
end
// step 2:
always @(*) begin
    if (diff[10]) begin
        O_t = diff_inv;
    end
    else begin
        O_t = diff;
    end
end
// step 3:
assign O_t_ex = {3'b0,O_t,1'b0};
assign diff_V = O_t_ex - {5'b0,V_t,4'b0};
assign diff_V_inv = {5'b0,V_t,4'b0} - O_t_ex;
assign diff_V_most = {diff_V[15], diff_V_inv[15]};
always @(*) begin
    case(diff_V_most)
        2'b10:   V_t_update = (V_t > 1) ? (V_t - 1) : 1;
        2'b01:   V_t_update = (V_t < 63) ? (V_t + 1) : 63;
        default: V_t_update = V_t;
    endcase
end
// step 4:
//assign E_t = (O_t[10:2] > 0) ? 10'd100 : 0;
assign diff_E = O_t_r - ({V_t_r,4'd10});
always @(*) begin
    if (diff_E[10]) begin
        E_t = 0;
    end
    else begin
        E_t = {1'b0,8'd255,2'b0};
    end
end


always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        oRed    <= 0;
        oGreen  <= 0;
        oBlue   <= 0;
        O_t_r   <= 0;
        V_t_r   <= 0;
    end
    else begin
        oRed    <= E_t;
        oGreen  <= E_t;
        oBlue   <= E_t;
        O_t_r   <= O_t;//O_t + {5'b10000};
        V_t_r   <= V_t;//(V_t < 63) ? (V_t + 1) : 63; //If you change it to V_t, there will be a bug. what the fuck???
    end
end

endmodule