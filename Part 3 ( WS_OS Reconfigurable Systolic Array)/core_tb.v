`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 32;
parameter len_kij = 9;   
parameter len_onij = 8;  
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;   

reg clk = 0;
reg reset = 1;

wire [48:0] inst_q;
wire Relu_en_c;

reg [1:0] inst_w_q = 0;
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg CEN_pmem_out = 1;
reg WEN_pmem_out = 1;
reg [10:0] A_pmem = 0;
reg [9:0] A_pmem_out = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg CEN_pmem_out_q = 1;
reg WEN_pmem_out_q = 1;
reg [10:0] A_pmem_q = 0;
reg [9:0] A_pmem_out_q = 0;
reg ofifo_rd_q = 0;
reg ofifo_rd = 0;
reg ififo_wr_q = 0;
reg ififo_wr = 0;
reg ififo_rd_q = 0;
reg ififo_rd = 0;
reg l0_rd_q = 0;
reg l0_rd = 0;
reg l0_wr_q = 0;
reg l0_wr = 0;
reg execute_q = 0;
reg execute = 0;
reg load_q = 0;
reg load = 0;
reg acc_q = 0;
reg acc = 0;
reg Relu_en_q = 0;
reg Relu_en = 0;

reg [1:0] inst_w;
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;

reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;
reg [2:0] sram_sel_fifo;
reg [2:0] sram_sel_output;

integer x_file, x_scan_file ; 
integer w_file, w_scan_file ; 
integer acc_file, acc_scan_file ; 
integer out_file, out_scan_file ; 
integer captured_data;
integer t, i, j, k, kij,l,onij;
integer error;

reg [31:0] temp_word = 0;
reg [col*bw-1:0] in_ififo_col = {col*bw{1'b0}}; 
reg mode = 0;              
reg mode_q = 0;            
reg [bw-1:0] weights_arr [0:col-1];
integer ret;

assign Relu_en_c = Relu_en_q;
assign inst_q[45:36] = A_pmem_out_q;
assign inst_q[35] = CEN_pmem_out_q;
assign inst_q[34] = WEN_pmem_out_q;
assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19] = CEN_xmem_q;
assign inst_q[18] = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6] = ofifo_rd_q;
assign inst_q[5] = ififo_wr_q;
assign inst_q[4] = ififo_rd_q;
assign inst_q[3] = l0_rd_q;
assign inst_q[2] = l0_wr_q;
assign inst_q[1] = execute_q;
assign inst_q[0] = load_q;
assign inst_q[46] = mode_q;

core #(.bw(bw), .col(col), .row(row)) core_instance (
	.clk(clk),
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
        .D_xmem(D_xmem_q),
	.sfp_out(sfp_out),
	.sram_sel_output(sram_sel_output),
	.sram_sel_fifo(sram_sel_fifo),
	.Relu_en (Relu_en_c),	
	.in_ififo_col(in_ififo_col),
	.reset(reset));


initial begin

    
    inst_w = 0;
    D_xmem = 0;
    CEN_pmem = 1;
    WEN_pmem = 1;
    CEN_pmem_out = 1;
    WEN_pmem_out = 1;
    A_pmem = 0;
    A_pmem_out = 0;
    CEN_xmem = 1;
    WEN_xmem = 1;
    A_xmem = 0;
    ofifo_rd = 0;
    ififo_wr = 0;
    ififo_rd = 0;
    l0_rd = 0;
    l0_wr = 0;
    execute = 0;
    load = 0;
    sram_sel_output = 0;
    sram_sel_fifo = 0;
    Relu_en = 0;
    mode = 0;

    $dumpfile("core_tb.vcd");
    $dumpvars(0,core_tb);

    // --------------------------------------------------
    // Activation data reading and writing to XMEM
    // --------------------------------------------------
    x_file = $fopen("Input_files/activation_padded_new_1.txt", "r");
  
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

   
    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;

    for (i=0; i<10 ; i=i+1) begin
        #1.0 clk = ~clk;
    end

    #0.5 clk = 1'b0; reset = 0;
    #0.5 clk = 1'b1;

    
    A_xmem = 0; 
    for (t=0; t<len_nij; t=t+1) begin
        #0.5 clk = 1'b0;
        x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
        WEN_xmem = 0; CEN_xmem = 0;
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;
    end

    #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1;

    $fclose(x_file);


    for (kij=0; kij<9; kij=kij+1) begin // kij loop

   
        case(kij)
        0: w_file_name = "weight_kij_new_0.txt";
        1: w_file_name = "weight_kij_new_1.txt";
        2: w_file_name = "weight_kij_new_2.txt";
        3: w_file_name = "weight_kij_new_3.txt";
        4: w_file_name = "weight_kij_new_4.txt";
        5: w_file_name = "weight_kij_new_5.txt";
        6: w_file_name = "weight_kij_new_6.txt";
        7: w_file_name = "weight_kij_new_7.txt";
        8: w_file_name = "weight_kij_new_8.txt";
        endcase


        w_file = $fopen(w_file_name, "r");
        // Skip headers again
        w_scan_file = $fscanf(w_file,"%s", captured_data);
        w_scan_file = $fscanf(w_file,"%s", captured_data);
        w_scan_file = $fscanf(w_file,"%s", captured_data);

        #0.5 clk = 1'b0; reset = 1;
        #0.5 clk = 1'b1;

        for (i=0; i<5 ; i=i+1) #1.0 clk = ~clk; 

        #0.5 clk = 1'b0; reset = 0;
        #0.5 clk = 1'b1;

        
        //in_ififo_col = {col*bw{1'b0}};

        // --------------------------------------------------
        // Kernel data reading from file, writing to XMEM and preparing IFIFO
        // --------------------------------------------------
        A_xmem = 11'b10000000000;

        for (t=0 ; t<col; t=t+1) begin
	weights_arr[t] = {bw{1'b0}};
        end 	
        for (t=0; t<col; t=t+1) begin
            #0.5 clk = 1'b0;
            w_scan_file = $fscanf(w_file,"%32b", temp_word); 
            D_xmem = temp_word; 
            WEN_xmem = 0; CEN_xmem = 0;
            if (t>0) A_xmem = A_xmem + 1;

         
            weights_arr[t] = temp_word[bw-1:0];
            #0.5 clk = 1'b1;
        end

        #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1'b1;

        $fclose(w_file); 
       in_ififo_col = {col*bw{1'b0}}; 

        for (t=0; t<col; t=t+1) begin
            in_ififo_col[bw*t +: bw] = weights_arr[t]; 
        end
	$display("kij=%0d packed IFIFO in_col = %b",kij,in_ififo_col);

        #0.5 clk = 1'b0;
        ififo_wr = 1'b1; 
        #0.5 clk = 1'b1;

        #0.5 clk = 1'b0;
        ififo_wr = 0; 
        #0.5 clk = 1'b1;

        #5.0 clk = ~clk;


        

    $display("kij=%0d asserting ififo_rd+load to latch weights into PEs",kij);
    #0.5 clk = 1'b0;
    ififo_rd =1'b1;
    #0.5 clk = 1'b1;
    #0.5clk = 1'b0;
    ififo_rd = 1'b0;
    load = 1'b0;
    #0.5 clk = 1'b1;
    #2.0 clk = ~clk;

        // --------------------------------------------------
        // Activation Stream & Execution Phase
        // --------------------------------------------------
        A_xmem = 11'b00000000000; 

        
                #0.5 clk = 1'b0 ; WEN_xmem = 1; CEN_xmem = 0;
                #0.5 clk = 1'b1 ;

                for (j=0 ; j<len_nij ; j++) begin
                    #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 0; l0_wr = 1'b1;
                    if(j>0) A_xmem = A_xmem + 1; 
		    #0.5 clk = 1'b1;
	            #0.5 clk = 1'b0; l0_wr = 0; #0.5 clk =1'b1;
                end
                #0.5 clk = 1'b0;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;
                #0.5 clk = 1'b1;
		#2.0 clk = ~clk;

                #1.0 clk = ~clk;

              
                for( l=0; l<len_nij ; l++) begin 
                    #0.5 clk = 1'b0; l0_rd = 1'b1; execute = 1'b1;
                    #0.5 clk = 1'b1;
		    #0.5 clk = 1'b0; l0_rd =1'b0; execute = 1'b0;
		    #0.5 clk = 1'b1;
                end

		#50.0 clk = ~clk;



        A_pmem = 0;

        for( l=0; l<len_onij ; l++) begin 
            #0.5 clk = 1'b0;
            ofifo_rd = 1'b1; 
            WEN_pmem = 0; CEN_pmem = 0;
            if(l>0 || kij >0) A_pmem = A_pmem + 1; 
	    #0.5 clk = 1'b1;
            #0.5 clk = 1'b0;
	    ofifo_rd = 1'b0;
	    #0.5 clk = 1'b1;
        end

        #0.5 clk = 1'b0;
        WEN_pmem = 1; CEN_pmem = 1; ofifo_rd = 0; 
	#0.5 clk = 1'b1;


    end 


    // --------------------------------------------------
    // Final Accumulation and Verification Phase
    // --------------------------------------------------
    #0.5 clk = 1'b0; A_pmem = 11'b0;
    #0.5 clk = 1'b1;

    out_file = $fopen("Input_files/output_new.txt", "r");
    acc_file = $fopen("acc.txt","r");

   
    out_scan_file = $fscanf(out_file,"%s", captured_data);
    out_scan_file = $fscanf(out_file,"%s", captured_data);
    out_scan_file = $fscanf(out_file,"%s", captured_data);

    error = 0;

    $display("############ Verification Start #############");

    for (i=0; i<len_onij; i=i+1) begin

        out_scan_file = $fscanf(out_file,"%256b", answer);

      
        #0.5 clk = 1'b0; reset = 1;
        #0.5 clk = 1'b1;
        #0.5 clk = 1'b0; reset = 0;
        #0.5 clk = 1'b1;

  
        for (j=0; j<len_kij; j=j+1) begin

            #0.5 clk = 1'b0;
          
            acc_scan_file = $fscanf(acc_file,"%11b", A_pmem);
            CEN_pmem = 0; WEN_pmem = 1;

            if (j>0) acc = 1; 
            #0.5 clk = 1'b1;
        end

      
        #0.5 clk = 1'b0; acc = 0; CEN_pmem = 1;
        #0.5 clk = 1'b1;

     
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;

      
        out_scan_file = $fscanf(out_file,"%256b", answer);

        if (sfp_out == answer)
            $display("%2d-th output featuremap Data matched! :D", i);
        else begin
            $display("--- %2d-th output featuremap Data ERROR!! ---", i);
            $display("sfpout: %256b", sfp_out);
            $display("answer: %256b", answer);
            error = 1;
        end

        #0.5 clk = 1'b0; acc = 0; CEN_pmem = 1;
        #0.5 clk = 1'b1;
    end


    if (error == 0) begin
        $display("############ No error detected ##############");
        $display("########### Project Completed !! ############");
    end

    $fclose(acc_file);
    $fclose(out_file);
  
    for (t=0; t<10; t=t+1) begin
        #1.0 clk = ~clk;
    end

    #10 $finish;

end

always @ (posedge clk) begin
    
    inst_w_q    <= inst_w;
    D_xmem_q    <= D_xmem;
    CEN_xmem_q <= CEN_xmem;
    WEN_xmem_q <= WEN_xmem;
    A_pmem_q    <= A_pmem;
    CEN_pmem_q <= CEN_pmem;
    WEN_pmem_q <= WEN_pmem;
    A_xmem_q    <= A_xmem;
    ofifo_rd_q <= ofifo_rd;
    acc_q       <= acc;
    ififo_wr_q <= ififo_wr;
    ififo_rd_q <= ififo_rd;
    l0_rd_q     <= l0_rd;
    l0_wr_q     <= l0_wr ;
    execute_q   <= execute;
    load_q      <= load;
    Relu_en_q   <= Relu_en;
    CEN_pmem_out_q <= CEN_pmem_out;
    WEN_pmem_out_q <= WEN_pmem_out;
    A_pmem_out_q <= A_pmem_out;
    mode_q <= mode;
end


endmodule


