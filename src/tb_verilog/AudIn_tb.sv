`timescale 1ns / 100ps  // 時間單位/時間精度

module Reocoder_Test ();

  localparam cycle = 10000;  // 100kHz

  // localparam data_tf_L = {
  //   16'b1111_1111_1111_1111,
  //   16'b1110_1101_1011_0111,
  //   16'b1100_1001_0011_0110,
  //   16'b1000_0001_0010_0100
  // };  // FSB first
  // localparam data_tf_R = {
  //   16'b0000_0000_0000_0000,
  //   16'b0001_0010_0100_1000,
  //   16'b0011_0110_1100_1001,
  //   16'b0111_1110_1101_1011
  // };

  logic [15:0] dL[4], dR[4];

  assign dL[0] = 16'b1111_1111_1111_1111;
  assign dR[0] = 16'b0000_0000_0000_0000;
  assign dL[1] = 16'b1110_1101_1011_0111;
  assign dR[1] = 16'b0001_0010_0100_1000;
  assign dL[2] = 16'b1100_1001_0011_0110;
  assign dR[2] = 16'b0011_0110_1100_1001;
  assign dL[3] = 16'b1000_0001_0010_0100;
  assign dR[3] = 16'b0111_1110_1101_1011;

  logic i_lrc, i_data;
  logic i_rst, i_clk, i_enable;
  logic [15:0] o_seq_l[16], o_seq_r[16];


  initial i_clk = 0;
  always #(cycle / 2.0) i_clk = ~i_clk;

  AudIn aud0 (
      .i_rst_n(i_rst),
      .i_clk(i_clk),
      .i_enable(i_enable),
      .i_lrc(i_lrc),
      .i_data(i_data),  // ADCDAT
      .o_seq_l(o_seq_l),
      .o_seq_r(o_seq_r)
  );

  initial begin
    $fsdbDumpfile("AubIn_Test.fsdb");
    $fsdbDumpvars(0, Reocoder_Test, "+all");
  end

  initial begin
    i_clk = 0;
    i_rst = 1;
    i_lrc = 1;  // right channel
    i_enable = 0;


    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_rst = 0;
    @(negedge i_clk) i_rst = 1;

    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_enable = 1;
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
  end

  initial begin
    @(negedge i_clk) i_lrc = 1;
    @(negedge i_clk);
    @(negedge i_clk);
    for (int i = 0; i < 4; i++) begin
      @(negedge i_clk) i_lrc = 0;
      for (int t = 0; t < 16; t++) begin
        @(negedge i_clk) i_data = dL[i][t];
      end
      @(negedge i_clk);
      @(negedge i_clk);
      @(negedge i_clk);
      @(negedge i_clk) i_lrc = 1;
      for (int t = 0; t < 16; t++) begin
        @(negedge i_clk) i_data = dR[i][t];
      end
      @(negedge i_clk);
      @(negedge i_clk);
      @(negedge i_clk);
    end

    // display results
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_lrc = 0;
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    for (int i = 0; i < 16; i++) begin
      $display("%d th | L: %b\tR: %b\n", i, o_seq_l[i], o_seq_r[i]);  // MSB first
    end
    $finish;
  end
endmodule

