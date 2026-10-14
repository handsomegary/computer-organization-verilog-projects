`timescale 1ns/1ps
// End-to-end smoke check of each module's built-in instruction ROM, without
// changing its ROM, registers or data memory from the testbench.
module reference_demo_tb;
  reg clk = 0;
  reg reset = 1;
  wire [31:0] single_pc, pipeline_pc, hazard_pc;
  wire pipeline_stall, hazard_stall;
  integer i, errors;
  reg [31:0] expected [0:31];
  reg [31:0] expected_word;
  mips_single_cycle single_dut(.clk(clk), .reset(reset), .pc(single_pc));
  mips_pipeline #(.HAZARD_ENABLE(0)) pipeline_dut(.clk(clk), .reset(reset), .pc(pipeline_pc), .stall(pipeline_stall));
  mips_pipeline #(.HAZARD_ENABLE(1)) hazard_dut(.clk(clk), .reset(reset), .pc(hazard_pc), .stall(hazard_stall));
  always #5 clk = ~clk;
  initial begin
    errors = 0;
    for (i = 0; i < 32; i = i + 1) expected[i] = 0;
    expected[1] = 12;
    expected[2] = 32'hfffffffc;
    expected[3] = 8;
    expected[4] = 16;
    expected[5] = 8;
    expected[6] = 24;
    expected[7] = 1;
    expected[8] = 24;
    expected[9] = 7;
    repeat (2) @(negedge clk);
    if (single_pc !== 0 || pipeline_pc !== 0 || hazard_pc !== 0)
      $fatal(1, "Reset PC must be zero in all three modes");
    reset = 0;
    repeat (100) @(negedge clk);
    for (i = 0; i < 32; i = i + 1) begin
      if (single_dut.regs[i] !== expected[i] || pipeline_dut.regs[i] !== expected[i] || hazard_dut.regs[i] !== expected[i]) begin
        $display("FAIL default register[%0d] single=%08x pipeline=%08x hazard=%08x expected=%08x",
          i, single_dut.regs[i], pipeline_dut.regs[i], hazard_dut.regs[i], expected[i]);
        errors = errors + 1;
      end
    end
    for (i = 0; i < 1024; i = i + 1) begin
      expected_word = (i == 100) ? 24 : 0;
      if (single_dut.dmem[i] !== expected_word || pipeline_dut.dmem[i] !== expected_word || hazard_dut.dmem[i] !== expected_word) begin
        $display("FAIL default data[%0d] single=%08x pipeline=%08x hazard=%08x expected=%08x",
          i, single_dut.dmem[i], pipeline_dut.dmem[i], hazard_dut.dmem[i], expected_word);
        errors = errors + 1;
      end
    end
    // Verify reset clears all registers and pipeline state while memory remains.
    reset = 1;
    repeat (2) @(negedge clk);
    if (single_pc !== 0 || pipeline_pc !== 0 || hazard_pc !== 0)
      $fatal(1, "Second reset PC must be zero in all three modes");
    for (i = 0; i < 32; i = i + 1) begin
      if (single_dut.regs[i] !== 0 || pipeline_dut.regs[i] !== 0 || hazard_dut.regs[i] !== 0) begin
        $display("FAIL register reset[%0d]", i);
        errors = errors + 1;
      end
    end
    if (single_dut.dmem[100] !== 24 || pipeline_dut.dmem[100] !== 24 || hazard_dut.dmem[100] !== 24)
      $fatal(1, "Reset must preserve the documented data memory contents");
    if (errors != 0) $fatal(1, "REFERENCE DEFAULT ROM FAIL errors=%0d", errors);
    $display("REFERENCE DEFAULT ROM PASS all_three_modes memory[400]=24 registers_and_reset_checked");
    $finish;
  end
endmodule
