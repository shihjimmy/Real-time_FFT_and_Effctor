`timescale 1ns / 100ps  // 時間單位/時間精度

module Initializer_Test ();

  localparam cycle = 10000;  // 100kHz

  logic rst, clk, start;
  logic finished, SCLK, OEN;
  wire SDAT;

  initial clk = 0;
  always #(cycle / 2.0) clk = ~clk;

  I2cInitializer init0 (
      .i_rst_n(rst),
      .i_clk(clk),
      .i_start(start),
      .o_finished(finished),
      .o_sclk(SCLK),
      .io_sdat(SDAT),
      .o_oen(OEN)  // you are outputing (you are not outputing only when you are "ack"ing.)
  );

  initial begin
    $fsdbDumpfile("Initializer_test.fsdb");
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

