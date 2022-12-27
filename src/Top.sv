module Top (
    input i_rst_n,
    input i_clk,
    input i_key_0,  // enable bypass
    input i_key_1,  // pause
    input i_GETMUSIC,
    output fft_done,

    //input i_key_2,  // stop
    //input i_key_4,  // play backward
    // input [3:0] i_speed, // design how user can decide mode on your own
    // input i_mode,
    // 0 is play 1 is record
    // input i_slowPlayMode,
    // input [13:0] i_speed,
    // output o_i2c_fin,
    // output o_i2c_start,

    // AudDSP and SRAM
    // output [19:0] o_SRAM_ADDR,
    // inout  [15:0] io_SRAM_DQ,
    // output        o_SRAM_WE_N,
    // output        o_SRAM_CE_N,
    // output        o_SRAM_OE_N,
    // output        o_SRAM_LB_N,
    // output        o_SRAM_UB_N,
    // output o_state,

    // I2C
    input  i_clk_100k,
    output o_I2C_SCLK,
    inout  io_I2C_SDAT,

    // AudPlayer
    input  i_AUD_ADCDAT,
    inout  i_AUD_ADCLRCK,
    inout  i_AUD_BCLK,
    inout  i_AUD_DACLRCK,
    output o_AUD_DACDAT,

    // SEVENDECODER (optional display)
    //output [1:0] o_state,
    // output [4:0] o_sec_display
    // output [5:0] o_record_time,
    // output [5:0] o_play_time,

    // LCD (optional display)
    // input        i_clk_800k,
    // inout  [7:0] o_LCD_DATA,
    // output       o_LCD_EN,
    // output       o_LCD_RS,
    // output       o_LCD_RW,
    // output       o_LCD_ON,
    // output       o_LCD_BLON

    // LED
    // output  [8:0] o_ledg
    //output [17:0] o_ledr,

    // parameters and frequencies
    output [255:0] freqs,
    input  [15:0] threshold_gate,       // -inf ~ 0 (0 ~ 32767)
    input  [15:0] threshold_comp,       // -inf ~ 0 (0 ~ 32767)
    input  [ 4:0] ratio,                // 1:1 ~ 31:1
    input  [15:0] makeup,
    input  [ 2:0] Pan
);

  // design the FSM and states as you like
  localparam S_IDLE = 0;
  localparam S_I2C = 1;
  localparam S_BYPASS = 2;

  logic [1:0] state_w, state_r;
  logic i2c_oen;
  wire  i2c_sdat;
  wire  inSigReady;

  logic [15:0] i_adc_l_w_0[16], i_adc_r_w_0[16];
  logic [15:0] i_adc_l_w_1[16], i_adc_r_w_1[16];
  logic [15:0] i_adc_l_w_2[16], i_adc_r_w_2[16];

  assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

  logic i2c_start, i2c_finish, en;
  logic fft_finish_r,fft_finish_w;
  logic fft0_valid,fft1_valid;
  logic fft2_valid,fft3_valid;
  logic [15:0] fft16_0_out[0:15], fft16_1_out[0:15];
  logic [15:0] fft16_2_out[0:15], fft16_3_out[0:15];
  logic [15:0] average_0[0:15];
  logic [15:0] average_1[0:15];
  logic [255:0] freqs_r,freqs_w;

  assign freqs = freqs_r;
  assign fft_done = fft_finish_r;

  // === I2cInitializer ===
  // sequentially sent out settings to initialize WM8731 with I2C protocal
  I2cInitializer init0 (
      .i_rst_n(i_rst_n),
      .i_clk(i_clk_100k),
      .i_start(i2c_start),
      .o_finished(i2c_finish),
      .o_sclk(o_I2C_SCLK),
      .io_sdat(i2c_sdat),
      .o_oen(i2c_oen)  // you are outputing (you are not outputing only when you are "ack"ing.)
  );

  Dynamic_Gate dygt0 (
      .i_rst_n(i_rst_n),
      .i_clk(i_AUD_BCLK),  // BCLK
      // .i_enable(en),  // input signal is ready to read
      .threshold_gate(threshold_gate),  // -inf ~ 0 (0 ~ 32767)
      .threshold_comp(threshold_comp),  // -inf ~ 0 (0 ~ 32767)
      .ratio(ratio),  // 1:1 ~ 31:1
      .makeup(makeup),  // (0 ~ 32767)
      .i_seq_l(i_adc_l_w_1),
      .i_seq_r(i_adc_r_w_1),
      .o_seq_l(i_adc_l_w_2),
      .o_seq_r(i_adc_r_w_2)
  );

  PanLR Pan_Control(
      .i_seq_l(i_adc_l_w_0),
      .i_seq_r(i_adc_r_w_0),
      .Pan(Pan),
      .o_seq_l(i_adc_l_w_1),
      .o_seq_r(i_adc_r_w_1)
  );

  // === AudPlayer ===
  // receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
  AudPlayer player0 (
      .i_rst_n     (i_rst_n),
      .i_bclk      (i_AUD_BCLK),
      .i_daclrck   (i_AUD_DACLRCK),
      .i_en        (en),               // enable AudPlayer only when playing audio, work with AudDSP
      // .i_dac_l     (i_adc_l_w_1[15]),
      // .i_dac_r     (i_adc_r_w_1[15]),
      .i_dac_l     (i_adc_l_w_0[15]),  // temp
      .i_dac_r     (i_adc_r_w_0[15]),  // temp
      .o_aud_dacdat(o_AUD_DACDAT)
  );

  AudIn audin0 (
      .i_rst_n(i_rst_n),
      .i_clk(i_AUD_BCLK),
      .i_enable(en),
      .i_lrc(i_AUD_ADCLRCK),
      .i_data(i_AUD_ADCDAT),  // ADCDAT
      .o_seq_l(i_adc_l_w_0),
      .o_seq_r(i_adc_r_w_0),
      .o_ready(inSigReady)
  );

  FFT fft16_0 (
      .clk(i_clk),
      .rst(!i_rst_n),
      .i_start(!i_GETMUSIC),
      .i_n(i_adc_l_w_2),
      .o_n(fft16_0_out),
      .o_out_valid(fft0_valid)
  );

  FFT fft16_1 (
      .clk(i_clk),
      .rst(!i_rst_n),
      .i_start(!i_GETMUSIC),
      .i_n(i_adc_r_w_2),
      .o_n(fft16_1_out),
      .o_out_valid(fft1_valid)
  );

  FFT fft16_2 (
      .clk(i_clk),
      .rst(!i_rst_n),
      .i_start(!i_GETMUSIC),
      .i_n(i_adc_l_w_0),
      .o_n(fft16_2_out),
      .o_out_valid(fft2_valid)
  );

  FFT fft16_3 (
      .clk(i_clk),
      .rst(!i_rst_n),
      .i_start(!i_GETMUSIC),
      .i_n(i_adc_r_w_0),
      .o_n(fft16_3_out),
      .o_out_valid(fft3_valid)
  );

  always_comb begin
    state_w = state_r;
    fft_finish_w = fft0_valid && fft1_valid && fft2_valid && fft3_valid;
    i2c_start = 0;
    en = 1;

    for(int i=0;i<=15;i=i+1) begin
        if(fft_finish_w) begin
          average_0[i] = { (fft16_0_out[i][15:8] + fft16_1_out[i][15:8])>>1 , 
                           (fft16_0_out[i][7:0] + fft16_1_out[i][7:0])>>1 };
          average_1[i] = { (fft16_2_out[i][15:8] + fft16_3_out[i][15:8])>>1 , 
                           (fft16_2_out[i][7:0] + fft16_3_out[i][7:0])>>1 };
        end
        else begin
          average_0[i] = 0;
          average_1[i] = 0;
        end
    end
   
    freqs_w = { 
                average_1[7],average_1[6],average_1[5],average_1[4],average_1[3],average_1[2],average_1[1],average_1[0],
                average_0[7],average_0[6],average_0[5],average_0[4],average_0[3],average_0[2],average_0[1],average_0[0]
              };

    case (state_r)
      S_IDLE: begin
        if (i_key_0) begin
          state_w   = S_I2C;
          i2c_start = 1;
        end
      end
      S_I2C: begin
        if (i2c_finish) begin
          state_w = S_BYPASS;
        end 
        else begin
          i2c_start = 1;
          state_w   = S_I2C;
        end
      end
      S_BYPASS: begin
        if (i_key_1) begin
          state_w = S_IDLE;
        end
      end
    endcase

  end

  always_ff @(posedge i_AUD_BCLK or negedge i_rst_n) begin
    if (!i_rst_n) begin
      state_r <= S_IDLE;
      fft_finish_r <= 0;
      freqs_r <= 0;
    end 
    else begin
      state_r   <= state_w;
      fft_finish_r <= fft_finish_w;
      freqs_r <= freqs_w;
    end
  end

endmodule