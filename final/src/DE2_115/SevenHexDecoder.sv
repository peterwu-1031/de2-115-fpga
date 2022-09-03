module SevenHexDecoder (
	input        [3:0] i_hex,
	output logic [6:0] o_seven
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
parameter D0 = 7'b1000000;
parameter D1 = 7'b1111001;
parameter D2 = 7'b0100100;
parameter D3 = 7'b0110000;
parameter D4 = 7'b0011001;
parameter D5 = 7'b0010010;
parameter D6 = 7'b0000010;
parameter D7 = 7'b1011000;
parameter D8 = 7'b0000000;
parameter D9 = 7'b0010000;
parameter DA = 7'b0001000;
parameter DB = 7'b0000011;
parameter DC = 7'b1000110;
parameter DD = 7'b0100001;
parameter DE = 7'b0000110;
parameter DF = 7'b0001110;
always_comb begin
	case(i_hex)
		4'h0: o_seven = D0;
		4'h1: o_seven = D1;
		4'h2: o_seven = D2;
		4'h3: o_seven = D3;
		4'h4: o_seven = D4;
		4'h5: o_seven = D5;
		4'h6: o_seven = D6;
		4'h7: o_seven = D7;
		4'h8: o_seven = D8;
		4'h9: o_seven = D9;
		4'ha: o_seven = DA;
		4'hb: o_seven = DB;
		4'hc: o_seven = DC;
		4'hd: o_seven = DD;
		4'he: o_seven = DE;
		4'hf: o_seven = DF;
	endcase
end

endmodule
