`timescale 1ns/1ps
`default_nettype none

//DATAPATH : EEP1 datapath from Lab 1 (decoder + register file + ALU + flags)
//one instruction per clock cycle, fed in on ins

module datapath (
    input  wire clk, //clock
    input  wire rst, //reset
    input  wire [15:0] ins //instruction to execute this cycle
);

    wire [2:0] aluopc, a, b, c; //from the decoder
    wire [1:0] shiftopc;
    wire [3:0] scnt;
    wire [15:0] imm;
    wire op2sel, ad1sel, wen1, wen_nz, wen_cv;

    wire [15:0] reg_a, reg_b; //register file outputs (Ra, Rb)
    wire [15:0] alu_out; //ALU result
    wire alu_c, alu_v; //ALU flags

    reg flagn, flagz, flagc, flagv; //flag flip-flops

    dpdecode DPDECODE (.ins(ins), .aluopc(aluopc), .a(a), .b(b), .c(c),
                       .shiftopc(shiftopc), .scnt(scnt), .imm(imm),
                       .op2sel(op2sel), .ad1sel(ad1sel), .wen1(wen1),
                       .wen_nz(wen_nz), .wen_cv(wen_cv));

    wire [2:0] ad1 = ad1sel ? c : a; //ad1sel mux: write to Rc or Ra

    regfile REGFILE (.clk(clk), .rst(rst), .wen1(wen1), .ad1(ad1), .din1(alu_out), //ALU result written back
                     .ad2(a), .dout2(reg_a), //field a -> Ra
                     .ad3(b), .dout3(reg_b)); //field b -> Rb

    wire [15:0] op2 = op2sel ? imm : reg_b; //op2sel mux: immediate or Rb

    alu ALU (.ina(reg_a), .inb(op2), .aluopc(aluopc), .shiftopc(shiftopc), .scnt(scnt),
             .flagcin(flagc), .out(alu_out), .cout(alu_c), .vout(alu_v));

    always @(posedge clk) begin //flags update on the clock edge
        if (rst) begin
            flagn <= 1'b0; flagz <= 1'b0; flagc <= 1'b0; flagv <= 1'b0;
        end else begin
            if (wen_nz) begin
                flagn <= alu_out[15]; //N: result negative (sign bit)
                flagz <= (alu_out == 16'd0); //Z: result zero
            end
            if (wen_cv) begin
                flagc <= alu_c; //C: carry
                flagv <= alu_v; //V: signed overflow
            end
        end
    end

endmodule
