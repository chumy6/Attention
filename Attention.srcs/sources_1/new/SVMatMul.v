// SVMatMul.v
// Third stage of pipeline: SVMatMul
/*
`include "FPMatMul.v"
`include "Dff.v"
*/
module SVMatMul#(
  parameter DATA_WIDTH = 16, // 8 MSBs integer part, 8 LSBs decimal part
  parameter TOKEN_DIM = 4,  //token维度，vit中为64
  parameter TOKEN_NUM = 8   //token个数，一个头有197个token,总共有12个头
)(
  input clk,
  input rst_n,

  input [DATA_WIDTH * TOKEN_NUM * TOKEN_NUM - 1 : 0] S_in,
  input [DATA_WIDTH * TOKEN_DIM * TOKEN_NUM - 1 : 0] V_in,

  output [DATA_WIDTH * TOKEN_DIM * TOKEN_NUM - 1 : 0] token_out
);

    wire [DATA_WIDTH * TOKEN_DIM * TOKEN_NUM - 1 : 0] token;
    
    FPMatMul#(
      .INPUT_DATA_WIDTH(DATA_WIDTH),
      .OUTPUT_DATA_WIDTH(DATA_WIDTH),
      .ROW_1(TOKEN_NUM),
      .COL_1(TOKEN_NUM),
      .ROW_2(TOKEN_NUM),
      .COL_2(TOKEN_DIM)
    ) MatmulUnit(
      .in_1(S_in),
      .in_2(V_in),
      .out(token)
    );
    
    Dff#(
      .DATA_WIDTH(DATA_WIDTH * TOKEN_DIM * TOKEN_NUM)
    ) TokenOutReg(
        .clk(clk),
      .rst_n(rst_n),
    
      .d(token),
      .q(token_out)
    );

endmodule