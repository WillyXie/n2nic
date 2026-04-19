// ALU
`define AluopAdd     4'b0000
`define AluopSub     4'b1000
`define AluopSll     4'b0001
`define AluopSlt     4'b0010
`define AluopSltu    4'b0011
`define AluopXor     4'b0100
`define AluopSrl     4'b0101
`define AluopSra     4'b1101
`define AluopOr      4'b0110
`define AluopAnd     4'b0111

module ALU(
  input  logic  [31:0]  op1,
  input  logic  [31:0]  op2,
  input  logic  [3:0]   aluop,

  output logic  [31:0]  result
);

always_comb begin
    result = 32'd0;
    case (aluop)
        `AluopAdd: begin    //4'b0000
            result = op1 + op2;
        end
        `AluopSub: begin    //4'b1000
            result = op1 - op2;
        end
        `AluopSll: begin    //4'b0001
            result = op1 << op2[4:0];
        end
        `AluopSlt: begin    //4'b0010
            result = (op1[31] > op2[31])? 32'd1 :
                      (op1[31] == op2[31])?((op1<op2)?32'd1:32'd0) :
                      32'd0;
        end
        `AluopSltu: begin   //4'b0011
            result = (op1 < op2)? 32'd1 : 32'd0;
        end
        `AluopXor: begin    //4'b0100
            result = op1 ^ op2;
        end
        `AluopSrl: begin    //4'b0101
            result = op1 >> op2[4:0];
        end
        `AluopSra: begin    //4'b1101
            result = $signed(op1) >>> op2[4:0];
        end
        `AluopOr: begin     //4'b0110
            result = op1 | op2;
        end
        `AluopAnd: begin    //4'b0111
            result = op1 & op2;
        end
    endcase
end

endmodule

