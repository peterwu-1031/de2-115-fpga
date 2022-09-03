module CalcDir(
    input               iCLK,
    input               iRST_N,
    input       [12:0]  iH_Cont,
    input       [12:0]  iV_Cont,
    input       [9:0]   iColorVal,
    output  reg [2:0]   oDirection,
    output  reg         oMotion
);

`ifdef VGA_640x480p60
//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	96;
parameter	H_SYNC_BACK	=	48;
parameter	H_SYNC_ACT	=	640;	
parameter	H_SYNC_FRONT=	16;
parameter	H_SYNC_TOTAL=	800;

//	Vertical Parameter		( Line )
parameter	V_SYNC_CYC	=	2;
parameter	V_SYNC_BACK	=	33;
parameter	V_SYNC_ACT	=	480;	
parameter	V_SYNC_FRONT=	10;
parameter	V_SYNC_TOTAL=	525; 

`else
 // SVGA_800x600p60
////	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	128;         //Peli
parameter	H_SYNC_BACK	=	88;
parameter	H_SYNC_ACT	=	800;	
parameter	H_SYNC_FRONT=	40;
parameter	H_SYNC_TOTAL=	1056;
//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	4;
parameter	V_SYNC_BACK	=	23;
parameter	V_SYNC_ACT	=	600;	
parameter	V_SYNC_FRONT=	1;
parameter	V_SYNC_TOTAL=	628;

