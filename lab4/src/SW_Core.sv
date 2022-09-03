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
// SW Core --------------------------------------------
module SW_core(
    input                                       clk,
    input                                       rst,   
   
    output reg                                  o_ready,
    input                                       i_valid,
    input [2*`REF_MAX_LENGTH-1:0]               i_sequence_ref,     // reference seq
    input [2*`READ_MAX_LENGTH-1:0]              i_sequence_read,    // read seq
    input [$clog2(`REF_MAX_LENGTH):0]           i_seq_ref_length,   // (1-based)
    input [$clog2(`READ_MAX_LENGTH):0]          i_seq_read_length,  // (1-based)

    input                                       i_ready,
    output reg                                  o_valid,
    output signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_alignment_score,
    output reg [$clog2(`REF_MAX_LENGTH)-1:0]    o_column,
    output reg [$clog2(`READ_MAX_LENGTH)-1:0]   o_row
);
    integer i, j, k, l;
    
    localparam  S_input                 = 2'd0,
                S_calculate             = 2'd1,
                S_select_highest        = 2'd2,
                S_done                  = 2'd3;

    localparam MOST_NEGATIVE = {1'b1, {(`DP_SW_SCORE_BITWIDTH-1){1'b0}}};

    ///////////////////////////// main registers ////////////////////////////////
    reg [1:0]                                           state, state_n;
    reg [$clog2(`REF_MAX_LENGTH+`READ_MAX_LENGTH):0]    counter, counter_n;
    reg [2*`REF_MAX_LENGTH-1:0]                         sequence_A, sequence_A_n;
    reg [2*`READ_MAX_LENGTH-1:0]                        sequence_B, sequence_B_n;
    reg [$clog2(`REF_MAX_LENGTH):0]                     seq_A_length, seq_A_length_n;
    reg [$clog2(`READ_MAX_LENGTH):0]                    seq_B_length, seq_B_length_n;

    reg                                                 sequence_B_valid[0:`READ_MAX_LENGTH-1];
    reg [2*`REF_MAX_LENGTH-1:0]                         sequence_A_shifter, sequence_A_shifter_n;

    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              highest_score, highest_score_n;
    reg [$clog2(`REF_MAX_LENGTH)-1:0]                   column, column_n;
    reg [$clog2(`READ_MAX_LENGTH)-1:0]                  row, row_n;

    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              row_highest_scores[0:`READ_MAX_LENGTH-1], row_highest_scores_n[0:`READ_MAX_LENGTH-1];
    reg [$clog2(`REF_MAX_LENGTH)-1:0]                   row_highest_columns[0:`READ_MAX_LENGTH-1], row_highest_columns_n [0:`READ_MAX_LENGTH-1];

    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_score_buff  [0:`READ_MAX_LENGTH-1], PE_score_buff_n [0:`READ_MAX_LENGTH-1];

    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_align_score_d  [0:`READ_MAX_LENGTH-1], PE_align_score_d_n [0:`READ_MAX_LENGTH-1];
    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_insert_score_d [0:`READ_MAX_LENGTH-1], PE_insert_score_d_n [0:`READ_MAX_LENGTH-1];
    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_delete_score_d [0:`READ_MAX_LENGTH-1], PE_delete_score_d_n [0:`READ_MAX_LENGTH-1];
    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_align_score_dd [0:`READ_MAX_LENGTH-1], PE_align_score_dd_n [0:`READ_MAX_LENGTH-1];
    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_insert_score_dd[0:`READ_MAX_LENGTH-1], PE_insert_score_dd_n [0:`READ_MAX_LENGTH-1];
    reg signed [`DP_SW_SCORE_BITWIDTH-1:0]              PE_delete_score_dd[0:`READ_MAX_LENGTH-1], PE_delete_score_dd_n [0:`READ_MAX_LENGTH-1];


    assign o_alignment_score = highest_score;
    assign o_ready           = (state == S_input) ? 1 : 0;        
    assign o_valid           = (state == S_done) ? 1 : 0;
    assign o_column          = column;
    assign o_row             = row;

    //----------------------------------------------------------------------------------------
    wire signed [`DP_SW_SCORE_BITWIDTH-1:0] PE_align_score          [`READ_MAX_LENGTH:0];
    wire signed [`DP_SW_SCORE_BITWIDTH-1:0] PE_insert_score         [`READ_MAX_LENGTH:0];
    wire signed [`DP_SW_SCORE_BITWIDTH-1:0] PE_delete_score         [`READ_MAX_LENGTH:0];
    
    wire                                    PE_last_A_base_valid    [`READ_MAX_LENGTH:0];
    wire [1:0]                              PE_last_A_base          [`READ_MAX_LENGTH:0];

    genvar gv;
    generate
        for (gv=0;gv<`READ_MAX_LENGTH;gv=gv+1) begin: PEs
            if (gv==0) begin
                DP_PE_single u_PE_single(
                    ///////////////////////////////////// basics /////////////////////////////////////
                    .clk                        (clk),
                    .rst                        (rst),
                    ///////////////////////////////////// I/Os //////////////////////////////////////
                    .i_A_base_valid             ((state == S_calculate) && (counter < seq_A_length)),
                    .i_A_base                   (sequence_A_shifter[2*`REF_MAX_LENGTH-1-:2] ),

                    .i_B_base_valid             (sequence_B_valid[gv]                       ),
                    .i_B_base                   (sequence_B[2*`READ_MAX_LENGTH-1-(2*gv)-:2] ),

                    .i_align_top_score          ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                    .i_insert_top_score         ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                    .i_align_diagonal_score     ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                    .i_insert_diagonal_score    ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),
                    .i_delete_diagonal_score    ({(`DP_SW_SCORE_BITWIDTH){1'b0}}            ), // (0),

                    .i_align_left_score         (PE_align_score_d[gv]                       ),
                    .i_insert_left_score        (PE_insert_score_d[gv]                      ),
                    .i_delete_left_score        (PE_delete_score_d[gv]                      ),

                    .o_align_score              (PE_align_score[gv]                         ),
                    .o_insert_score             (PE_insert_score[gv]                        ),
                    .o_delete_score             (PE_delete_score[gv]                        ),

                    .o_the_score                (PE_score_buff_n [gv]                       ),
                    .o_last_A_base_valid        (PE_last_A_base_valid[gv]                   ),
                    .o_last_A_base              (PE_last_A_base[gv]                         )
                );
            end 
            else begin
                DP_PE_single u_PE_single(
                    ///////////////////////////////////// basics /////////////////////////////////////
                    .clk                        (clk),
                    .rst                        (rst),
                    ///////////////////////////////////// I/Os //////////////////////////////////////
                    .i_A_base_valid             (PE_last_A_base_valid[gv-1]                 ),
                    .i_A_base                   (PE_last_A_base[gv-1]                       ),
                    .i_B_base_valid             (sequence_B_valid[gv]                       ),
                    .i_B_base                   (sequence_B[2*`READ_MAX_LENGTH-1-(2*gv)-:2] ),
                    
                    .i_align_diagonal_score     (PE_align_score_dd [gv-1]                   ),
                    .i_align_top_score          (PE_align_score_d  [gv-1]                   ),
                    .i_align_left_score         (PE_align_score_d  [gv]                     ),

                    .i_insert_diagonal_score    (PE_insert_score_dd[gv-1]                   ),
                    .i_insert_top_score         (PE_insert_score_d [gv-1]                   ), 
                    .i_insert_left_score        (PE_insert_score_d [gv]                     ),                  
                    
                    .i_delete_diagonal_score    (PE_delete_score_dd[gv-1]                   ),                  
                    .i_delete_left_score        (PE_delete_score_d [gv]                     ),

                    .o_align_score              (PE_align_score[gv]                         ),
                    .o_insert_score             (PE_insert_score[gv]                        ),
                    .o_delete_score             (PE_delete_score[gv]                        ),

                    .o_the_score                (PE_score_buff_n[gv]                        ),
                    .o_last_A_base_valid        (PE_last_A_base_valid[gv]                   ),
                    .o_last_A_base              (PE_last_A_base[gv]                         )
                );
            end
        end
    endgenerate

    //////////////////////////// state control ////////////////////////////
    always@(*) begin
        state_n = state;
        case(state)
            S_input:            state_n = (i_valid) ? S_calculate : state;
            S_calculate:        state_n = (counter == seq_A_length + seq_B_length - 2) ? S_select_highest : state;
            S_select_highest:   state_n = (counter == seq_B_length - 1) ? S_done : state;
            S_done:             state_n = (i_ready) ? S_input : state;
        endcase
    end

    ///////////////////// main design ///////////////////
    always@(*) begin
        sequence_A_n                                                            = sequence_A;
        sequence_B_n                                                            = sequence_B;
        seq_A_length_n                                                          = seq_A_length;
        seq_B_length_n                                                          = seq_B_length;

        counter_n                                                               = counter;
        sequence_A_shifter_n                                                    = sequence_A;

        highest_score_n                                                         = highest_score;
        column_n                                                                = column;
        row_n                                                                   = row;
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_scores_n[i]              = row_highest_scores [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_columns_n[i]             = row_highest_columns[i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) sequence_B_valid[i]                  = (state == S_calculate);
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_d_n  [i]              = PE_align_score_d [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_d_n [i]              = PE_insert_score_d [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_d_n [i]              = PE_delete_score_d [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_dd_n [i]              = PE_align_score_dd [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_dd_n[i]              = PE_insert_score_dd [i];
        for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_dd_n[i]              = PE_delete_score_dd [i];


        // *** TODO
        case(state)
            S_input: begin
                sequence_A_n                                                            = i_sequence_ref;
                sequence_B_n                                                            = i_sequence_read;
                seq_A_length_n                                                          = i_seq_ref_length;
                seq_B_length_n                                                          = i_seq_read_length;

                counter_n                                                               = 0;
                sequence_A_shifter_n                                                    = i_sequence_ref;

                highest_score_n                                                         = MOST_NEGATIVE;
                column_n                                                                = 0;
                row_n                                                                   = 0;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_scores_n[i]              = 0;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_columns_n[i]             = 0;

                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_d_n  [i]              = 0;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_d_n [i]              = 0;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_d_n [i]              = 0;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_dd_n [i]              = 0;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_dd_n[i]              = 0;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_dd_n[i]              = 0;
            end

            S_calculate: begin
                sequence_A_n                                                            = sequence_A;
                sequence_B_n                                                            = sequence_B;
                seq_A_length_n                                                          = seq_A_length;
                seq_B_length_n                                                          = seq_B_length;
                counter_n                                                               = (counter == seq_A_length + seq_B_length - 2) ? 0 : (counter + 1);
                sequence_A_shifter_n                                                    = sequence_A_shifter << 2;

                highest_score_n                                                         = highest_score;
                column_n                                                                = column;
                row_n                                                                   = row;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_scores_n[i]              = (PE_score_buff_n[i] > row_highest_scores[i]) ? PE_score_buff_n[i] : row_highest_scores[i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_columns_n[i]             = (PE_score_buff_n[i] > row_highest_scores[i]) ? counter - $unsigned(i) : row_highest_columns[i];

                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_d_n  [i]              = PE_align_score[i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_d_n [i]              = PE_insert_score[i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_d_n [i]              = PE_delete_score[i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_dd_n [i]              = PE_align_score_d[i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_dd_n[i]              = PE_insert_score_d[i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_dd_n[i]              = PE_delete_score_d[i];           
            end

            S_select_highest: begin
                sequence_A_n                                                            = sequence_A;
                sequence_B_n                                                            = sequence_B;
                seq_A_length_n                                                          = seq_A_length;
                seq_B_length_n                                                          = seq_B_length;
                counter_n                                                               = counter + 1;
                sequence_A_shifter_n                                                    = sequence_A_shifter;

                highest_score_n                                                         = (row_highest_scores[counter] > highest_score) ? row_highest_scores[counter] : highest_score;
                column_n                                                                = (row_highest_scores[counter] > highest_score) ? row_highest_columns[counter] : column;
                row_n                                                                   = (row_highest_scores[counter] > highest_score) ? counter : row;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_scores_n[i]              = row_highest_scores [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_columns_n[i]             = row_highest_columns[i];

                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_d_n  [i]              = PE_align_score_d [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_d_n [i]              = PE_insert_score_d [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_d_n [i]              = PE_delete_score_d [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_dd_n [i]              = PE_align_score_dd [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_dd_n[i]              = PE_insert_score_dd [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_dd_n[i]              = PE_delete_score_dd [i];
            end

            S_done: begin
                sequence_A_n                                                            = sequence_A;
                sequence_B_n                                                            = sequence_B;
                seq_A_length_n                                                          = seq_A_length;
                seq_B_length_n                                                          = seq_B_length;
                counter_n                                                               = 0;
                sequence_A_shifter_n                                                    = sequence_A_shifter;

                highest_score_n                                                         = highest_score;
                column_n                                                                = column;
                row_n                                                                   = row;
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_scores_n[i]              = row_highest_scores [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_columns_n[i]             = row_highest_columns[i];

                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_d_n  [i]              = PE_align_score_d [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_d_n [i]              = PE_insert_score_d [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_d_n [i]              = PE_delete_score_d [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_dd_n [i]              = PE_align_score_dd [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_dd_n[i]              = PE_insert_score_dd [i];
                for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_dd_n[i]              = PE_delete_score_dd [i];
            end
        endcase
    end

    /////////////////////////////// main ////////////////////////////
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            state                                                       <= S_input;
            counter                                                     <= 0;
            sequence_A                                                  <= 0;
            sequence_B                                                  <= 0;
            seq_A_length                                                <= 0;
            seq_B_length                                                <= 0;
            sequence_A_shifter                                          <= 0;
            highest_score                                               <= MOST_NEGATIVE;            
            column                                                      <= 0;
            row                                                         <= 0;

            for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_scores[i]    <= 0;
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_columns[i]   <= 0;

            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_score_buff[i]         <= 0;
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_d  [i]    <= 0;
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_d [i]    <= 0;
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_d [i]    <= 0;
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_dd [i]    <= 0;
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_dd[i]    <= 0;
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_dd[i]    <= 0;
        end 
        else begin
            state                                                       <= state_n;
            counter                                                     <= counter_n;
            sequence_A                                                  <= sequence_A_n;
            sequence_B                                                  <= sequence_B_n;
            seq_A_length                                                <= seq_A_length_n;
            seq_B_length                                                <= seq_B_length_n;
            sequence_A_shifter                                          <= sequence_A_shifter_n;
            highest_score                                               <= highest_score_n;
            column                                                      <= column_n;
            row                                                         <= row_n;

            for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_scores[i]    <= row_highest_scores_n [i];
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) row_highest_columns[i]   <= row_highest_columns_n[i];

            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_score_buff[i]         <= PE_score_buff_n[i];
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_d  [i]    <= PE_align_score_d_n   [i];
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_d [i]    <= PE_insert_score_d_n  [i];
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_d [i]    <= PE_delete_score_d_n  [i];
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_align_score_dd [i]    <= PE_align_score_dd_n  [i];
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_insert_score_dd[i]    <= PE_insert_score_dd_n [i];
            for (i=0;i<`READ_MAX_LENGTH;i=i+1) PE_delete_score_dd[i]    <= PE_delete_score_dd_n [i];            
        end
    end

endmodule


module DP_PE_single(
    ///////////////////////////////////// basics /////////////////////////////////////
    input                                       clk,
    input                                       rst,

    ///////////////////////////////////// I/Os //////////////////////////////////////
    input                                       i_A_base_valid,
    input                                       i_B_base_valid,
    input [1:0]                                 i_A_base,          // reference one.   Mapping: reference sequence
    input [1:0]                                 i_B_base,          // query one.       Mapping: short-read
    
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_align_diagonal_score,
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_align_top_score,
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_align_left_score, 

    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_insert_diagonal_score,
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_insert_top_score,
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_insert_left_score,    // if !(i_A_base_valid && i_B_base_valid), o_insert_score = i_insert_left_score
    
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_delete_diagonal_score,
    input signed [`DP_SW_SCORE_BITWIDTH-1:0]    i_delete_left_score,

    output reg signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_align_score,
    output reg signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_insert_score,
    output reg signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_delete_score,

    output reg signed [`DP_SW_SCORE_BITWIDTH-1:0]   o_the_score,            // The highest score among o_align_score, o_insert_score and o_delete_score
    output reg                                      o_last_A_base_valid,
    output reg [1:0]                                o_last_A_base
); 
reg signed [`DP_SW_SCORE_BITWIDTH-1:0] S;
assign S = (i_A_base == i_B_base) ? `CONST_MATCH_SCORE : `CONST_MISMATCH_SCORE;
assign o_the_score = o_align_score;
// *** TODO
// Insert
always@(*) begin
    if (i_A_base_valid && i_B_base_valid) begin
        if((i_align_top_score + `CONST_GAP_OPEN) >= (i_insert_top_score + `CONST_GAP_EXTEND) && (i_align_top_score + `CONST_GAP_OPEN) >= 0) begin
            o_insert_score = i_align_top_score + `CONST_GAP_OPEN;
        end
        else if((i_insert_top_score + `CONST_GAP_EXTEND) >= (i_align_top_score + `CONST_GAP_OPEN) && (i_insert_top_score + `CONST_GAP_EXTEND) >= 0) begin
            o_insert_score = i_insert_top_score + `CONST_GAP_EXTEND;
        end
        else begin
            o_insert_score = 0;
        end
    end
    else begin
        o_insert_score = i_insert_left_score;
    end
end
// Delete
always@(*) begin
    if (i_A_base_valid && i_B_base_valid) begin
        if((i_align_left_score + `CONST_GAP_OPEN) >= (i_delete_left_score + `CONST_GAP_EXTEND) && (i_align_left_score + `CONST_GAP_OPEN) >= 0) begin
            o_delete_score = i_align_left_score + `CONST_GAP_OPEN;
        end
        else if((i_delete_left_score + `CONST_GAP_EXTEND) >= (i_align_left_score + `CONST_GAP_OPEN) && (i_delete_left_score + `CONST_GAP_EXTEND) >= 0) begin
            o_delete_score = i_delete_left_score + `CONST_GAP_EXTEND;
        end
        else begin
            o_delete_score = 0;
        end
    end
    else begin
        o_delete_score = i_delete_left_score;
    end
end
// H(align)
always@(*) begin
    if (i_A_base_valid && i_B_base_valid) begin
        if((i_align_diagonal_score + S) >= o_insert_score && (i_align_diagonal_score + S) >= o_delete_score && (i_align_diagonal_score + S) >= 0) begin
            o_align_score = i_align_diagonal_score + S;
        end
        else if(o_insert_score >= (i_align_diagonal_score + S) && o_insert_score >= o_delete_score && o_insert_score >= 0) begin
            o_align_score = o_insert_score;
        end
        else if(o_delete_score >= (i_align_diagonal_score + S) && o_delete_score >= o_insert_score && o_delete_score >= 0) begin
            o_align_score = o_delete_score;
        end
        else begin
            o_align_score = 0;
        end
    end
    else begin
        o_align_score = i_align_left_score;
    end
end
// Sequential
always@(posedge clk or posedge rst) begin
    if (rst) begin
        o_last_A_base_valid <= 0;
        o_last_A_base       <= 0;
    end else begin
        o_last_A_base_valid <= i_A_base_valid;
        o_last_A_base       <= i_A_base;
    end
end

endmodule