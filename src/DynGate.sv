module Dynamic_Gate (
  input i_rst_n,
  input i_clk,  // BCLK
  // input i_enable,  // input signal is ready to read
  input [15:0] threshold_gate,  // -inf ~ 0 (0 ~ 32767)
  input [15:0] threshold_comp,  // -inf ~ 0 (0 ~ 32767)
  input [4:0] ratio,    // 1:1 ~ 31:1
  input [15:0] makeup,  // (0 ~ 32767)
  input [15:0] i_seq_l[16],
  input [15:0] i_seq_r[16],
  output [15:0] o_seq_l[16],
  output [15:0] o_seq_r[16]
);

  integer i;
  always_ff@ (posedge i_clk) begin
    for (i=0; i<16; i=i+1) begin
      o_seq_l[i] <= (i_seq_l[i]<threshold_gate) ? 0 : ((i_seq_l[i]<=threshold_comp) ? i_seq_l[i]*makeup : i_seq_l[i]*makeup/ratio);
      o_seq_r[i] <= (i_seq_r[i]<threshold_gate) ? 0 : ((i_seq_r[i]<=threshold_comp) ? i_seq_r[i]*makeup : i_seq_r[i]*makeup/ratio);
    end
  end

endmodule