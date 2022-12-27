module POINT16 (
  input clk,
  input rst,
  input i_start,
  input signed [63:0] a_i,
  input signed [63:0] b_i,
  input signed [63:0] c_i,
  input signed [63:0] d_i,
  input signed [63:0] e_i,
  input signed [63:0] f_i,
  input signed [63:0] g_i,
  input signed [63:0] h_i,
  input signed [63:0] i_i,
  input signed [63:0] j_i,
  input signed [63:0] k_i,
  input signed [63:0] l_i,
  input signed [63:0] m_i,
  input signed [63:0] n_i,
  input signed [63:0] o_i,
  input signed [63:0] p_i,
  output reg signed [15:0] a_o,     
  output reg signed [15:0] b_o, 
  output reg signed [15:0] c_o,
  output reg signed [15:0] d_o,
  output reg signed [15:0] e_o,
  output reg signed [15:0] f_o,
  output reg signed [15:0] g_o,
  output reg signed [15:0] h_o,
  output reg signed [15:0] i_o,
  output reg signed [15:0] j_o,
  output reg signed [15:0] k_o,
  output reg signed [15:0] l_o,
  output reg signed [15:0] m_o,
  output reg signed [15:0] n_o,
  output reg signed [15:0] o_o,
  output reg signed [15:0] p_o,
  output o_out_valid
  );
  parameter signed [31:0] W0_R =  32'h00010000  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 0: 001
  parameter signed [31:0] W1_R =  32'h0000EC83  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 1: 9.238739e-001
  parameter signed [31:0] W2_R =  32'h0000B504  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 2: 7.070923e-001
  parameter signed [31:0] W3_R =  32'h000061F7  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 3: 3.826752e-001
  parameter signed [31:0] W4_R =  32'h00000000  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 4: 000
  parameter signed [31:0] W5_R =  32'hFFFF9E09  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 5: -3.826752e-001
  parameter signed [31:0] W6_R =  32'hFFFF4AFC  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 6: -7.070923e-001
  parameter signed [31:0] W7_R =  32'hFFFF137D  ;    //The real part of the reference table about COS(x)+i*SIN(x) value , 7: -9.238739e-001
  parameter signed [31:0] W0_I =  32'h00000000 ;     //The imag part of the reference table about COS(x)+i*SIN(x) value , 0: 000
  parameter signed [31:0] W1_I =  32'hFFFF9E09 ;    //The imag part of the reference table about COS(x)+i*SIN(x) value , 1: -3.826752e-001
  parameter signed [31:0] W2_I =  32'hFFFF4AFC ;   //The imag part of the reference table about COS(x)+i*SIN(x) value , 2: -7.070923e-001
  parameter signed [31:0] W3_I =  32'hFFFF137D ;    //The imag part of the reference table about COS(x)+i*SIN(x) value , 3: -9.238739e-001
  parameter signed [31:0] W4_I =  32'hFFFF0000 ;    //The imag part of the reference table about COS(x)+i*SIN(x) value , 4: -01
  parameter signed [31:0] W5_I =  32'hFFFF137D ;   //The imag part of the reference table about COS(x)+i*SIN(x) value , 5: -9.238739e-001
  parameter signed [31:0] W6_I =  32'hFFFF4AFC ;     //The imag part of the reference table about COS(x)+i*SIN(x) value , 6: -7.070923e-001
  parameter signed [31:0] W7_I =  32'hFFFF9E09 ;    //The imag part of the reference table about COS(x)+i*SIN(x) value , 7: -3.826752e-001
  
  localparam IDLE = 0;
  localparam RUN  = 1;

  reg signed [63:0] temp_a_r, temp_a_i, temp_b_r, temp_b_i;
  reg signed [63:0] temp_c_r, temp_c_i, temp_d_r, temp_d_i;
  reg signed [63:0] temp_e_r, temp_e_i, temp_f_r, temp_f_i;
  reg signed [63:0] temp_g_r, temp_g_i, temp_h_r, temp_h_i;
  reg signed [63:0] temp_i_r, temp_i_i, temp_j_r, temp_j_i;
  reg signed [63:0] temp_k_r, temp_k_i, temp_l_r, temp_l_i;
  reg signed [63:0] temp_m_r, temp_m_i, temp_n_r, temp_n_i;
  reg signed [63:0] temp_o_r, temp_o_i, temp_p_r, temp_p_i;
  reg signed [31:0] temp_ac, temp_bd;
  reg signed [63:0] temp_real_1, temp_imaginary_1;
  reg signed [63:0] temp_real_2, temp_imaginary_2;
  reg signed [63:0] temp_real_3, temp_imaginary_3;
  reg signed [63:0] temp_real_4, temp_imaginary_4;
  reg signed [63:0] temp_real_5, temp_imaginary_5;
  reg signed [63:0] temp_real_6, temp_imaginary_6;
  reg signed [63:0] temp_real_7, temp_imaginary_7;
  reg signed [63:0] temp_real_8, temp_imaginary_8;
  reg signed [31:0] b_i_r, b_i_i, c_i_r, c_i_i, d_i_r, d_i_i, e_i_r, e_i_i, f_i_r, f_i_i, g_i_r, g_i_i, h_i_r, h_i_i;
  reg signed [31:0] i_i_r, i_i_i, j_i_r, j_i_i, k_i_r, k_i_i, l_i_r, l_i_i, m_i_r, m_i_i, n_i_r, n_i_i, o_i_r, o_i_i, p_i_r, p_i_i;

  reg signed [63:0] point8_1_i1, point8_1_i2, point8_1_i3, point8_1_i4, point8_1_i5, point8_1_i6, point8_1_i7, point8_1_i8;
  reg signed [63:0] point8_2_i1, point8_2_i2, point8_2_i3, point8_2_i4, point8_2_i5, point8_2_i6, point8_2_i7, point8_2_i8;
  wire signed [15:0] point8_1_o1, point8_1_o2, point8_1_o3, point8_1_o4, point8_1_o5, point8_1_o6, point8_1_o7, point8_1_o8;
  wire signed [15:0] point8_2_o1, point8_2_o2, point8_2_o3, point8_2_o4, point8_2_o5, point8_2_o6, point8_2_o7, point8_2_o8;

  reg signed [63:0] point8_1_d1, point8_1_d2, point8_1_d3, point8_1_d4, point8_1_d5, point8_1_d6, point8_1_d7, point8_1_d8;
  reg signed [63:0] point8_2_d1, point8_2_d2, point8_2_d3, point8_2_d4, point8_2_d5, point8_2_d6, point8_2_d7, point8_2_d8;
  reg signed [63:0] next_point8_1_d1, next_point8_1_d2, next_point8_1_d3, next_point8_1_d4, next_point8_1_d5, next_point8_1_d6, next_point8_1_d7, next_point8_1_d8;
  reg signed [63:0] next_point8_2_d1, next_point8_2_d2, next_point8_2_d3, next_point8_2_d4, next_point8_2_d5, next_point8_2_d6, next_point8_2_d7, next_point8_2_d8;
  
  reg state_r,state_w,valid_r,valid_w;
  wire point8_1_valid,point8_2_valid;
  wire point8_1_start,point8_2_start;

  POINT8 point8_1(.a_i(point8_1_d1), .b_i(point8_1_d2), .c_i(point8_1_d3), .d_i(point8_1_d4), .e_i(point8_1_d5), .f_i(point8_1_d6), .g_i(point8_1_d7), .h_i(point8_1_d8),
                  .a_o(point8_1_o1), .b_o(point8_1_o2), .c_o(point8_1_o3), .d_o(point8_1_o4), .e_o(point8_1_o5), .f_o(point8_1_o6), .g_o(point8_1_o7), .h_o(point8_1_o8),
                  .clk(clk), .rst(rst),.i_start(point8_1_start),.o_out_valid(point8_1_valid));
  POINT8 point8_2(.a_i(point8_2_d1), .b_i(point8_2_d2), .c_i(point8_2_d3), .d_i(point8_2_d4), .e_i(point8_2_d5), .f_i(point8_2_d6), .g_i(point8_2_d7), .h_i(point8_2_d8), 
                  .a_o(point8_2_o1), .b_o(point8_2_o2), .c_o(point8_2_o3), .d_o(point8_2_o4), .e_o(point8_2_o5), .f_o(point8_2_o6), .g_o(point8_2_o7), .h_o(point8_2_o8),
                  .clk(clk), .rst(rst),.i_start(point8_2_start) ,.o_out_valid(point8_2_valid));

  assign o_out_valid = point8_1_valid & point8_2_valid;
  assign point8_1_start = valid_r;
  assign point8_2_start = valid_r;

  always @(*)begin
    state_w = state_r;
    valid_w = 0;

    case(state_r)

      IDLE: begin
          if(i_start) begin
              state_w = RUN;
              valid_w = 0;
          end
          else begin
              // wait for 8 bits fft finished
          end
      end

      RUN: begin
          temp_a_r = ({{32{a_i[63]}},a_i[63:32]} - {{32{i_i[63]}},i_i[63:32]})*{{32{W0_R[31]}},W0_R};  //32bit * 32bit = 64 bit
          temp_a_i = ({{32{i_i[31]}},i_i[31:0]} - {{32{a_i[31]}},a_i[31:0]})*{{32{W0_I[31]}}, W0_I};
          temp_i_r = (a_i[63:32] - i_i[63:32])*W0_I;
          temp_i_i = (a_i[31:0] - i_i[31:0])*W0_R;
          temp_ac = a_i[63:32] + i_i[63:32]; //32 bit real
          temp_bd = a_i[31:0] + i_i[31:0]; //32 bit imaginary
          temp_real_1 = temp_a_r + temp_a_i; //64 bit
          temp_imaginary_1 = temp_i_r + temp_i_i; //64 bit
          next_point8_1_d1 = {{temp_ac}, {temp_bd}};
          next_point8_2_d1 = {{(temp_real_1[63]==1)? {temp_real_1[47:16]+1}:{temp_real_1[47:16]}},{(temp_imaginary_1[63]==1)? {temp_imaginary_1[47:16]+1}:temp_imaginary_1[47:16]}};

          b_i_r = b_i[63:32];    b_i_i = b_i[31:0];    j_i_r = j_i[63:32];    j_i_i = j_i[31:0];
          temp_b_r = ($signed(b_i_r) - $signed(j_i_r))*$signed(W1_R);
          temp_b_i = (j_i_i - b_i_i)*W1_I;
          temp_j_r = ($signed(b_i_r) - $signed(j_i_r))*$signed(W1_I);
          temp_j_i = (b_i_i - j_i_i)*W1_R;
          temp_real_2 = temp_b_r + temp_b_i; //64 bit
          temp_imaginary_2 = temp_j_r + temp_j_i; //64 bit
          next_point8_1_d2 = {{b_i[63:32] + j_i[63:32]},{b_i[31:0] + j_i[31:0]}};
          next_point8_2_d2 = {{(temp_real_2[63]==1)? {temp_real_2[47:16]+1}:{temp_real_2[47:16]}},{(temp_imaginary_2[63]==1)? {temp_imaginary_2[47:16]+1}:temp_imaginary_2[47:16]}};

          c_i_r = c_i[63:32];  c_i_i = c_i[31:0];  k_i_r = k_i[63:32]; k_i_i = k_i[31:0];
          temp_c_r = (c_i_r - k_i_r)*W2_R;
          temp_c_i = (k_i_i - c_i_i)*W2_I;
          temp_k_r = (c_i_r - k_i_r)*W2_I;
          temp_k_i = (c_i_i - k_i_i)*W2_R;
          temp_real_3 = temp_c_r + temp_c_i; //64 bit
          temp_imaginary_3 = temp_k_r + temp_k_i; //64 bit
          next_point8_1_d3 = {{c_i_r + k_i_r},{c_i_i + k_i_i}};
          next_point8_2_d3 = {{(temp_real_3[63]==1)? {temp_real_3[47:16]+1}:{temp_real_3[47:16]}},{(temp_imaginary_3[47]==1)? {temp_imaginary_3[47:16]+1}:temp_imaginary_3[47:16]}};

          d_i_r = d_i[63:32];  d_i_i = d_i[31:0]; l_i_r = l_i[63:32]; l_i_i = l_i[31:0];
          temp_d_r = (d_i_r - l_i_r)*W3_R;
          temp_d_i = (l_i_i - d_i_i)*W3_I;
          temp_l_r = (d_i_r - l_i_r)*W3_I;
          temp_l_i = (d_i_i - l_i_i)*W3_R;
          temp_real_4 = temp_d_r + temp_d_i; //64 bit
          temp_imaginary_4 = temp_l_r + temp_l_i; //64 bit
          next_point8_1_d4 = {{d_i_r + l_i_r},{d_i_i + l_i_i}};
          next_point8_2_d4 = {{(temp_real_4[63]==1)? {temp_real_4[47:16]+1}:{temp_real_4[47:16]}},{(temp_imaginary_4[63]==1)? {temp_imaginary_4[47:16]+1}:temp_imaginary_4[47:16]}};

          e_i_r = e_i[63:32];  e_i_i = e_i[31:0]; m_i_r = m_i[63:32]; m_i_i = m_i[31:0];
          temp_e_r = (e_i_r - m_i_r)*W4_R;
          temp_e_i = (m_i_i - e_i_i)*W4_I;
          temp_m_r = (e_i_r - m_i_r)*W4_I;
          temp_m_i = (e_i_i - m_i_i)*W4_R;
          temp_real_5 = temp_e_r + temp_e_i; //64 bit
          temp_imaginary_5 = temp_m_r + temp_m_i; //64 bit
          next_point8_1_d5 = {{e_i_r + m_i_r},{e_i_i + m_i_i}};
          next_point8_2_d5 = {{(temp_real_5[63]==1)? {temp_real_5[47:16]+1}:{temp_real_5[47:16]}},{(temp_imaginary_5[63]==1)? {temp_imaginary_5[47:16]+1}:temp_imaginary_5[47:16]}};

          f_i_r = f_i[63:32]; f_i_i = f_i[31:0]; n_i_r = n_i[63:32];  n_i_i = n_i[31:0];
          temp_f_r = (f_i_r - n_i_r)*W5_R;
          temp_f_i = (n_i_i - f_i_i)*W5_I;
          temp_n_r = (f_i_r - n_i_r)*W5_I;
          temp_n_i = (f_i_i - n_i_i)*W5_R;
          temp_real_6 = temp_f_r + temp_f_i; //64 bit
          temp_imaginary_6 = temp_n_r + temp_n_i; //64 bit
          next_point8_1_d6 = {{f_i_r + n_i_r},{f_i_i + n_i_i}};
          next_point8_2_d6 = {{(temp_real_6[63]==1)? {temp_real_6[47:16]+1}:{temp_real_6[47:16]}},{(temp_imaginary_6[63]==1)? {temp_imaginary_6[47:16]+1}:temp_imaginary_6[47:16]}};

          g_i_r = g_i[63:32]; g_i_i = g_i[31:0]; o_i_r = o_i[63:32]; o_i_i = o_i[31:0];
          temp_g_r = (g_i_r - o_i_r)*W6_R;
          temp_g_i = (o_i_i - g_i_i)*W6_I;
          temp_o_r = (g_i_r - o_i_r)*W6_I;
          temp_o_i = (g_i_i - o_i_i)*W6_R;
          temp_real_7 = temp_g_r + temp_g_i; //64 bit
          temp_imaginary_7 = temp_o_r + temp_o_i; //64 bit
          next_point8_1_d7 = {{g_i_r + o_i_r},{g_i_i + o_i_i}};
          next_point8_2_d7 = {{(temp_real_7[63]==1)? {temp_real_7[47:16]+1}:{temp_real_7[47:16]}},{(temp_imaginary_7[63]==1)? {temp_imaginary_7[47:16]+1}:temp_imaginary_7[47:16]}};

          h_i_r = h_i[63:32]; h_i_i = h_i[31:0]; p_i_r = p_i[63:32]; p_i_i = p_i[31:0];
          temp_h_r = (h_i_r - p_i_r)*W7_R;
          temp_h_i = (p_i_i - h_i_i)*W7_I;
          temp_p_r = (h_i_r - p_i_r)*W7_I;
          temp_p_i = (h_i_i - p_i_i)*W7_R;
          temp_real_8 = temp_h_r + temp_h_i; //64 bit
          temp_imaginary_8 = temp_p_r + temp_p_i; //64 bit
          next_point8_1_d8 = {{h_i_r + p_i_r},{h_i_i + p_i_i}};
          next_point8_2_d8 = {{(temp_real_8[63]==1)? {temp_real_8[47:16]+1}:{temp_real_8[47:16]}},{(temp_imaginary_8[63]==1)? {temp_imaginary_8[47:16]+1}:temp_imaginary_8[47:16]}};

          state_w = IDLE;
          valid_w = 1;
      end
    endcase

    a_o = point8_1_o1;
    b_o = point8_1_o2;
    c_o = point8_1_o3;
    d_o = point8_1_o4;
    e_o = point8_1_o5;
    f_o = point8_1_o6;
    g_o = point8_1_o7;
    h_o = point8_1_o8;
    i_o = point8_2_o1;
    j_o = point8_2_o2;
    k_o = point8_2_o3;
    l_o = point8_2_o4;
    m_o = point8_2_o5;
    n_o = point8_2_o6;
    o_o = point8_2_o7;
    p_o = point8_2_o8;

  end

  always @(posedge clk or posedge rst)begin
    if(rst)begin
      state_r <= IDLE;
      valid_r <= 0;
      point8_1_d1 <= 0;
      point8_1_d2 <= 0;
      point8_1_d3 <= 0;
      point8_1_d4 <= 0;
      point8_1_d5 <= 0;
      point8_1_d6 <= 0;
      point8_1_d7 <= 0;
      point8_1_d8 <= 0;
      point8_2_d1 <= 0;
      point8_2_d2 <= 0;
      point8_2_d3 <= 0;
      point8_2_d4 <= 0;
      point8_2_d5 <= 0;
      point8_2_d6 <= 0;
      point8_2_d7 <= 0;
      point8_2_d8 <= 0;
    end 
    else begin
      state_r <= state_w;
      valid_r <= valid_w;
      point8_1_d1 <= next_point8_1_d1;
      point8_1_d2 <= next_point8_1_d2;
      point8_1_d3 <= next_point8_1_d3;
      point8_1_d4 <= next_point8_1_d4;
      point8_1_d5 <= next_point8_1_d5;
      point8_1_d6 <= next_point8_1_d6;
      point8_1_d7 <= next_point8_1_d7;
      point8_1_d8 <= next_point8_1_d8;
      point8_2_d1 <= next_point8_2_d1;
      point8_2_d2 <= next_point8_2_d2;
      point8_2_d3 <= next_point8_2_d3;
      point8_2_d4 <= next_point8_2_d4;
      point8_2_d5 <= next_point8_2_d5;
      point8_2_d6 <= next_point8_2_d6;
      point8_2_d7 <= next_point8_2_d7;
      point8_2_d8 <= next_point8_2_d8;
    end
  end

endmodule