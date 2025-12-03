module mac #(
    parameter bw = 4,
    parameter psum_bw = 16
)(
    input  wire                 clk,
    input  wire                 reset,

    // 0 = WS, 1 = OS
    input  wire                 mode,

    // Data inputs
    input  wire [bw-1:0]        act_in,        // From WEST (activation)
    input  wire [bw-1:0]        weight_in_ws,  // WS load (from NORTH)
    input  wire [bw-1:0]        weight_in_os,  // OS stream (from NORTH)
    input  wire [psum_bw-1:0]   psum_in,       // From NORTH (vertical psum)

    // Streaming valid for weights (from North)
    input  wire                 weight_valid,  // indicates weight_in_* is valid

    // Control
    input  wire                 load_weight,   // WS: load weight into weight_reg (pulse)
    input  wire                 clear_psum,    // Clear psum at tile start
    input  wire                 flush,         // OS: final output pulse

    // Outputs
    output reg  [bw-1:0]        act_out,       // To EAST (activation forwarded)
    output reg  [bw-1:0]        weight_out,    // To SOUTH (weight forwarded)
    output reg                  weight_valid_out, // To SOUTH: indicates weight_out valid
    output reg  [psum_bw-1:0]   psum_out       // To SOUTH (vertical psum)
);

    reg [bw-1:0]      act_reg;
    reg [bw-1:0]      weight_reg;
    reg [psum_bw-1:0] psum_reg;

    wire [psum_bw-1:0] act_ext    = { {(psum_bw-bw){1'b0}}, act_reg };
    wire [psum_bw-1:0] weight_ext = { {(psum_bw-bw){1'b0}}, weight_reg };
    wire [psum_bw-1:0] mul_res    = act_ext * weight_ext;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            act_reg    <= 0;
            weight_reg <= 0;
            psum_reg   <= 0;

            act_out         <= 0;
            weight_out      <= 0;
            weight_valid_out<= 0;
            psum_out        <= 0;
        end else begin
            // Activation: forward and register
            act_out <= act_in;
            act_reg <= act_in;

            // Weight handling:
            if (mode == 0) begin
                // WS: load weight when load_weight asserted (weights arrive on weight_in_ws)
                if (load_weight) begin
                    weight_reg <= weight_in_ws;
                    weight_out <= weight_in_ws;
                    weight_valid_out <= 1'b1;
                end else begin
                    weight_reg <= weight_reg;
                    weight_out <= {bw{1'b0}};
                    weight_valid_out <= 1'b0;
                end
            end else begin
                // OS: stream weights from north when weight_valid
                if (weight_valid) begin
                    weight_reg <= weight_in_os;
                    weight_out <= weight_in_os;
                    weight_valid_out <= 1'b1;
                end else begin
                    weight_reg <= weight_reg;
                    weight_out <= {bw{1'b0}};
                    weight_valid_out <= 1'b0;
                end
            end

            // PSUM update
            if (clear_psum) begin
                psum_reg <= 0;
            end else begin
                if (mode == 0) begin
                    // WS: psum flows vertically, combine incoming psum with product
                    psum_reg <= psum_in + mul_res;
                end else begin
                    // OS: accumulate locally
                    psum_reg <= psum_reg + mul_res;
                end
            end

            // PSUM forwarding
            if (mode == 0) begin
                psum_out <= psum_reg;
            end else begin
                if (flush)
                    psum_out <= psum_reg;
                else
                    psum_out <= {psum_bw{1'b0}};
            end
        end
    end

endmodule
