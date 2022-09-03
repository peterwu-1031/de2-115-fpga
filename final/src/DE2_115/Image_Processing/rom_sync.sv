module rom_sync #(
	parameter WIDTH=8,
	parameter DEPTH=256, 
	parameter INIT_F="", 
	parameter ADDRW=$clog2(DEPTH)
	)(
    input wire logic clk, 
    input wire logic [ADDRW-1:0] addr, 
    output     logic [WIDTH-1:0] data
    );

    logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $readmemh(INIT_F, memory);
        end
    end

    always_ff @(posedge clk) begin
        data <= memory[addr];
    end 
endmodule