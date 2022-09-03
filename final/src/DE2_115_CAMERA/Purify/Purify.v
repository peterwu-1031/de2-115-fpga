module Purify(
    input            iCLK,
    input            iRST_N,
    input      [9:0] idata,
    input            iDVAL,
    output reg [9:0] odata
);

wire    [7:0]   Row0, Row1, Row2;

reg     [7:0]   Row0_prev1, Row0_prev2;
reg     [7:0]   Row1_prev1, Row1_prev2;
reg     [7:0]   Row2_prev1, Row2_prev2;

always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        odata <= 0;
    end
    else begin
        if (Row0 == 0 && Row1 == 0 && Row2 == 0 && Row0_prev1 == 0 && Row2_prev1 == 0 && Row0_prev2 == 0 && Row1_prev2 == 0 && Row2_prev2 == 0) begin
            odata <= 0;
        end
        else begin
            odata <= (Row1_prev1 << 2);
        end
    end
end

always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        Row0_prev1  <= 0;
        Row0_prev2  <= 0;
        Row1_prev1  <= 0;
        Row1_prev2  <= 0;
        Row2_prev1  <= 0;
        Row2_prev2  <= 0;
    end
    else begin
        Row0_prev1  <= Row0;
        Row0_prev2  <= Row0_prev1;
        Row1_prev1  <= Row1;
        Row1_prev2  <= Row1_prev1;
        Row2_prev1  <= Row2;
        Row2_prev2  <= Row2_prev1;
    end
end

Purify_buffer_3 buf3_1(
    .iCLK(iCLK),
    .iRST_N(iRST_N),
    .iCLKen(iDVAL),
    .idata(idata[9:2]),
    .oRow0(Row0),
    .oRow1(Row1),
    .oRow2(Row2)
);


endmodule