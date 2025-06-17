// top_tb.v
`timescale 1ns/1ps
//`include "Attention_top.v"

`define DATA_WIDTH 16  // 8 MSBs integer part, 8 LSBs decimal part
`define TOKEN_DIM 4  //token维度，vit中为64
`define TOKEN_NUM 8  //token个数，一个头有197个token,总共有12个头

module top_tb();

    reg [`DATA_WIDTH - 1 : 0] Q [0 : `TOKEN_NUM * `TOKEN_DIM - 1];
    reg [`DATA_WIDTH - 1 : 0] K [0 : `TOKEN_NUM * `TOKEN_DIM - 1];
    reg [`DATA_WIDTH - 1 : 0] V [0 : `TOKEN_NUM * `TOKEN_DIM - 1];
    
    reg [`DATA_WIDTH * `TOKEN_DIM * `TOKEN_NUM - 1 : 0] Q_in;
    reg [`DATA_WIDTH * `TOKEN_DIM * `TOKEN_NUM - 1 : 0] K_in;
    reg [`DATA_WIDTH * `TOKEN_DIM * `TOKEN_NUM - 1 : 0] V_in;
    
    wire [`DATA_WIDTH * `TOKEN_DIM * `TOKEN_NUM - 1 : 0] out;
    
    wire [`DATA_WIDTH : 0] out_mat [0 : `TOKEN_NUM - 1][0 : `TOKEN_DIM - 1];
    
    reg clk, rst_n;
    
    genvar i,j;
    generate
      for(i = 0; i < `TOKEN_NUM * `TOKEN_DIM; i = i + 1 ) begin
        always @( *) begin
          Q_in[`DATA_WIDTH * (i+1) - 1 : `DATA_WIDTH * i]=Q[i];
          K_in[`DATA_WIDTH * (i+1) - 1 : `DATA_WIDTH * i]=K[i];
          V_in[`DATA_WIDTH * (i+1) - 1 : `DATA_WIDTH * i]=V[i];
        end
      end
    endgenerate
    
    generate
      for (i = 0; i < `TOKEN_NUM; i = i + 1) begin
        for (j = 0; j < `TOKEN_DIM; j = j + 1) begin
         assign out_mat[i][j] = out[`DATA_WIDTH * (i * `TOKEN_DIM + j + 1) - 1 : `DATA_WIDTH * (i * `TOKEN_DIM + j)];
       end
      end
    endgenerate
    
    real tmp = (1<<8);
    
    wire [`DATA_WIDTH : 0]  A_tele[0 : `TOKEN_NUM - 1][0 : `TOKEN_NUM - 1];
    wire [`DATA_WIDTH : 0]  S_tele[0 : `TOKEN_NUM - 1][0 : `TOKEN_NUM - 1];
       
    generate
      for (i = 0; i < `TOKEN_NUM; i = i + 1) begin
        for (j = 0; j < `TOKEN_NUM; j = j + 1) begin
         assign A_tele[i][j] = 
         DUT.A_stage_1_to_2[`DATA_WIDTH * (i * `TOKEN_NUM + j + 1) - 1 : `DATA_WIDTH * (i * `TOKEN_NUM + j)];
         assign S_tele[i][j] = 
         DUT.S_stage_2_to_3[`DATA_WIDTH * (i * `TOKEN_NUM + j + 1) - 1 : `DATA_WIDTH * (i * `TOKEN_NUM + j)];
        end
      end
    endgenerate  
    
    Attention_top #(
      .DATA_WIDTH(`DATA_WIDTH),
      .TOKEN_DIM(`TOKEN_DIM),
      .TOKEN_NUM(`TOKEN_NUM)
    ) DUT(
      .clk(clk),
      .rst_n(rst_n),
      .Q(Q_in),
      .K(K_in),
      .V(V_in),
      .token_out(out)
    );
    
    integer index = 0;
    integer jndex = 0;
    
    integer test_times = 1;
    integer test_index = 0;
    
    integer fd_K, fd_Q, fd_V, fd_b, fd_f;
    integer err_K, err_Q, err_V, err_b, err_f;
    integer code_K, code_Q, code_V, code_b, code_f;
    
    reg [639 : 0] str_K, str_Q, str_V, str_b, str_f;
    
    initial begin
    
      $value$plusargs("test_times=%d", test_times);
    
      rst_n = 0;
      clk = 0;
      #5
      rst_n = 1;
    
      fd_K = $fopen("E:/2025_ViT_Based_FPGA/source_code/Attention/testbench/top/K_data.txt", "r");
      err_K = $ferror(fd_K, str_K);
      fd_Q = $fopen("E:/2025_ViT_Based_FPGA/source_code/Attention/testbench/top/Q_data.txt", "r");
      err_Q = $ferror(fd_Q, str_Q);
      fd_V = $fopen("E:/2025_ViT_Based_FPGA/source_code/Attention/testbench/top/V_data.txt", "r");
      err_V = $ferror(fd_V, str_V);
      fd_b = $fopen("E:/2025_ViT_Based_FPGA/source_code/Attention/generate/OUT_data_module_binary.txt", "w+");
      err_b = $ferror(fd_b, str_b);
      fd_f = $fopen("E:/2025_ViT_Based_FPGA/source_code/Attention/generate/OUT_data_module_float.txt", "w+");
      err_f = $ferror(fd_f, str_f);
    
      for (test_index = 0; test_index <test_times + 3; test_index = test_index + 1) begin
        if (test_index < test_times) begin 
          if (!err_K && !err_Q && !err_V) begin
            for (index = 0; index < `TOKEN_DIM * `TOKEN_NUM; index = index + 1) begin
              code_K = $fscanf(fd_K, "%b", K[index]);
              code_Q = $fscanf(fd_Q, "%b", Q[index]);
              code_V = $fscanf(fd_V, "%b", V[index]);
            end
          end
        end
    
        #5 clk = 1;
        #5 clk = 0;
    
        $display("clock period %d", test_index+1);
        $display("out binary:");
        for (index = 0; index < `TOKEN_NUM; index = index + 1) begin
          $write("[");
          for (jndex = 0; jndex < `TOKEN_DIM; jndex = jndex + 1)begin
            $write("%b, ",out_mat[index][jndex]);
            if (!err_b && test_index>=3) begin 
              $fwrite(fd_b, "%b\n", out_mat[index][jndex]);
            end
          end
          $write("]\n");
        end
    
        $display("out:");
        for (index = 0; index < `TOKEN_NUM; index = index + 1) begin
          $write("[");
          for (jndex = 0; jndex < `TOKEN_DIM; jndex = jndex + 1)begin
            $write("%.8f, ",out_mat[index][jndex][15 : 8] + out_mat[index][jndex][7 : 0] / tmp);
            if (!err_f && test_index>=3)begin
                $fwrite(fd_f, "%.8f\n",out_mat[index][jndex][15 : 8] + out_mat[index][jndex][7 : 0] / tmp);
            end
          end
          $write("]\n");
        end
        
      end    
      #5
        $fclose(fd_K); 
        $fclose(fd_Q);
        $fclose(fd_V);
        $fclose(fd_b);
        $fclose(fd_f);
        $finish;
    end

endmodule
