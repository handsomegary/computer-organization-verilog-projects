`timescale 1ns/1ps
// Independent architectural-state checker. The Python driver supplies complete
// instruction/data/register images and expectations computed by an ISA oracle.
module reference_tb;
  reg clk = 0;
  reg reset = 1;
  wire [31:0] pc;
  wire stall;
`ifdef REFERENCE_SINGLE
  mips_single_cycle dut(.clk(clk), .reset(reset), .pc(pc));
  assign stall = 1'b0;
`else
`ifdef REFERENCE_NO_HAZARDS
  mips_pipeline #(.HAZARD_ENABLE(0)) dut(.clk(clk), .reset(reset), .pc(pc), .stall(stall));
`else
  mips_pipeline #(.HAZARD_ENABLE(1)) dut(.clk(clk), .reset(reset), .pc(pc), .stall(stall));
`endif
`endif
  reg [31:0] expected_regs [0:31];
  reg [31:0] expected_data [0:1023];
  reg [8191:0] program_file, regs_file, data_file, expected_regs_file, expected_data_file, vcd_file;
  integer cycles, min_stalls, max_stalls, finish_pc;
  integer i, errors, stalls_seen;
  reg reached_finish;
  reg [31:0] held_pc;
  always #5 clk = ~clk;
  always @(posedge clk) begin
    if (!reset) begin
      if (pc === finish_pc) reached_finish = 1;
      if (stall === 1'b1) begin
        stalls_seen = stalls_seen + 1;
        held_pc = pc;
        #1;
        if (pc !== held_pc) begin
          $display("FAIL PC advanced during load-use stall old=%08x new=%08x", held_pc, pc);
          errors = errors + 1;
        end
      end
    end
  end
  initial begin
    errors = 0;
    stalls_seen = 0;
    reached_finish = 0;
    if (!$value$plusargs("PROGRAM=%s", program_file)) $fatal(1, "Missing PROGRAM");
    if (!$value$plusargs("REGS=%s", regs_file)) $fatal(1, "Missing REGS");
    if (!$value$plusargs("DATA=%s", data_file)) $fatal(1, "Missing DATA");
    if (!$value$plusargs("EXPECTED_REGS=%s", expected_regs_file)) $fatal(1, "Missing EXPECTED_REGS");
    if (!$value$plusargs("EXPECTED_DATA=%s", expected_data_file)) $fatal(1, "Missing EXPECTED_DATA");
    if (!$value$plusargs("CYCLES=%d", cycles)) $fatal(1, "Missing CYCLES");
    if (!$value$plusargs("FINISH_PC=%d", finish_pc)) $fatal(1, "Missing FINISH_PC");
    if (!$value$plusargs("MIN_STALLS=%d", min_stalls)) min_stalls = 0;
    if (!$value$plusargs("MAX_STALLS=%d", max_stalls)) max_stalls = 2147483647;
    if ($value$plusargs("VCD=%s", vcd_file)) begin
      $dumpfile(vcd_file);
      $dumpvars(0, reference_tb);
    end
    repeat (2) @(negedge clk);
    // Reset has been sampled on two rising edges. Set images away from the edge.
    $readmemh(program_file, dut.imem);
    $readmemh(regs_file, dut.regs);
    $readmemh(data_file, dut.dmem);
    $readmemh(expected_regs_file, expected_regs);
    $readmemh(expected_data_file, expected_data);
    reset = 0;
    repeat (cycles) @(negedge clk);
    for (i = 0; i < 32; i = i + 1) begin
      if (dut.regs[i] !== expected_regs[i]) begin
        $display("FAIL register[%0d] got=%08x expected=%08x", i, dut.regs[i], expected_regs[i]);
        errors = errors + 1;
      end
    end
    for (i = 0; i < 1024; i = i + 1) begin
      if (dut.dmem[i] !== expected_data[i]) begin
        $display("FAIL data[%0d] byte_address=%0d got=%08x expected=%08x", i, i*4, dut.dmem[i], expected_data[i]);
        errors = errors + 1;
      end
    end
    if (!reached_finish) begin
      $display("FAIL never reached completion PC=%0d", finish_pc);
      errors = errors + 1;
    end
    if (stalls_seen < min_stalls || stalls_seen > max_stalls) begin
      $display("FAIL stall_count=%0d expected_range=[%0d,%0d]", stalls_seen, min_stalls, max_stalls);
      errors = errors + 1;
    end
    if (errors != 0) $fatal(1, "REFERENCE FAIL errors=%0d stalls=%0d", errors, stalls_seen);
    $display("REFERENCE PASS cycles=%0d stalls=%0d finish_pc=%0d", cycles, stalls_seen, finish_pc);
    $finish;
  end
endmodule
