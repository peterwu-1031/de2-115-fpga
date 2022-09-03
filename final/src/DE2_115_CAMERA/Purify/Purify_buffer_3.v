module Purify_buffer_3(
    input         iCLK,
    input         iRST_N,
    input         iCLKen,
    input  [7:0]  idata,
    output [7:0]  oRow0,
    output [7:0]  oRow1,
    output [7:0]  oRow2
);

assign oRow2 = idata;

Purify_Line_Buffer buf0(
	.aclr(!iRST_N),
    .clken(iCLKen),
	.clock(iCLK),
	.shiftin(idata),
	.shiftout(),
	.taps0x(oRow1),
	.taps1x(oRow0),
    .taps2x()
);

endmodule