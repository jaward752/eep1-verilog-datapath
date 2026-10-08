`timescale 1ns/1ps
`default_nettype none

//ALU.DECODE : sets invert and carryin for ADDSUB from the opcode
//ADD: a + b    SUB/CMP: a + ~b + 1    ADC: a + b + C    SBC: a + ~b + C

module aludecode (
    input  wire [2:0] aluopc, //opcode (bits 14:12)
    input  wire flagcin, //current carry flag
    output wire invert, //to ADDSUB invert
    output wire addsubcin //to ADDSUB carryin
);

    wire is_sub = (aluopc == 3'd2) || (aluopc == 3'd6); //SUB or CMP
    wire is_carry = (aluopc == 3'd3) || (aluopc == 3'd4); //ADC or SBC

    assign invert = is_sub || (aluopc == 3'd4); //invert b for SUB, CMP, SBC

    assign addsubcin = is_sub ? 1'b1 : //SUB, CMP: carry in 1
                       is_carry ? flagcin : //ADC, SBC: carry in = C flag
                       1'b0; //ADD (and anything else): carry in 0

endmodule