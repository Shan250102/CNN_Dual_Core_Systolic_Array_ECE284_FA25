module ififo_part3 #(
    parameter col = 8,
    parameter bw  = 4
)(
    input  wire              clk,
    input  wire              reset,

    // write interface (loader writes col words at once)
    input  wire              wr,
    input  wire [col*bw-1:0] in_col,     // words for each column
    output wire              o_full,     // any FIFO full

    // read interface (array reads all columns at once)
    input  wire              rd,
    output wire [col*bw-1:0] out_col,    // outputs for each column (top of column)
    output wire [col-1:0]    valid_col,  // per-column valid
    output wire              o_ready     // true if all FIFOs non-empty
);

    wire [col-1:0] empty;
    wire [col-1:0] full;

    genvar c;
    generate
        for (c = 0; c < col; c = c + 1) begin : cols
            fifo_depth64 #(.bw(bw)) fifo_inst (
                .rd_clk (clk),
                .wr_clk (clk),
                .rd     (rd),
                .wr     (wr),
                .o_empty(empty[c]),
                .o_full (full[c]),
                .in     (in_col[bw*c +: bw]),
                .out    (out_col[bw*c +: bw]),
                .reset  (reset)
            );
            assign valid_col[c] = ~empty[c];
        end
    endgenerate

    assign o_ready = (empty == 0);
    assign o_full  = |full;

endmodule
