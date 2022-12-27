// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
module AudPlayer (
    input         i_rst_n,
    input         i_bclk,       // clk in WM8731
    input         i_daclrck,    // input from WM8731
    input         i_en,         // enable AudPlayer only when playing audio, work with AudDSP
    input  [15:0] i_dac_l,      // processed audio sequence (left channel)
    input  [15:0] i_dac_r,      // processed audio sequence (right channel)
    output        o_aud_dacdat  // output data to WM8731
);

  localparam S_IDLE = 0;
  localparam S_PLAY_L = 1;
  localparam S_PLAY_R = 2;

  logic [1:0] state_r, state_w;
  logic [3:0] count_r, count_w;
  logic [15:0] output_r, output_w;
  logic last_dalrck;

  assign o_aud_dacdat = output_r[15];

  always_comb begin
    state_w  = state_r;
    count_w  = count_r;
    output_w = output_r;

    case (state_r)
      S_IDLE: begin
        count_w = 0;
        if (i_en && last_dalrck && (!i_daclrck)) begin
          // when i_en is 1 and i_daclrck falls to 0 after 1 clk
          // last_dalrck remember i_dalrck in 1 clk before
          state_w  = S_PLAY_L;
          output_w = i_dac_l;
        end else if (i_en && (!last_dalrck) && i_daclrck) begin
          state_w  = S_PLAY_R;
          output_w = i_dac_r;
        end
      end

      S_PLAY_L: begin
        if (&count_r) begin
          //already send 16 bits,so count_r is 1111
          state_w = S_IDLE;
          count_w = 0;
        end else begin
          state_w  = S_PLAY_L;
          output_w = output_r << 1;
          count_w  = count_r + 1;
        end
      end

      S_PLAY_R: begin
        if (&count_r) begin
          //already send 16 bits,so count_r is 1111
          state_w = S_IDLE;
          count_w = 0;
        end else begin
          state_w  = S_PLAY_R;
          output_w = output_r << 1;
          count_w  = count_r + 1;
        end
      end

      default: begin
        state_w  = S_IDLE;
        count_w  = 0;
        output_w = 0;
      end
    endcase
  end

  always_ff @(posedge i_bclk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      state_r <= S_IDLE;
      output_r <= 0;
      count_r <= 0;
      last_dalrck <= i_daclrck;
    end else begin
      state_r <= state_w;
      output_r <= output_w;
      count_r <= count_w;
      last_dalrck <= i_daclrck;
    end
  end

endmodule
