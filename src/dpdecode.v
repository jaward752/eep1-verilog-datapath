`timescale 1ns/1ps
`default_nettype none

//DPDECODE : splits the instruction into fields and makes control signals
//op2sel = 1: ALU second operand is the immediate (else Rb)
//ad1sel = 1: write to Rc (else Ra)
//wen1   = 1: write the result to the register file (0 for CMP)

module dpdecode (
    input  wire [15:0] ins, //instruction word
    output wire [2:0] aluopc, //which ALU operation
    output wire [2:0] a, //field a (Ra)
    output wire [2:0] b, //field b (Rb)
    output wire [2:0] c, //field c (Rc)
    output wire [1:0] shiftopc, //which shift
    output wire [3:0] scnt, //shift amount
    output wire [15:0] imm, //immediate, sign extended to 16 bits
    output wire op2sel, //1 = use immediate
    output wire ad1sel, //1 = write to Rc
    output wire wen1, //register write enable
    output wire wen_nz, //update flags N and Z
    output wire wen_cv //update flags C and V
);

    wire is_alu = ~ins[15]; //bit 15 = 0 means ALU instruction

    assign aluopc = ins[14:12]; //fields are just wires from the right bits
    assign a = ins[11:9];
    assign b = ins[7:5];
    assign c = ins[4:2];
    assign shiftopc = {ins[8], ins[4]}; //shift opcode is split across bits 8 and 4
    assign scnt = ins[3:0];

    assign imm = {{8{ins[7]}}, ins[7:0]}; //sign extend: copy bit 7 into the top 8 bits

    assign op2sel = ins[8] && (aluopc != 3'd7); //immediate form, but bit 8 means something else for shifts

    assign ad1sel = ~ins[8] && (aluopc >= 3'd1) && (aluopc <= 3'd5); //3-register ADD/SUB/ADC/SBC/AND write Rc

    assign wen1 = is_alu && (aluopc != 3'd6); //CMP does not write a register

    assign wen_nz = is_alu; //N, Z written by every ALU instruction
    assign wen_cv = is_alu && (aluopc != 3'd0) && (aluopc != 3'd5); //C, V not written by MOV or AND

endmodule