// Branch Control Unit

module Branch(
  input  logic  [31:0]  rs1,
  input  logic  [31:0]  rs2,
  input  logic  [2:0]   funct3,
  input  logic          branch,
  input  logic          jump,
  // control
  output logic          flush
);

logic taken;
assign flush = (taken)? 1'b1 : 1'b0;

always_comb begin
    if (jump) begin
       taken = 1'b1;
    end
    else if (branch) begin
        case (funct3)
            3'b000: taken = (rs1 == rs2)? 1'b1 : 1'b0;
            3'b001: taken = (rs1 != rs2)? 1'b1 : 1'b0;
            3'b100: begin
                if (rs1[31]<rs2[31]) taken = 1'b0;
                else if(rs1[31]>rs2[31]) taken = 1'b1;
                else if(rs1 < rs2) taken = 1'b1;
                else taken = 1'b0;
            end
            3'b101: begin
                if (rs1[31]<rs2[31]) taken = 1'b1;
                else if(rs1[31]>rs2[31]) taken = 1'b0;
                else if(rs1 < rs2) taken = 1'b0;
                else taken = 1'b1;
            end
            3'b110: taken = (rs1 >= rs2)? 1'b0 : 1'b1;
            3'b111: taken = (rs1 >= rs2)? 1'b1 : 1'b0;
	    default: taken = 1'b0;
        endcase
    end
    else begin
        taken = 1'b0;
    end
end


endmodule
