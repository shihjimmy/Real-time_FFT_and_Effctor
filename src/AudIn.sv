module AudIn (
    input i_rst_n,
    input i_clk,  // BCLK
    input i_enable,  // 1 for enabled
    input i_lrc,  // ADCLRCK
    input i_data,  // ADCDAT
    output [15:0] o_seq_l[0:15],  // output 16 16 bit sequence (left channel)
    output [15:0] o_seq_r[0:15],  // output 16 16 bit sequence (right channel)
    output o_ready
);

  localparam S_IDLE = 0;  // wait for start
  localparam S_WORK_L = 1;
  localparam S_WORK_R = 2;

  logic [1:0] state_r, state_w;
  logic [0:15] temp_seq_r, temp_seq_w;
  logic [6:0] bit_counter_r, bit_counter_w;  // 16-bit data *2
  logic last_lrc_r;  // lrc at last clk
  logic ready_r, ready_w;

  logic [15:0] o_seq_l_r[0:16], o_seq_l_w[0:16];
  logic [15:0] o_seq_r_r[0:16], o_seq_r_w[0:16];

  assign o_seq_l[0]  = o_seq_l_r[0];
  assign o_seq_l[1]  = o_seq_l_r[1];
  assign o_seq_l[2]  = o_seq_l_r[2];
  assign o_seq_l[3]  = o_seq_l_r[3];
  assign o_seq_l[4]  = o_seq_l_r[4];
  assign o_seq_l[5]  = o_seq_l_r[5];
  assign o_seq_l[6]  = o_seq_l_r[6];
  assign o_seq_l[7]  = o_seq_l_r[7];
  assign o_seq_l[8]  = o_seq_l_r[8];
  assign o_seq_l[9]  = o_seq_l_r[9];
  assign o_seq_l[10] = o_seq_l_r[10];
  assign o_seq_l[11] = o_seq_l_r[11];
  assign o_seq_l[12] = o_seq_l_r[12];
  assign o_seq_l[13] = o_seq_l_r[13];
  assign o_seq_l[14] = o_seq_l_r[14];
  assign o_seq_l[15] = o_seq_l_r[15];

  assign o_seq_r[0]  = o_seq_r_r[0];
  assign o_seq_r[1]  = o_seq_r_r[1];
  assign o_seq_r[2]  = o_seq_r_r[2];
  assign o_seq_r[3]  = o_seq_r_r[3];
  assign o_seq_r[4]  = o_seq_r_r[4];
  assign o_seq_r[5]  = o_seq_r_r[5];
  assign o_seq_r[6]  = o_seq_r_r[6];
  assign o_seq_r[7]  = o_seq_r_r[7];
  assign o_seq_r[8]  = o_seq_r_r[8];
  assign o_seq_r[9]  = o_seq_r_r[9];
  assign o_seq_r[10] = o_seq_r_r[10];
  assign o_seq_r[11] = o_seq_r_r[11];
  assign o_seq_r[12] = o_seq_r_r[12];
  assign o_seq_r[13] = o_seq_r_r[13];
  assign o_seq_r[14] = o_seq_r_r[14];
  assign o_seq_r[15] = o_seq_r_r[15];

  // === Combinational Circuits ===
  always_comb begin
    state_w = state_r;
    bit_counter_w = bit_counter_r;
    temp_seq_w = temp_seq_r;
    for (int i = 0; i < 16; i++) begin
      o_seq_l_w[i] = o_seq_l_r[i];
      o_seq_r_w[i] = o_seq_r_r[i];
    end
    ready_w = ready_r;

    case (state_r)
      S_IDLE: begin
        ready_w = 1;
        bit_counter_w = 5'd0;  // read from the middle
        for (int i = 0; i < 16; i++) begin
          o_seq_l_w[i] = 0;
          o_seq_r_w[i] = 0;
        end

        if (!i_enable) begin
          state_w = S_IDLE;
        end 
        else begin
          ready_w = 0;
          if (last_lrc_r == 1'b1 && i_lrc == 1'b0) begin  // lrc negedge
            state_w = S_WORK_L;
          end 
          else begin
            state_w = S_IDLE;
          end
        end
      end

      S_WORK_L: begin
        if (bit_counter_r < 16) begin
          state_w = S_WORK_L;
          temp_seq_w[bit_counter_r] = i_data;
          bit_counter_w = bit_counter_r + 1;
        end 
        else if (last_lrc_r == 1'b0 && i_lrc == 1'b1) begin  // lrc posedge
          state_w = S_WORK_R;
          for (int i = 1; i < 16; i++) begin
            o_seq_l_w[i-1] = o_seq_l_r[i];
          end
          o_seq_l_w[15] = temp_seq_r;
          bit_counter_w = 0;
        end
        if (!i_enable) begin
          state_w = S_IDLE;
        end
      end

      S_WORK_R: begin
        if (bit_counter_r < 16) begin  // lrc posedge
          // right channel
          state_w = S_WORK_R;
          temp_seq_w[bit_counter_r] = i_data;
          bit_counter_w = bit_counter_r + 1;
        end 
        else if (last_lrc_r == 1'b1 && i_lrc == 1'b0) begin  // lrc negedge
          // left channel
          state_w = S_WORK_L;
          for (int i = 1; i < 16; i++) begin
            o_seq_r_w[i-1] = o_seq_r_r[i];
          end
          o_seq_r_w[15] = temp_seq_r;
          bit_counter_w = 0;
        end
        if (!i_enable) begin
          state_w = S_IDLE;
        end
      end
    endcase
  end

  // === Sequential Circuits ===
  always_ff @(posedge i_clk or negedge i_rst_n) begin  // BCLK
    if (!i_rst_n) begin
      state_r <= S_IDLE;
      bit_counter_r <= 0;
      last_lrc_r <= 0;
      temp_seq_r <= 0;
      for (int i = 0; i < 16; i++) begin
        o_seq_l_r[i] <= 0;
        o_seq_r_r[i] <= 0;
      end
      ready_r <= 0;
    end 
    else begin
      state_r <= state_w;
      bit_counter_r <= bit_counter_w;
      last_lrc_r <= i_lrc;
      temp_seq_r <= temp_seq_w;
      for (int i = 0; i < 16; i++) begin
        o_seq_l_r[i] <= o_seq_l_w[i];
        o_seq_r_r[i] <= o_seq_r_w[i];
      end
      ready_r <= ready_w;
    end
  end

endmodule