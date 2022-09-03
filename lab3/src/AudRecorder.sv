module AudRecorder(
    input i_rst_n,
    input i_clk,
    input i_lrc,
    input i_start,
    input i_pause,
    input i_stop,
    input i_data,
    output [19:0] o_address,
    output [15:0] o_data
);
localparam S_IDLE = 3'd0;
localparam S_WAIT = 3'd1;
localparam S_RECORD = 3'd2;
localparam S_PAUSE = 3'd3;
localparam S_CLEAN = 3'd4;

logic [19:0] addr_r, addr_w;
logic [15:0] data_r, data_w;
logic [2:0] state_r, state_w;
logic [4:0] counter_r, counter_w;
logic [19:0] c_count_r, c_count_w;

assign o_address = addr_w;
assign o_data = data_w;
always_comb begin
	data_w = data_r;
	counter_w = counter_r;
	c_count_w = c_count_r;	
    case (state_r)
        S_IDLE : begin
				data_w = 0;	
            addr_w = 0;
            if(i_start) begin
                state_w = S_CLEAN;
            end
            else begin
                state_w = S_IDLE;
            end
        end 
        S_WAIT : begin
            addr_w = addr_r;
            if(i_lrc) begin
                state_w = S_RECORD;
                counter_w = 5'd0;
            end
            else if(i_pause) begin
                state_w = S_PAUSE;
                counter_w = counter_r;
            end
            else if(i_stop) begin
                state_w = S_IDLE;
                counter_w = counter_r;
            end
            else begin
                state_w = S_WAIT;
                counter_w = counter_r;
            end
            
        end
        S_RECORD : begin
            if(i_stop) begin
                addr_w = addr_r;
                state_w = S_IDLE;
            end
            else if(i_pause) begin
                addr_w = addr_r;
                state_w = S_PAUSE;
            end
            else if(counter_r < 5'd16) begin
                addr_w = addr_r;
                state_w = S_RECORD;
                counter_w = counter_r + 1;
                data_w = {data_r[14:0], i_data};
            end
            else if(~i_lrc) begin
                addr_w = addr_r + 1;
                counter_w = 0;
                state_w = S_WAIT;
                data_w = data_r;
            end
            else begin
                addr_w = addr_r;
                data_w = data_r;
                counter_w = counter_r;
                state_w = state_r;
                    
            end
        end
        S_PAUSE : begin
            addr_w = addr_r;
            counter_w = 0;
            data_w = 0;
            if(i_stop) begin
                state_w = S_IDLE;
            end
            else if(i_start) begin
                state_w = S_WAIT;
            end
            else begin
                state_w = S_PAUSE;
            end
            
        end
		  S_CLEAN : begin
				counter_w = 0;
				if(c_count_r < 20'b11111111111111111111) begin
					c_count_w = c_count_r + 1;
					state_w = S_CLEAN;
					addr_w = addr_r + 1;
					data_w = 0;
				end
				else begin
					c_count_w = 0;
					state_w = S_WAIT;
					addr_w = 0;
					data_w = 0;
				end
		  end
    endcase

    
end
always_ff @(posedge i_clk or negedge i_rst_n ) begin
    if(~i_rst_n) begin
        state_r <= S_IDLE;
        counter_r <= 0;
        data_r <= 0;
        addr_r <= 20'b11111111111111111111;
		  c_count_r <= 20'd0;

    end
    else begin
        state_r <= state_w;
        counter_r <= counter_w;
        data_r <= data_w;
        addr_r <= addr_w;
		  c_count_r <= c_count_w;
    end
end
endmodule