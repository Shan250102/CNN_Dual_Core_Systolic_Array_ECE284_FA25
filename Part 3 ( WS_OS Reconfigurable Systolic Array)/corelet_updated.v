module corelet_part3 #(
  parameter row = 8,
  parameter col = 8,
  parameter bw  = 4,
  parameter psum_bw_ofifo = 32,
  parameter psum_bw_mac   = 16
)(
  input  wire                    clk,
  input  wire                    reset,

  // activation inputs (westmost per-row) from top-level activation SRAM
  input  wire [row*bw-1:0]       in_lfifo,

  // IFIFO write bus (host/file writes a col-wide vector into IFIFO)
  input  wire [col*bw-1:0]       in_ififo_col,

  input  wire [48:0]             inst_q,
  input  wire                    Relu_en, 
  output wire [col*psum_bw_mac-1:0] out_ofifo, // MAC array outputs (one PSUM per column)
  output wire                    o_valid
);

  wire l0_wr    = inst_q[2];
  wire l0_rd    = inst_q[3];
  wire [row*bw-1:0] out_lfifo;
  wire ififo_rd_tb = inst_q[4];
  wire ififo_wr = inst_q[5];
  wire ofifo_rd = inst_q[6];
  wire execute  = inst_q[1];
  wire load     = inst_q[0];

  wire mode     = inst_q[46]; // 0 = WS, 1 = OS

  wire [col*bw-1:0] ififo_out_col;
  wire [col-1:0]    ififo_valid_col;
  wire ififo_ready, ififo_full;
  

  // control for automatic IFIFO read aligned to load
  reg load_active;
  reg [3:0] row_ptr;
  reg ififo_rd_auto;
  wire ififo_rd = ififo_rd_tb | ififo_rd_auto;
  wire [psum_bw_mac*col-1:0] out_s;
  reg [row-1:0] load_weight_vec;      // actual pulse seen by MACs this cycle
  reg [row-1:0] load_weight_next;     // prepared one cycle earlier
  reg ififo_rd_request;               //  drives ififo_rd_auto next cycle


  wire [col-1:0] valid_ofifo;
  ififo_part3 #(.col(col), .bw(bw)) ififo_inst (
    .clk(clk), .reset(reset),
    .wr(ififo_wr), .in_col(in_ififo_col), .o_full(ififo_full),
    .rd(ififo_rd), .out_col(ififo_out_col), .valid_col(ififo_valid_col),
    .o_ready(ififo_ready)
  );

  l0 #(.bw(bw), .row(row)) l0_fifo(
	  .clk(clk),
	  .in(in_lfifo),
	  .out(out_lfifo),
	  .rd(inst_q[3]),.wr(inst_q[2]), .o_full(o_full), .reset(reset), .o_ready(o_ready));

  ofifo #(.psum_bw(psum_bw_mac), .col(col)) o_fifo
  (.clk(clk), .in(out_s), .out(out_ofifo), .rd(inst_q[6]), .wr(valid_ofifo), .o_full(o_full), .reset(reset), .o_ready(o_ready_ofifo), .o_valid(o_valid));



  // ---------------- Control generator (per-row signals) ----------------
  reg exec_active;
  reg [row-1:0] clear_psum_vec;
  reg [row-1:0] flush_vec;

  integer ii;
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      row_ptr <= 0;
      load_active <= 1'b0;
      exec_active <= 1'b0;
      ififo_rd_auto <= 1'b0;
      load_weight_vec <= {row{1'b0}};
      load_weight_next <= {row{1'b0}};
      ififo_rd_request <= 1'b0;
      clear_psum_vec <= {row{1'b0}};
      flush_vec <= {row{1'b0}};
    end else begin
      
    if (load && !load_active) begin
        load_active <= 1'b1;
        row_ptr <= 0;
        load_weight_next <= {row{1'b0}};
        load_weight_next[0] <= 1'b1;
      end else if (!load) begin
        load_active <= 1'b0;
        load_weight_vec <= {row{1'b0}};
        load_weight_next <= {row{1'b0}};
        ififo_rd_request <= 1'b0;
        ififo_rd_auto <= 1'b0;
      end

      if (load_active) begin
        ififo_rd_request <= 1'b1;

        load_weight_vec <= load_weight_next;

        load_weight_next <= {row{1'b0}};
        load_weight_next[row_ptr] <= 1'b1;

        if (row_ptr == row-1) row_ptr <= 0;
        else row_ptr <= row_ptr + 1'b1;
      end

      if (ififo_rd_request) begin
        ififo_rd_auto <= (mode == 1'b0); // only auto-pop in WS automatic load
        ififo_rd_request <= 1'b0; 
      end else begin
        ififo_rd_auto <= 1'b0;
      end

      // ------------ Execute clear and flush (unchanged) ------------
      if (execute && !exec_active) begin
        exec_active <= 1'b1;
        clear_psum_vec <= {row{1'b1}};
      end else begin
        clear_psum_vec <= {row{1'b0}};
      end

      if (!execute && exec_active) begin
        exec_active <= 1'b0;
        flush_vec <= {row{1'b1}};
      end else begin
        flush_vec <= {row{1'b0}};
      end
    end
  end

  //  reg [row*bw-1:0] act_in_reg;
  //always @(posedge clk or posedge reset) begin
  //        if(reset) begin
  //      	  act_in_reg <= {row*bw{1'b0}};
  //        end else begin
  //      	  act_in_reg <= out_lfifo;
  //        end
  //end

 // wire [row*bw-1:0] mac_in_act_west = in_lfifo;

  wire [psum_bw_mac*col-1:0] mac_out_flat;
  wire [row*col-1:0]         weight_valid_out_flat; // observation

  mac_array #(.bw(bw), .psum_bw(psum_bw_mac), .row(row), .col(col)) mac_array_inst (
    .clk(clk),
    .reset(reset),
    .mode(mode),
    .ififo_out_col(ififo_out_col),
    .ififo_valid_col(ififo_valid_col),
    .l0_out_row(out_lfifo),
    .in_psum_top({psum_bw_mac*col{1'b0}}),
    .load_weight(load_weight_vec),
    .clear_psum(clear_psum_vec),
    .flush(flush_vec),
    .out_s(mac_out_flat),
    .weight_valid_out_flat(weight_valid_out_flat)
  );

  assign out_ofifo = mac_out_flat;

  reg o_valid_reg;
  always @(posedge clk or posedge reset) begin
    if (reset) o_valid_reg <= 1'b0;
    else o_valid_reg <= |flush_vec;
  end
  assign o_valid = o_valid_reg;

endmodule
