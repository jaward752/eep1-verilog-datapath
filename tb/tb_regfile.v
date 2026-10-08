`timescale 1ns/1ps

//TB_REGFILE : checks write, read, write enable and reset

module tb_regfile;

    reg clk = 0;
    reg rst = 1;
    reg wen1 = 0;
    reg [2:0] ad1 = 0, ad2 = 0, ad3 = 0;
    reg [15:0] din1 = 0;
    wire [15:0] dout2, dout3;
    integer errors = 0;

    regfile DUT (.clk(clk), .rst(rst), .wen1(wen1), .ad1(ad1), .din1(din1),
                 .ad2(ad2), .dout2(dout2), .ad3(ad3), .dout3(dout3));

    always #5 clk = ~clk; //clock: 10 ns period

    //write value to register n on the next rising edge
    task write(input [2:0] n, input [15:0] value);
        begin
            @(negedge clk); //change inputs away from the rising edge
            wen1 = 1; ad1 = n; din1 = value;
            @(negedge clk); //rising edge happens in between
            wen1 = 0;
        end
    endtask

    //read register n on port 2 and check the value
    task check(input [2:0] n, input [15:0] expected);
        begin
            ad2 = n; #1;
            if (dout2 === expected) $display("PASS  R%0d = %h", n, dout2);
            else begin $display("FAIL  R%0d = %h, expected %h", n, dout2, expected); errors = errors + 1; end
        end
    endtask

    initial begin
        $dumpfile("regfile.vcd"); $dumpvars(0, tb_regfile);

        @(negedge clk); @(negedge clk); rst = 0; //reset for one rising edge

        $display("-- after reset, all registers 0");
        check(0, 16'h0000); check(7, 16'h0000);

        $display("-- write and read back");
        write(3, 16'h1234);
        write(7, 16'hBEEF);
        check(3, 16'h1234);
        check(7, 16'hBEEF);
        check(0, 16'h0000); //R0 untouched

        $display("-- wen1 = 0 must NOT write");
        @(negedge clk); wen1 = 0; ad1 = 3; din1 = 16'hFFFF;
        @(negedge clk);
        check(3, 16'h1234); //still the old value

        $display("-- both read ports at once");
        ad2 = 3; ad3 = 7; #1;
        if (dout2 === 16'h1234 && dout3 === 16'hBEEF) $display("PASS  dout2=%h dout3=%h", dout2, dout3);
        else begin $display("FAIL  dout2=%h dout3=%h", dout2, dout3); errors = errors + 1; end

        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule