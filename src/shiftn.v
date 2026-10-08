`timescale 1ns/1ps
`default_nettype none

//SHIFTN : one barrel shifter stage, shifts by N bits when en = 1
//used 4 times with N = 1, 2, 4, 8 (SHIFT1, SHIFT2, SHIFT4, SHIFT8)

module shiftn #(parameter N = 1) ( //N = how many bits this stage shifts
    input  wire [15:0] din, //data in
    input  wire en, //1 = shift, 0 = pass through
    input  wire [1:0] shiftopc, //0 LSL, 1 LSR, 2 ASR, 3 XSR
    input  wire cin, //carry in
    output wire [15:0] dout, //data out
    output wire cout //carry out (last bit shifted out)
);

    wire fill = (shiftopc == 2'd2) ? din[15] : //ASR: fill with sign bit
                (shiftopc == 2'd3) ? cin : //XSR: fill with carry
                1'b0; //LSL, LSR: fill with 0

    wire left = (shiftopc == 2'd0); //only LSL shifts left

    wire [15:0] left_out  = {din[15-N:0], {N{fill}}}; //drop top N bits, fill on right
    wire [15:0] right_out = {{N{fill}}, din[15:N]}; //drop bottom N bits, fill on left

    assign dout = !en ? din : //not enabled: pass through
                  left ? left_out : right_out;

    assign cout = !en ? cin : //not enabled: carry unchanged
                  left ? din[16-N] : din[N-1]; //last bit to fall off

endmodule