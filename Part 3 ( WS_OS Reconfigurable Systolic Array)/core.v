module core (
    clk,
    inst,
    ofifo_valid,
    D_xmem,
    sfp_out,
    reset,
    Relu_en,
    sram_sel_fifo,
    sram_sel_output,
    in_ififo_col   
);

parameter row = 8;
parameter col = 8;
parameter bw = 4;
parameter psum_bw_ofifo = 32;
parameter psum_bw_mac = 16;
parameter sram_act_size = 8192;

input clk;
input [48:0] inst;
input Relu_en;
output ofifo_valid;
input signed [psum_bw_ofifo-1:0] D_xmem;
output reg signed [col*psum_bw_ofifo-1:0] sfp_out;
input reset;
input [2:0] sram_sel_fifo;
input [2:0] sram_sel_output;
input [col*bw-1:0] in_ififo_col; 

wire [col*psum_bw_mac -1 :0] out_ofifo; 
wire o_valid;
wire [psum_bw_ofifo-1:0] output_act;

wire [psum_bw_ofifo-1:0] psum_stored_1;
wire [psum_bw_ofifo-1:0] psum_stored_2;
wire [psum_bw_ofifo-1:0] psum_stored_3;
wire [psum_bw_ofifo-1:0] psum_stored_4;
wire [psum_bw_ofifo-1:0] psum_stored_5;
wire [psum_bw_ofifo-1:0] psum_stored_6;
wire [psum_bw_ofifo-1:0] psum_stored_7;
wire [psum_bw_ofifo-1:0] psum_stored_8;
wire [col*psum_bw_ofifo-1:0] psum_stored_mem;
reg [col*psum_bw_ofifo-1:0] temp_out_ofifo;
wire [col*psum_bw_ofifo-1:0] temp_out_psum;

wire [psum_bw_ofifo-1:0] psum_stored_out_1;
wire [psum_bw_ofifo-1:0] psum_stored_out_2;
wire [psum_bw_ofifo-1:0] psum_stored_out_3;
wire [psum_bw_ofifo-1:0] psum_stored_out_4;
wire [psum_bw_ofifo-1:0] psum_stored_out_5;
wire [psum_bw_ofifo-1:0] psum_stored_out_6;
wire [psum_bw_ofifo-1:0] psum_stored_out_7;
wire [psum_bw_ofifo-1:0] psum_stored_out_8;
reg [psum_bw_ofifo-1:0] psum_stored_sfp;

genvar i;

corelet_part3 #(
    .row(row),
    .col(col),
    .bw(bw),
    .psum_bw_ofifo(psum_bw_ofifo),
    .psum_bw_mac(psum_bw_mac)
) corelet_instance (
    .clk(clk),
    .reset(reset),
    .in_lfifo(output_act),          // activation values read from activation SRAM
    .in_ififo_col(in_ififo_col),    // IFIFO write bus
    .inst_q(inst),
    .Relu_en(Relu_en),
    .out_ofifo(out_ofifo),
    .o_valid(o_valid)
);

