// AttnSoftmax
// Second stage of pipeline: softmax

/*
`include "Dff.v"
`include "MatSoftmax.v"
*/
module AttnSoftmax#(
  parameter DATA_WIDTH = 16, // 8 MSBs integer part, 8 LSBs decimal part
  parameter TOKEN_DIM = 4, //token维度，vit中为64
  parameter TOKEN_NUM = 8  //token个数，一个头有197个token,总共有12个头
)(
  input clk,
  input rst_n,

  input [DATA_WIDTH * TOKEN_NUM * TOKEN_NUM - 1 : 0] A_in,
  input [DATA_WIDTH * TOKEN_DIM * TOKEN_NUM - 1 : 0] V_in,

  output [DATA_WIDTH * TOKEN_NUM * TOKEN_NUM - 1 : 0] S_out,
  output [DATA_WIDTH * TOKEN_DIM * TOKEN_NUM - 1 : 0] V_out
);

    wire [DATA_WIDTH * TOKEN_NUM * TOKEN_NUM - 1 : 0] S;
    
    MatSoftmax #(
      .INPUT_DATA_WIDTH(DATA_WIDTH),
      .OUTPUT_DATA_WIDTH(DATA_WIDTH),
      .ROW_IN(TOKEN_NUM),
      .COL_IN(TOKEN_NUM)
    ) MatSoftmaxUnit(
      .in(A_in),
      .out(S)
    );
    
    Dff#(
      .DATA_WIDTH(DATA_WIDTH * TOKEN_NUM * TOKEN_NUM)
    ) ScoreReg(
      .clk(clk),
      .rst_n(rst_n),
    
      .d(S),
      .q(S_out)
    );
    
    Dff#(
      .DATA_WIDTH(DATA_WIDTH * TOKEN_DIM * TOKEN_NUM)
    ) ValueReg(
      .clk(clk),
      .rst_n(rst_n),
    
      .d(V_in),
      .q(V_out)
    );

endmodule
