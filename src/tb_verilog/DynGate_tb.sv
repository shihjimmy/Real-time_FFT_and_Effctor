`timescale 1ns / 100ps  // 時間單位/時間精度

module Reocoder_Test ();

  localparam cycle = 10000;  // 100kHz

  logic [15:0] dL[16], dR[16];

  assign dL[0] = 16'b1111_1111_1111_1111;  // -1
  assign dR[0] = 16'b0000_0000_0000_0000;  // -4681
  assign dL[1] = 16'b1110_1101_1011_0111;  // 0
  assign dR[1] = 16'b0001_0010_0100_1000;  // 4680
  assign dL[2] = 16'b1100_1001_0011_0110;  // -14026
  assign dR[2] = 16'b0011_0110_1100_1001;  // 14025
  assign dL[3] = 16'b1000_0001_0010_0100;  // -32476
  assign dR[3] = 16'b0111_1110_1101_1011;  // 32475

  logic i_rst, i_clk, i_enable;
  logic [15:0] o_seq_l[16], o_seq_r[16];
  logic [14:0] thG, thC, makeup;
  logic [4:0] r;


  initial i_clk = 0;
  always #(cycle / 2.0) i_clk = ~i_clk;

  Dynamic_Gate hyn0 (
      .i_rst_n(i_rst),
      .i_clk(i_clk),  // BCLK
      .i_enable(i_enable),  // input signal is ready to read
      .threshold_gate(thG),  // -inf ~ 0 (0 ~ 32767)
      .threshold_comp(thC),  // -inf ~ 0 (0 ~ 32767)
      .ratio(r),  // 1:1 ~ 31:1
      .makeup(makeup),  // (0 ~ 32767)
      .i_seq_l(dL),
      .i_seq_r(dR),
      .o_seq_l(o_seq_l),
      .o_seq_r(o_seq_r)
  );

  initial begin
    $fsdbDumpfile("DynGate_Test.fsdb");
    $fsdbDumpvars(0, Reocoder_Test, "+all");
  end

  initial begin
    i_clk = 0;
    i_rst = 1;
    i_enable = 0;
    thG = 15'd6000;
    thC = 15'd10000;
    r = 5'd2;
    makeup = 0;
    $display("RhG: %d ThC: %d Ratio: %d Makeup: %d", thG, thC, r, makeup);  // MSB first

    @(negedge i_clk) i_rst = 0;
    @(negedge i_clk) i_rst = 1;
    @(negedge i_clk) i_enable = 0;
    @(negedge i_clk) i_enable = 1;
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
  end

  initial begin
    // display results
    for (int i = 0; i < 16; i++) begin
      o_seq_l[i] = 16'b1111_1111_1111_1111;
      $display("%d th | L: %b\tR: %b\n", i, o_seq_l[i], o_seq_r[i]);
    end
    $finish;
  end
endmodule

