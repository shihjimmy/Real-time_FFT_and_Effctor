`timescale 1ns / 100ps  // 時間單位/時間精度

module Initializer_Test ();

  localparam cycle = 10000;  // 100kHz

  logic rst, clk, start;
  logic finished, SCLK, OEN;
  wire SDAT;

  initial clk = 0;
  always #(cycle / 2.0) clk = ~clk;

  Rsa256Wrapper wrapper0 (
      .avm_rst(rst),  // input          avm_rst,
      .avm_clk(clk),  // input          avm_clk,
      .avm_address(),  // output [  4:0] avm_address,
      .avm_read(),  // output         avm_read,
      .avm_readdata(),  // input  [ 31:0] avm_readdata,
      .avm_write(),  // output         avm_write,
      .avm_writedata(),  // output [ 31:0] avm_writedata,
      .avm_waitrequest(),  // input          avm_waitrequest,
      // // frequencies to sent
      .freqs(),  // input  [127:0] freqs,            // 16 16bit frequency amplitude 
      // // parameters
      .threshold_gate(),  // output [ 15:0] threshold_gate,   // -inf ~ 0 (0 ~ 32767)
      .threshold_camp(),  // output [ 15:0] threshold_comp,   // -inf ~ 0 (0 ~ 32767)
      .ratio(),  // output [  4:0] ratio,            // 1:1 ~ 31:1
      .makeup()  // output [ 15:0] makeup            // (0 ~ 32767)
  );

  initial begin
    $fsdbDumpfile("Wrapper_test.fsdb");
    $fsdbDumpvars(0, Initializer_Test, "+all");
  end

  initial begin
    clk   = 0;
    rst   = 1;
    start = 0;

    @(negedge clk);
    @(negedge clk);
    @(negedge clk) rst = 0;
    @(negedge clk) rst = 1;

    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    @(negedge clk) start = 1;
    @(negedge clk);
    @(negedge clk) start = 0;
  end

  initial #(cycle * 10000000) $finish;

endmodule