`endif
//	Start Offset
parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;

// leftmost -> middle -> rightmost
reg  [17:0] motion_count [0:7];

reg  [17:0] MostPixel;
reg  [2:0]  MostDirection;
reg  [2:0]  oDirection_w;

integer i;

wire [12:0] diff;
wire [6:0]  index;
wire index0,index1,index2,index3,index4,index5,index6;
assign diff = iH_Cont - X_START;
assign index6 =                   (diff < 114);
assign index5 = (114  <= diff) && (diff < 228);
assign index4 = (228  <= diff) && (diff < 342);
assign index3 = (342  <= diff) && (diff < 456);
assign index2 = (456  <= diff) && (diff < 572);
assign index1 = (572  <= diff) && (diff < 686);
assign index0 = (686  <= diff) && (diff < 800);
assign index = {index6,index5,index4,index3,index2,index1,index0};


always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        motion_count[0]  <= 0;
        motion_count[1]  <= 0;
        motion_count[2]  <= 0;
        motion_count[3]  <= 0;
        motion_count[4]  <= 0;
        motion_count[5]  <= 0;
        motion_count[6]  <= 0;
    end
    else begin
        if (iV_Cont < Y_START || iV_Cont >= Y_START+V_SYNC_ACT) begin
            motion_count[0]  <= 0;
            motion_count[1]  <= 0;
            motion_count[2]  <= 0;
            motion_count[3]  <= 0;
            motion_count[4]  <= 0;
            motion_count[5]  <= 0;
            motion_count[6]  <= 0;
        end
        else if (iH_Cont >= X_START && iH_Cont < X_START + H_SYNC_ACT) begin
            if (iColorVal > 200) begin
                case(index)
                    // right
                    7'b1000000: begin   
                        motion_count[0]  <= motion_count[0];
                        motion_count[1]  <= motion_count[1];
                        motion_count[2]  <= motion_count[2];
                        motion_count[3]  <= motion_count[3];
                        motion_count[4]  <= motion_count[4];
                        motion_count[5]  <= motion_count[5];
                        motion_count[6]  <= motion_count[6] + 1;
                    end
                    7'b0100000: begin   
                        motion_count[0]  <= motion_count[0];
                        motion_count[1]  <= motion_count[1];
                        motion_count[2]  <= motion_count[2];
                        motion_count[3]  <= motion_count[3];
                        motion_count[4]  <= motion_count[4];
                        motion_count[5]  <= motion_count[5] + 1;
                        motion_count[6]  <= motion_count[6];
                    end
                    7'b0010000: begin   
                        motion_count[0]  <= motion_count[0];
                        motion_count[1]  <= motion_count[1];
                        motion_count[2]  <= motion_count[2];
                        motion_count[3]  <= motion_count[3];
                        motion_count[4]  <= motion_count[4] + 1;
                        motion_count[5]  <= motion_count[5];
                        motion_count[6]  <= motion_count[6];
                    end
                    // middle
                    7'b0001000: begin   
                        motion_count[0]  <= motion_count[0];
                        motion_count[1]  <= motion_count[1];
                        motion_count[2]  <= motion_count[2];
                        motion_count[3]  <= motion_count[3] + 1;
                        motion_count[4]  <= motion_count[4];
                        motion_count[5]  <= motion_count[5];
                        motion_count[6]  <= motion_count[6];
                    end
                    // left
                    7'b0000100: begin   
                        motion_count[0]  <= motion_count[0];
                        motion_count[1]  <= motion_count[1];
                        motion_count[2]  <= motion_count[2] + 1;
                        motion_count[3]  <= motion_count[3];
                        motion_count[4]  <= motion_count[4];
                        motion_count[5]  <= motion_count[5];
                        motion_count[6]  <= motion_count[6];
                    end
                    7'b0000010: begin   
                        motion_count[0]  <= motion_count[0];
                        motion_count[1]  <= motion_count[1] + 1;
                        motion_count[2]  <= motion_count[2];
                        motion_count[3]  <= motion_count[3];
                        motion_count[4]  <= motion_count[4];
                        motion_count[5]  <= motion_count[5];
                        motion_count[6]  <= motion_count[6];
                    end
                    7'b0000001: begin   
                        motion_count[0]  <= motion_count[0] + 1;
                        motion_count[1]  <= motion_count[1];
                        motion_count[2]  <= motion_count[2];
                        motion_count[3]  <= motion_count[3];
                        motion_count[4]  <= motion_count[4];
                        motion_count[5]  <= motion_count[5];
                        motion_count[6]  <= motion_count[6];
                    end
                    default: begin   
                        motion_count[0]  <= motion_count[0];
                        motion_count[1]  <= motion_count[1];
                        motion_count[2]  <= motion_count[2];
                        motion_count[3]  <= motion_count[3];
                        motion_count[4]  <= motion_count[4];
                        motion_count[5]  <= motion_count[5];
                        motion_count[6]  <= motion_count[6];
                    end
                endcase
            end
            else begin
                motion_count[0]  <= motion_count[0];
                motion_count[1]  <= motion_count[1];
                motion_count[2]  <= motion_count[2];
                motion_count[3]  <= motion_count[3];
                motion_count[4]  <= motion_count[4];
                motion_count[5]  <= motion_count[5];
                motion_count[6]  <= motion_count[6];
            end
        end
        else begin
            motion_count[0]  <= motion_count[0];
            motion_count[1]  <= motion_count[1];
            motion_count[2]  <= motion_count[2];
            motion_count[3]  <= motion_count[3];
            motion_count[4]  <= motion_count[4];
            motion_count[5]  <= motion_count[5];
            motion_count[6]  <= motion_count[6];
        end
    end
end

always @(*) begin
    MostPixel = 0;
    MostDirection = 0;
    for (i = 0; i < 7; i = i + 1) begin
        if (MostPixel < motion_count[i]) begin
            MostPixel = motion_count[i];
            MostDirection = i;
        end
    end
    // If pixel is not enough, set it to default (none)
    if (MostPixel < 600) begin
        MostDirection = 7;
    end
end
always @(*) begin
    if ((iV_Cont == Y_START+V_SYNC_ACT - 1) && (iH_Cont == X_START + H_SYNC_ACT - 1)) begin
        oDirection_w  = MostDirection;
    end
    else begin
        oDirection_w  = oDirection;
    end
end

always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        oDirection  <= 7;
        oMotion     <= 0;
    end
    else begin
        oDirection  <= oDirection_w;
        oMotion     <= (oDirection_w != 7);
    end
end

endmodule