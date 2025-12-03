module mac_row_part3 #(
    parameter bw = 4,
    parameter psum_bw = 16,
    parameter col = 8
)(
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 mode,

    // weight inputs from NORTH for this row: one per column
    input  wire [bw*col-1:0]    weight_in_north_vec,
    input  wire [col-1:0]       weight_valid_in_vec,

    // activation from WEST for this row: one activation (westmost) that enters tile0 and shifts right
    input  wire [bw-1:0]        act_in_west_row,

    // psum inputs from NORTH for each column
    input  wire [psum_bw*col-1:0] psum_in_vec,

    input  wire                 load_weight,   
    input  wire                 clear_psum,
    input  wire                 flush,

    // weight outputs to SOUTH for each column (to feed next row)
    output wire [bw*col-1:0]    weight_out_south_vec,
    output wire [col-1:0]       weight_valid_out_vec,

    // psum outputs from this row (to feed next row's psum_in)
    output wire [psum_bw*col-1:0] psum_out_vec,

    // for debug per-tile valid
    output wire [col-1:0]       valid_vec
);

    wire [bw*(col+1)-1:0] act_chain; 
    assign act_chain[bw-1:0] = act_in_west_row;

    // weight chain inside row: weight_in_north_vec provides weight to each tile; tiles will forward weight_out_south (col-wise)
    // but weight flow north->south is handled at array level; here we just use the provided per-column north inputs.

    genvar c;
    for (c = 0; c < col; c = c + 1) begin : col_tiles
       
        mac_tile_part3 #(.bw(bw), .psum_bw(psum_bw)) tile (
            .clk(clk),
            .reset(reset),
            .mode(mode),
            .load_weight(load_weight),
            .clear_psum(clear_psum),
            .flush(flush),

            .act_in_west(act_chain[bw*c +: bw]),
            .act_out_east(act_chain[bw*(c+1) +: bw]),

            .weight_in_north(weight_in_north_vec[bw*c +: bw]),
            .weight_valid_in(weight_valid_in_vec[c]),
            .weight_out_south(weight_out_south_vec[bw*c +: bw]),
            .weight_valid_out(weight_valid_out_vec[c]),

            .psum_in_north(psum_in_vec[psum_bw*c +: psum_bw]),
            .psum_out_south(psum_out_vec[psum_bw*c +: psum_bw]),

            .valid_out(valid_vec[c])
        );
    end

endmodule
