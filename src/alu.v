`timescale 1ns/1ps
`default_nettype none

//ALU : DECODE + ADDSUB + AND + SHIFTER, output mux picks the result
//aluopc: 0 MOV, 1 ADD, 2 SUB, 3 ADC, 4 SBC, 5 AND, 6 CMP, 7 SHIFT

module alu (
    input  wire [15:0] ina, //Ra
    input  wire [15:0] inb, //Rb or immediate
    input  wire [2:0] aluopc, //which operation
    input  wire [1:0] shiftopc, //which shift
    input  wire [3:0] scnt, //shift amount
    input  wire flagcin, //current carry flag
    output wire [15:0] out, //result
    output wire cout, //new carry flag
    output wire vout //new overflow flag
);

    wire invert, addsubcin; //DECODE -> ADDSUB
    wire [15:0] addsub_out, and_out, shift_out; //result from each block
    wire addsub_c, addsub_v, shift_c; //flags from each block

    aludecode DECODE (.aluopc(aluopc), .flagcin(flagcin), .invert(invert), .addsubcin(addsubcin));

    addsub ADDSUB (.ina(ina), .inb(inb), .invert(invert), .carryin(addsubcin),
                   .out(addsub_out), .cout(addsub_c), .v(addsub_v));

    assign and_out = ina & inb; //16 AND gates

    shifter SHIFT (.din(inb), .scnt(scnt), .shiftopc(shiftopc), .cin(flagcin),
                   .dout(shift_out), .cout(shift_c)); //shifts operate on Rb

    wire is_mov   = (aluopc == 3'd0);
    wire is_and   = (aluopc == 3'd5);
    wire is_shift = (aluopc == 3'd7);

    assign out = is_mov   ? inb : //output mux
                 is_and   ? and_out :
                 is_shift ? shift_out :
                 addsub_out; //ADD, SUB, ADC, SBC, CMP

    assign cout = is_shift ? shift_c : //shift: last bit out
                  (is_mov || is_and) ? flagcin : //MOV, AND: carry unchanged
                  addsub_c; //arithmetic: carry from adder

    assign vout = (is_mov || is_and || is_shift) ? 1'b0 : addsub_v; //overflow only from arithmetic

endmodule