`timescale 1ns/1ps
`default_nettype none

//ADDSUB : one adder for ADD, SUB, ADC, SBC, CMP
//invert = 0: out = ina + inb + carryin
//invert = 1: out = ina + ~inb + carryin

module addsub (
    input  wire [15:0] ina, //Ra
    input  wire [15:0] inb, //Rb
    input  wire invert, //invert Rb
    input  wire carryin, //Cin
    output wire [15:0] out, //Result
    output wire cout, //Cout
    output wire v //signed overflow 
);

    wire [15:0] inb2 = invert ? ~inb : inb; //passes either inb or ~inb

    wire [16:0] sum = {1'b0, ina} + {1'b0, inb2} + carryin; //17 bit sum so the carry out lands in bit 16

    assign out  = sum[15:0]; //result 
    assign cout = sum[16]; //carryout

    assign v = (ina[15] == inb2[15]) && (out[15] != ina[15]); //overflow 

endmodule

