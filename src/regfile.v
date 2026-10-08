`timescale 1ns/1ps
`default_nettype none

//REGFILE : 8 registers (R0-R7) x 16 bits
//write: clocked, on the rising edge if wen1 = 1
//read: combinational, dout changes as soon as the address changes

module regfile (
    input  wire clk, //clock
    input  wire rst, //reset: all registers to 0
    input  wire wen1, //write enable
    input  wire [2:0] ad1, //which register to write
    input  wire [15:0] din1, //data to write (from the ALU)
    input  wire [2:0] ad2, //read address 2 (field a)
    output wire [15:0] dout2, //Ra
    input  wire [2:0] ad3, //read address 3 (field b)
    output wire [15:0] dout3 //Rb
);

    reg [15:0] r0, r1, r2, r3, r4, r5, r6, r7; //the 8 registers (flip-flops)

    wire [7:0] we = wen1 ? (8'b0000_0001 << ad1) : 8'b0000_0000; //decoder: one enable per register

    always @(posedge clk) begin //on the rising clock edge
        if (rst) begin
            r0 <= 16'd0; r1 <= 16'd0; r2 <= 16'd0; r3 <= 16'd0;
            r4 <= 16'd0; r5 <= 16'd0; r6 <= 16'd0; r7 <= 16'd0;
        end else begin
            if (we[0]) r0 <= din1; //only the enabled register loads
            if (we[1]) r1 <= din1; //the others keep their value
            if (we[2]) r2 <= din1;
            if (we[3]) r3 <= din1;
            if (we[4]) r4 <= din1;
            if (we[5]) r5 <= din1;
            if (we[6]) r6 <= din1;
            if (we[7]) r7 <= din1;
        end
    end

    assign dout2 = (ad2 == 3'd0) ? r0 : (ad2 == 3'd1) ? r1 : //8 to 1 mux for read port 2
                   (ad2 == 3'd2) ? r2 : (ad2 == 3'd3) ? r3 :
                   (ad2 == 3'd4) ? r4 : (ad2 == 3'd5) ? r5 :
                   (ad2 == 3'd6) ? r6 : r7;

    assign dout3 = (ad3 == 3'd0) ? r0 : (ad3 == 3'd1) ? r1 : //8 to 1 mux for read port 3
                   (ad3 == 3'd2) ? r2 : (ad3 == 3'd3) ? r3 :
                   (ad3 == 3'd4) ? r4 : (ad3 == 3'd5) ? r5 :
                   (ad3 == 3'd6) ? r6 : r7;

endmodule