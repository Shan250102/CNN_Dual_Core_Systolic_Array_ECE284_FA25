module mac_array #(
    parameter bw = 4,
    parameter psum_bw = 16,
    parameter row = 8,
    parameter col = 8
)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   mode,                // 0 = WS, 1 = OS

    // weight IFIFO: per-column weight outputs (top of each column)
    input  wire [col*bw-1:0]      ififo_out_col,      // weight per column from IFIFO (top inputs)
    input  wire [col-1:0]         ififo_valid_col,    // valid bits per column from IFIFO

    // activations L0: per-row westmost activations (one per row)
    input  wire [row*bw-1:0]      l0_out_row,         
    input  wire [psum_bw*col-1:0] in_psum_top,

    input  wire [row-1:0]         load_weight,   // per-row pulse for WS
    input  wire [row-1:0]         clear_psum,
    input  wire [row-1:0]         flush,

    output wire [psum_bw*col-1:0] out_s,         // final psum vector from bottom row
    output wire [row*col-1:0]     weight_valid_out_flat 
);


    wire [bw*col-1:0] weight_in_north_row  [0:row-1];
    wire [col-1:0]    weight_valid_in_row  [0:row-1];
    wire [bw*col-1:0] weight_out_south_row [0:row-1];
    wire [col-1:0]    weight_valid_out_row [0:row-1];

    wire [psum_bw*col-1:0] psum_in_row  [0:row-1];
    wire [psum_bw*col-1:0] psum_out_row [0:row-1];

    wire [bw-1:0] act_west_row [0:row-1];
    genvar r;
    generate
        for (r = 0; r < row; r = r + 1) begin : row_assigns
            assign act_west_row[r] = l0_out_row[bw*r +: bw];
        end
    endgenerate

    generate
        for (r = 0; r < row; r = r + 1) begin : weight_init
            if (r == 0) begin
                assign weight_in_north_row[0] = ififo_out_col;
                assign weight_valid_in_row[0] = ififo_valid_col;
            end
        end
    endgenerate

    assign psum_in_row[0] = in_psum_top;

    generate
        for (r = 0; r < row; r = r + 1) begin : rows
            if (r > 0) begin
                assign weight_in_north_row[r] = weight_out_south_row[r-1];
                assign weight_valid_in_row[r] = weight_valid_out_row[r-1];
                assign psum_in_row[r] = psum_out_row[r-1];
            end

            mac_row_part3 #(.bw(bw), .psum_bw(psum_bw), .col(col)) row_inst (
                .clk(clk),
                .reset(reset),
                .mode(mode),

                .weight_in_north_vec(weight_in_north_row[r]),
                .weight_valid_in_vec(weight_valid_in_row[r]),

                .act_in_west_row(act_west_row[r]),

                .psum_in_vec(psum_in_row[r]),

                .load_weight(load_weight[r]),
                .clear_psum(clear_psum[r]),
                .flush(flush[r]),

                .weight_out_south_vec(weight_out_south_row[r]),
                .weight_valid_out_vec(weight_valid_out_row[r]),

                .psum_out_vec(psum_out_row[r]),
                .valid_vec()             );

            genvar c;
            for (c = 0; c < col; c = c + 1) begin : pack_obs
                assign weight_valid_out_flat[r*col + c] = weight_valid_out_row[r][c];
            end
        end
    endgenerate

    assign out_s = psum_out_row[row-1];

endmodule