// o_valid pulses when out_ofifo valid
integer jj;
always @(posedge clk) begin
    if (reset) begin
        temp_out_ofifo <= {col*psum_bw_ofifo{1'b0}};
    end else begin
        if (o_valid) begin
            for (jj = 0; jj < col; jj = jj + 1) begin
                temp_out_ofifo[(jj+1)*psum_bw_ofifo-1 -: psum_bw_ofifo] <=
                    {{(psum_bw_ofifo-psum_bw_mac){out_ofifo[(jj+1)*psum_bw_mac-1]}},
                     out_ofifo[(jj+1)*psum_bw_mac-1 -: psum_bw_mac]};
            end
        end
    end
end

sram_32b_w2048 sram_activation (
    .CLK(clk),
    .D(D_xmem),
    .Q(output_act),
    .CEN(inst[19]),
    .WEN(inst[18]),
    .A(inst[17:7])
);

sram_32b_w10500 #(.num(10500)) sram_psum_oc1 (.CLK(clk), .D(temp_out_ofifo[31:0]),    .Q(psum_stored_1), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));
sram_32b_w10500 #(.num(10500)) sram_psum_oc2 (.CLK(clk), .D(temp_out_ofifo[63:32]),   .Q(psum_stored_2), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));
sram_32b_w10500 #(.num(10500)) sram_psum_oc3 (.CLK(clk), .D(temp_out_ofifo[95:64]),   .Q(psum_stored_3), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));
sram_32b_w10500 #(.num(10500)) sram_psum_oc4 (.CLK(clk), .D(temp_out_ofifo[127:96]),  .Q(psum_stored_4), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));
sram_32b_w10500 #(.num(10500)) sram_psum_oc5 (.CLK(clk), .D(temp_out_ofifo[159:128]), .Q(psum_stored_5), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));
sram_32b_w10500 #(.num(10500)) sram_psum_oc6 (.CLK(clk), .D(temp_out_ofifo[191:160]), .Q(psum_stored_6), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));
sram_32b_w10500 #(.num(10500)) sram_psum_oc7 (.CLK(clk), .D(temp_out_ofifo[223:192]), .Q(psum_stored_7), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));
sram_32b_w10500 #(.num(10500)) sram_psum_oc8 (.CLK(clk), .D(temp_out_ofifo[255:224]), .Q(psum_stored_8), .CEN(inst[35]), .WEN(inst[34]), .A(inst[33:20]));

sram_32b_w1024 #(.num(1024)) sram_psum_store_1 (.CLK(clk), .D(temp_out_psum[31:0]),   .Q(psum_stored_out_1), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));
sram_32b_w1024 #(.num(1024)) sram_psum_store_2 (.CLK(clk), .D(temp_out_psum[63:32]),  .Q(psum_stored_out_2), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));
sram_32b_w1024 #(.num(1024)) sram_psum_store_3 (.CLK(clk), .D(temp_out_psum[95:64]),  .Q(psum_stored_out_3), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));
sram_32b_w1024 #(.num(1024)) sram_psum_store_4 (.CLK(clk), .D(temp_out_psum[127:96]), .Q(psum_stored_out_4), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));
sram_32b_w1024 #(.num(1024)) sram_psum_store_5 (.CLK(clk), .D(temp_out_psum[159:128]),.Q(psum_stored_out_5), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));
sram_32b_w1024 #(.num(1024)) sram_psum_store_6 (.CLK(clk), .D(temp_out_psum[191:160]),.Q(psum_stored_out_6), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));
sram_32b_w1024 #(.num(1024)) sram_psum_store_7 (.CLK(clk), .D(temp_out_psum[223:192]),.Q(psum_stored_out_7), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));
sram_32b_w1024 #(.num(1024)) sram_psum_store_8 (.CLK(clk), .D(temp_out_psum[255:224]),.Q(psum_stored_out_8), .CEN(inst[38]), .WEN(inst[37]), .A(inst[48:39]));

// When mac array produces valid output, build psum_stored_mem for SFU
assign psum_stored_mem = (o_valid) ? (
    { psum_stored_1, psum_stored_2, psum_stored_3, psum_stored_4,
      psum_stored_5, psum_stored_6, psum_stored_7, psum_stored_8 }
) : {col*psum_bw_ofifo{1'b0}};

for (i = 0; i < col; i = i + 1) begin : sfu_col
    accumulator_sfu #(.psum_bw(psum_bw_ofifo)) sfu_instance (
        .clk(clk),
        .reset(reset),
        .psum_stored_q(psum_stored_mem[(i+1)*psum_bw_ofifo -1 : i*psum_bw_ofifo]),
        .out(temp_out_psum[(i+1)*psum_bw_ofifo -1 : i*psum_bw_ofifo]),
        .Relu_en(Relu_en)
    );
end

always @(*) begin
    case (sram_sel_output)
        3'b000 : psum_stored_sfp = psum_stored_out_1 ;
        3'b001 : psum_stored_sfp = psum_stored_out_2 ;
        3'b010 : psum_stored_sfp = psum_stored_out_3 ;
        3'b011 : psum_stored_sfp = psum_stored_out_4 ;
        3'b100 : psum_stored_sfp = psum_stored_out_5 ;
        3'b101 : psum_stored_sfp = psum_stored_out_6 ;
        3'b110 : psum_stored_sfp = psum_stored_out_7 ;
        3'b111 : psum_stored_sfp = psum_stored_out_8 ;
        default : psum_stored_sfp = psum_stored_out_1;
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        sfp_out <= {col*psum_bw_ofifo{1'b0}};
    end else begin
        if (o_valid)
            sfp_out <= temp_out_ofifo;
    end
end

assign ofifo_valid = o_valid;

endmodule
