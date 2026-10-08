// =============================================================================
// tb_datapath.v  -  Runs real EEP1 machine code through the datapath
// =============================================================================
// Feeds one instruction per clock cycle (the testbench plays the part of the
// instruction memory and program counter, which are Lab 2) and checks the
// registers and flags at the end of each program.
//
// Programs:
//   1. Lab 1 Task 3 (Figure 5)       : MOV / ADD, register and immediate forms
//   2. Lab 1 challenge (Figure 7)    : add R0..R3 into R4
//   3. 32-bit addition using ADC     : carry passed from one 16-bit word to the next
//   4. AND, LSL and CMP              : CMP must change flags but not registers
//
// Run:
//   iverilog -o dp_test addsub.v aludecode.v shiftn.v shifter.v alu.v regfile.v dpdecode.v datapath.v tb_datapath.v
//   vvp dp_test
// Waveforms: open datapath.vcd with WaveTrace (or GTKWave).
// =============================================================================
`timescale 1ns/1ps

module tb_datapath;

    reg         clk = 0;
    reg         rst = 1;
    reg  [15:0] ins = 16'hC100;    // 0xC100 = NOP (a jump that never jumps)

    datapath DUT (.clk(clk), .rst(rst), .ins(ins));

    // clock: flips every 5 ns -> one cycle every 10 ns
    always #5 clk = ~clk;

    reg [15:0] prog [0:15];        // the program (plays the role of code memory)
    integer    errors = 0;

    // ---- read register n (looks inside the design by hierarchical name) -----
    function [15:0] R(input [2:0] n);
        case (n)
            3'd0: R = DUT.REGFILE.r0;  3'd1: R = DUT.REGFILE.r1;
            3'd2: R = DUT.REGFILE.r2;  3'd3: R = DUT.REGFILE.r3;
            3'd4: R = DUT.REGFILE.r4;  3'd5: R = DUT.REGFILE.r5;
            3'd6: R = DUT.REGFILE.r6;  3'd7: R = DUT.REGFILE.r7;
        endcase
    endfunction

    // ---- print the state after a cycle ---------------------------------------
    task show(input integer cycle);
        $display("  cycle %0d  INS=%h | R0=%h R1=%h R2=%h R3=%h R4=%h R5=%h R6=%h R7=%h | NZCV=%b%b%b%b",
                 cycle, prog[cycle], R(0), R(1), R(2), R(3), R(4), R(5), R(6), R(7),
                 DUT.flagn, DUT.flagz, DUT.flagc, DUT.flagv);
    endtask

    // ---- reset, then run the first n instructions of prog --------------------
    // Inputs are changed on the FALLING edge so they are stable when the
    // datapath samples them on the RISING edge.
    task run(input integer n);
        integer k;
        begin
            @(negedge clk) begin rst = 1; ins = 16'hC100; end
            @(negedge clk) rst = 0;                // a rising edge in between resets everything
            for (k = 0; k < n; k = k + 1) begin
                ins = prog[k];                     // present the instruction...
                @(negedge clk);                    // ...rising edge in between executes it
                show(k);
            end
            ins = 16'hC100;                        // NOP so nothing more happens
        end
    endtask

    // ---- checks ---------------------------------------------------------------
    task expect_reg(input [2:0] n, input [15:0] value);
        if (R(n) === value)
            $display("    PASS  R%0d = %h", n, value);
        else begin
            $display("    FAIL  R%0d = %h, expected %h", n, R(n), value);
            errors = errors + 1;
        end
    endtask

    task expect_flags(input [3:0] nzcv);
        if ({DUT.flagn, DUT.flagz, DUT.flagc, DUT.flagv} === nzcv)
            $display("    PASS  NZCV = %b", nzcv);
        else begin
            $display("    FAIL  NZCV = %b%b%b%b, expected %b",
                     DUT.flagn, DUT.flagz, DUT.flagc, DUT.flagv, nzcv);
            errors = errors + 1;
        end
    endtask

    // ---- the programs ---------------------------------------------------------
    initial begin
        $dumpfile("datapath.vcd");
        $dumpvars(0, tb_datapath);

        // ---------------------------------------------------------------------
        $display("\nProgram 1: Lab 1 Task 3 (Figure 5)");
        prog[0] = 16'h0103;   // MOV R0, #3
        prog[1] = 16'h0200;   // MOV R1, R0
        prog[2] = 16'h1301;   // ADD R1, #1
        prog[3] = 16'h102C;   // ADD R3, R0, R1
        run(4);
        expect_reg(0, 16'd3);
        expect_reg(1, 16'd4);
        expect_reg(3, 16'd7);

        // ---------------------------------------------------------------------
        $display("\nProgram 2: Lab 1 challenge (Figure 7) - R4 = R0 + R1 + R2 + R3");
        prog[0] = 16'h010C;   // MOV R0, #12
        prog[1] = 16'h03F9;   // MOV R1, #-7
        prog[2] = 16'h05E9;   // MOV R2, #233   <- doesn't fit in a signed 8-bit immediate!
        prog[3] = 16'h0701;   // MOV R3, #1
        prog[4] = 16'h1030;   // ADD R4, R0, R1
        prog[5] = 16'h1850;   // ADD R4, R4, R2
        prog[6] = 16'h1870;   // ADD R4, R4, R3
        run(7);
        expect_reg(0, 16'h000C);   //  12
        expect_reg(1, 16'hFFF9);   //  -7
        expect_reg(2, 16'hFFE9);   //  233 = 0xE9 is sign-extended -> -23, not 233
        expect_reg(3, 16'h0001);   //   1
        expect_reg(4, 16'hFFEF);   //  12 - 7 - 23 + 1 = -17

        // ---------------------------------------------------------------------
        $display("\nProgram 3: 32-bit addition  R1:R0 + R3:R2 -> R5:R4");
        $display("           0x0000FFFF + 0x00000001 = 0x00010000");
        prog[0] = 16'h01FF;   // MOV R0, #-1     R1:R0 = 0x0000_FFFF
        prog[1] = 16'h0300;   // MOV R1, #0
        prog[2] = 16'h0501;   // MOV R2, #1      R3:R2 = 0x0000_0001
        prog[3] = 16'h0700;   // MOV R3, #0
        prog[4] = 16'h1050;   // ADD R4, R0, R2  low words:  FFFF + 0001 = 0000, carry C = 1
        prog[5] = 16'h3274;   // ADC R5, R1, R3  high words: 0000 + 0000 + C = 0001
        run(6);
        expect_reg(4, 16'h0000);
        expect_reg(5, 16'h0001);

        // ---------------------------------------------------------------------
        $display("\nProgram 4: AND, LSL and CMP");
        prog[0] = 16'h0105;   // MOV R0, #5
        prog[1] = 16'h0307;   // MOV R1, #7
        prog[2] = 16'h502C;   // AND R3, R0, R1   5 & 7 = 5
        prog[3] = 16'h7423;   // LSL R2, R1, #3   7 << 3 = 56 = 0x38
        prog[4] = 16'h6020;   // CMP R0, R1       5 - 7: flags only, R0 unchanged
        run(5);
        expect_reg(0, 16'd5);      // CMP did NOT overwrite R0 (WEN1 = 0)
        expect_reg(3, 16'd5);
        expect_reg(2, 16'h0038);
        expect_flags(4'b1000);     // 5 - 7 is negative: N=1, Z=0, C=0 (borrow), V=0

        // ---------------------------------------------------------------------
        $display("\n================ EEP1 datapath programs ================");
        if (errors == 0) $display(" RESULT: PASS - all programs correct");
        else             $display(" RESULT: FAIL - %0d checks failed", errors);
        $display("=========================================================");
        $finish;
    end

endmodule