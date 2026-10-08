`timescale 1ns/1ps
`default_nettype none

//SHIFTER : barrel shifter, 4 stages (1, 2, 4, 8) give any shift 0..15
//each stage turned on by one bit of scnt, carry passed stage to stage

module shifter (
    input  wire [15:0] din, //value to shift (Rb)
    input  wire [3:0] scnt, //shift amount 0..15
    input  wire [1:0] shiftopc, //0 LSL, 1 LSR, 2 ASR, 3 XSR
    input  wire cin, //current carry flag
    output wire [15:0] dout, //shifted result
    output wire cout //last bit shifted out
);

    wire [15:0] d1, d2, d4; //data between stages
    wire c1, c2, c4; //carry between stages

    shiftn #(.N(1)) SHIFT1 (.din(din), .en(scnt[0]), .shiftopc(shiftopc), .cin(cin), .dout(d1),   .cout(c1));
    shiftn #(.N(2)) SHIFT2 (.din(d1),  .en(scnt[1]), .shiftopc(shiftopc), .cin(c1),  .dout(d2),   .cout(c2));
    shiftn #(.N(4)) SHIFT4 (.din(d2),  .en(scnt[2]), .shiftopc(shiftopc), .cin(c2),  .dout(d4),   .cout(c4));
    shiftn #(.N(8)) SHIFT8 (.din(d4),  .en(scnt[3]), .shiftopc(shiftopc), .cin(c4),  .dout(dout), .cout(cout));

endmodule