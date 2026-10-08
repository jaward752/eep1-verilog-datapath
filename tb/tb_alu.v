`timescale 1ns/1ps

//TB_ALU : tests the ALU with 100,000 random inputs
//compares every answer against a reference model written with normal maths

module tb_alu;

    //inputs to the ALU
    reg  [15:0] ina, inb;
    reg  [2:0]  aluopc;
    reg  [1:0]  shiftopc;
    reg  [3:0]  scnt;
    reg         flagcin;

    //outputs from the ALU
    wire [15:0] out;
    wire        cout, vout;

    //the ALU being tested
    alu DUT (.ina(ina), .inb(inb), .aluopc(aluopc), .shiftopc(shiftopc), .scnt(scnt),
             .flagcin(flagcin), .out(out), .cout(cout), .vout(vout));

    //expected answers from the reference model
    reg [15:0] exp_out;
    reg        exp_c, exp_v;
    reg        check_out, check_c, check_v; //which outputs to check

    integer i, tests, errors, skipped, seed;
    integer count [0:7]; //tests per opcode
    integer ux, uy, sx, sy, cf, full;
    reg [31:0] t32;

    //random value, often an edge case (0, 1, 7FFF, 8000, FFFF)
    task pick(output [15:0] x);
        begin
            case ($random(seed) & 7)
                0: x = 16'h0000;
                1: x = 16'h0001;
                2: x = 16'h7FFF;
                3: x = 16'h8000;
                4: x = 16'hFFFF;
                default: x = $random(seed);
            endcase
        end
    endtask

    //reference model: what EEP1 should do, using normal maths
    task reference;
        begin
            ux = ina; uy = inb;                    //unsigned 0..65535
            sx = $signed(ina); sy = $signed(inb);  //signed -32768..32767
            cf = flagcin;
            check_out = 1; check_c = 1; check_v = 1;
            exp_c = flagcin; exp_v = 0;

            case (aluopc)
                3'd0: begin exp_out = inb; check_c = 0; check_v = 0; end //MOV
                3'd1: begin //ADD
                    full = ux + uy; exp_out = full; exp_c = (full > 65535);
                    full = sx + sy; exp_v = (full > 32767) || (full < -32768);
                end
                3'd2, 3'd6: begin //SUB, CMP
                    full = ux - uy; exp_out = full; exp_c = (ux >= uy);
                    full = sx - sy; exp_v = (full > 32767) || (full < -32768);
                end
                3'd3: begin //ADC
                    full = ux + uy + cf; exp_out = full; exp_c = (full > 65535);
                    full = sx + sy + cf; exp_v = (full > 32767) || (full < -32768);
                end
                3'd4: begin //SBC
                    full = ux - uy + cf - 1; exp_out = full; exp_c = (full >= 0);
                    full = sx - sy + cf - 1; exp_v = (full > 32767) || (full < -32768);
                end
                3'd5: begin exp_out = ina & inb; check_c = 0; check_v = 0; end //AND
                3'd7: begin //SHIFTS
                    check_v = 0; //V undefined after shift
                    case (shiftopc)
                        2'd0: begin t32 = {16'd0, inb} << scnt; exp_out = t32[15:0];
                                    exp_c = (scnt == 0) ? flagcin : t32[16]; end //LSL
                        2'd1: begin t32 = {inb, 16'd0} >> scnt; exp_out = t32[31:16];
                                    exp_c = (scnt == 0) ? flagcin : t32[15]; end //LSR
                        2'd2: begin t32 = $signed({inb, 16'd0}) >>> scnt; exp_out = t32[31:16];
                                    exp_c = (scnt == 0) ? flagcin : t32[15]; end //ASR
                        2'd3: begin //XSR: only check shifts of 0 or 1
                            if (scnt <= 1) begin
                                t32 = {inb, 16'd0} >> scnt; exp_out = t32[31:16];
                                if (scnt == 1) exp_out[15] = flagcin;
                                exp_c = (scnt == 0) ? flagcin : inb[0];
                            end else begin
                                check_out = 0; check_c = 0; skipped = skipped + 1;
                            end
                        end
                    endcase
                end
            endcase
        end
    endtask

    initial begin
        seed = 2026; tests = 0; errors = 0; skipped = 0;
        for (i = 0; i < 8; i = i + 1) count[i] = 0;

        for (i = 0; i < 100000; i = i + 1) begin
            pick(ina); pick(inb); //1. random inputs
            aluopc = $random(seed); shiftopc = $random(seed);
            scnt = $random(seed); flagcin = $random(seed);
            #1; //2. let the ALU settle
            reference; //3. work out the right answer
            tests = tests + 1; //4. compare
            count[aluopc] = count[aluopc] + 1;
            if ((check_out && (out !== exp_out)) ||
                (check_c && (cout !== exp_c)) ||
                (check_v && (vout !== exp_v))) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("MISMATCH opc=%0d sop=%0d scnt=%0d cin=%b a=%h b=%h | got %h c=%b v=%b | expected %h c=%b v=%b",
                             aluopc, shiftopc, scnt, flagcin, ina, inb, out, cout, vout, exp_out, exp_c, exp_v);
            end
        end

        $display("");
        $display("========== EEP1 ALU random test ==========");
        $display(" Tests run : %0d", tests);
        $display(" MOV %0d | ADD %0d | SUB %0d | ADC %0d | SBC %0d | AND %0d | CMP %0d | SHIFT %0d",
                 count[0], count[1], count[2], count[3], count[4], count[5], count[6], count[7]);
        $display(" XSR > 1 not checked: %0d", skipped);
        $display(" Mismatches: %0d", errors);
        if (errors == 0) $display(" RESULT: PASS");
        else             $display(" RESULT: FAIL");
        $display("==========================================");
        $finish;
    end

endmodule