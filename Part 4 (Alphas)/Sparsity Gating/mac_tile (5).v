module mac_tile_part3 #(
    parameter bw = 4,
    parameter psum_bw = 16
)(
    input  wire                 clk,
    input  wire                 reset,

    // control
    input  wire                 mode,
    input  wire                 load_weight,
    input  wire                 clear_psum,
    input  wire                 flush,

    // activation (WEST -> EAST)
    input  wire [bw-1:0]        act_in_west,
    output wire [bw-1:0]        act_out_east,

    // weight (NORTH -> SOUTH)
    input  wire [bw-1:0]        weight_in_north,
    input  wire                 weight_valid_in,
    output wire [bw-1:0]        weight_out_south,
    output wire                 weight_valid_out,

    // psum (NORTH -> SOUTH)
    input  wire [psum_bw-1:0]   psum_in_north,
    output wire [psum_bw-1:0]   psum_out_south,

    // debug
    output wire                 valid_out
    output wire                 clk_en1,clk_en2;
    output wire                  clk1, clk2;
);
output wire clk_en1, clk_en2;

     if (act_in_west == 0)
         assign clk_en1 = 0;   // clk_en for weight stationary
     if (act_in_north == 0)
         assing clk_en2 = 0;  // clk_en for output stationary

     assign clk1 = clk & clk_en1; // clk for weight stationary
     assign clk2 = clk & clk_en2; // clk for output stationary
      


    mac #(.bw(bw), .psum_bw(psum_bw)) u_mac (
        .clk(clk),
        .reset(reset),
        .mode(mode),

        .act_in(act_in_west),
        .weight_in_ws(weight_in_north),
        .weight_in_os(weight_in_north),
        .psum_in(psum_in_north),

        .weight_valid(weight_valid_in),

        .load_weight(load_weight),
        .clear_psum(clear_psum),
        .flush(flush),

        .act_out(act_out_east),
        .weight_out(weight_out_south),
        .weight_valid_out(weight_valid_out),
        .psum_out(psum_out_south)
    );

    assign valid_out = weight_valid_in;

endmodule
