// Transpose.v
// transpose the input matrix

module Transpose#(
  parameter DATA_WIDTH = 16, // 8 MSBs integer part, 8 LSBs decimal part
  parameter ROW_IN = 8,  //token个数，一个头有197个token,总共有12个头
  parameter COL_IN = 4  //token维度，vit中为64
)(
  // input format: MSB{{MSB(n-1,m-1),LSB(n-1,m-1)},..., {MSB(0,1),LSB(0,1}, {MSB(0,0),LSB(0,0)}}LSB
  // (i,j) means the i-th row and j-th column data
    input [DATA_WIDTH * ROW_IN * COL_IN - 1 : 0] in,
    output [DATA_WIDTH * ROW_IN * COL_IN - 1 : 0] out
);

  localparam ROW_OUT = COL_IN;
  localparam COL_OUT = ROW_IN;

  //转置
  genvar i,j;
  generate
    for (i = 0; i < ROW_OUT; i = i + 1) begin
      for (j = 0; j < COL_OUT; j = j + 1) begin
        assign out[DATA_WIDTH * (i * COL_OUT + j + 1) - 1 : DATA_WIDTH * (i * COL_OUT + j)] = 
          in[DATA_WIDTH * (j * COL_IN + i + 1) - 1 : DATA_WIDTH * (j * COL_IN + i)];
      end
    end
  endgenerate

endmodule
