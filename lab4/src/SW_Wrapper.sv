`define REF_MAX_LENGTH              128
`define READ_MAX_LENGTH             128

`define REF_LENGTH                  128
`define READ_LENGTH                 128

//* Score parameters
`define DP_SW_SCORE_BITWIDTH        10

`define CONST_MATCH_SCORE           1
`define CONST_MISMATCH_SCORE        -4
`define CONST_GAP_OPEN              -6
`define CONST_GAP_EXTEND            -1

module SW_Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_QUERY_RX   = 0;
localparam S_READ       = 1;
localparam S_WAIT_READY = 2;
localparam S_CALCULATE  = 3;
localparam S_QUERY_TX   = 4;
localparam S_WRITE      = 5;
localparam S_DONE       = 6;

logic [255:0] read_r, read_w, ref_r, ref_w;
logic [247:0] ans_r, ans_w;
logic [  9:0] core_score;   
logic [  7:0] read_l, ref_l;
logic [  6:0] core_col, core_row;
logic [  2:0] state_r, state_w;
logic [  6:0] bytes_counter_r, bytes_counter_w;
logic [  4:0] avm_address_r, avm_address_w;
logic         avm_read_r, avm_read_w, avm_write_r, avm_write_w;
logic         core_valid, core_ready, valid, ready;

assign avm_address   = avm_address_r;
assign avm_read      = avm_read_r;
assign avm_write     = avm_write_r;
assign avm_writedata = ans_r[247-:8];

// Remember to complete the port connection
SW_core sw_core(
    .clk				(avm_clk),
    .rst				(avm_rst),

	.o_ready			(core_ready),
    .i_valid			(valid),
    .i_sequence_ref		(ref_r),
    .i_sequence_read	(read_r),
    .i_seq_ref_length	(ref_l),
    .i_seq_read_length	(read_l),
    
    .i_ready			(ready),
    .o_valid			(core_valid),
    .o_alignment_score	(core_score),
    .o_column			(core_col),
    .o_row				(core_row)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

// TODO
always_comb begin
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    avm_address_w = avm_address_r;
    ref_l = 8'd128;
    read_l = 8'd128;
    case(state_r) 
        S_QUERY_RX: begin
            valid  = 0;
            ready  = 0;
            ref_w  = ref_r;
            read_w = read_r;
            ans_w  = ans_r;
            if(~avm_waitrequest & avm_readdata[RX_OK_BIT]) begin
                StartRead(RX_BASE);
                state_w = S_READ;
                bytes_counter_w = bytes_counter_r + 1;
            end
            else begin
                state_w = state_r;
                bytes_counter_w = bytes_counter_r;
            end
        end
        S_READ: begin
            valid = 0;
            ready = 0;
            ans_w = ans_r;
            bytes_counter_w = bytes_counter_r;     
            if(~avm_waitrequest) begin
                StartRead(STATUS_BASE);
                if(bytes_counter_r <= 7'd32) begin
                    ref_w   = (ref_r << 8) + avm_readdata[7:0];
                    read_w  = read_r;
                    state_w = S_QUERY_RX;
                end
                else if(bytes_counter_r <= 7'd63) begin
                    ref_w   = ref_r;
                    read_w  = (read_r << 8) + avm_readdata[7:0];
                    state_w = S_QUERY_RX;
                end
                else begin
                    ref_w   = ref_r;
                    read_w  = (read_r << 8) + avm_readdata[7:0];
                    state_w = S_WAIT_READY;
                end
                
            end
            else begin
                ref_w   = ref_r;
                read_w  = read_r;
                state_w = state_r;
            end
        end
        S_WAIT_READY: begin
            ref_w   = ref_r;
            read_w  = read_r;
            ans_w   = ans_r;
            valid   = 1;
            ready   = 0;
            state_w = core_ready ? S_CALCULATE : state_r;
            bytes_counter_w = 0;
        end
        S_CALCULATE: begin
            ref_w  = ref_r;
            read_w = read_r;
            valid  = 0;
            ready  = 0;
            bytes_counter_w = 0;
            if(~avm_waitrequest & core_valid) begin
                StartRead(STATUS_BASE);
                state_w = S_QUERY_TX;
                ans_w   = {113'd0, core_col, 57'd0, core_row, 54'd0, core_score}; 
            end
            else begin
                state_w = state_r;
                ans_w   = ans_r;
            end
        end
        S_QUERY_TX: begin
            valid  = 0;
            ready  = 0;
            ref_w  = ref_r;
            read_w = read_r;
            ans_w  = ans_r;
            if(~avm_waitrequest & avm_readdata[TX_OK_BIT]) begin
                StartWrite(TX_BASE);
                state_w = S_WRITE;
                bytes_counter_w = bytes_counter_r + 1;
            end
            else begin
                state_w = state_r;
                bytes_counter_w = bytes_counter_r;
            end
        end
        S_WRITE: begin
            valid  = 0;
            ready  = 0;
            ref_w  = ref_r;
            read_w = read_r;
            bytes_counter_w = bytes_counter_r;
            if(bytes_counter_r <= 6'd30) begin
                if(~avm_waitrequest) begin
                    StartRead(STATUS_BASE);
                    ans_w   = ans_r << 8;
                    state_w = S_QUERY_TX; 
                end
                else begin
                    ans_w   = ans_r;
                    state_w = state_r;
                end
            end
            else begin
                if(~avm_waitrequest) begin
                    StartRead(STATUS_BASE);
                    ans_w   = ans_r << 8;
                    state_w = S_DONE;
                end
                else begin
                    ans_w   = ans_r;
                    state_w = state_r;
                end
            end
        end
        S_DONE: begin
            ref_w   = 0;
            read_w  = 0;
            valid   = 0;
            ready   = 1;
            ans_w   = 0;
            state_w = S_QUERY_RX;
            bytes_counter_w = 0;
        end
    endcase
end

// TODO
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        ref_r           <= 0;
        read_r          <= 0;
        ans_r           <= 0;
        avm_address_r   <= STATUS_BASE;
        avm_read_r      <= 1;
        avm_write_r     <= 0;
        state_r         <= S_QUERY_RX;
        bytes_counter_r <= 0;
    end
    else begin
        ref_r           <= ref_w;
        read_r          <= read_w;
        ans_r           <= ans_w;
        avm_address_r   <= avm_address_w;
        avm_read_r      <= avm_read_w;
        avm_write_r     <= avm_write_w;
        state_r         <= state_w;
        bytes_counter_r <= bytes_counter_w;
    end
end

endmodule
