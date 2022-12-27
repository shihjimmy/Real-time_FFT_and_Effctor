module POINT8 (
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
  output reg signed [15:0] a_o,
  output reg signed [15:0] b_o,
  output reg signed [15:0] c_o,
  output reg signed [15:0] d_o,
  output reg signed [15:0] e_o,
  output reg signed [15:0] f_o,
  output reg signed [15:0] g_o,
  output reg signed [15:0] h_o,
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
  reg signed [63:0] temp_real_1, temp_imaginary_1;
  reg signed [63:0] temp_real_2, temp_imaginary_2;
  reg signed [63:0] temp_real_3, temp_imaginary_3;
  reg signed [63:0] temp_real_4, temp_imaginary_4;

  reg signed [63:0] point4_1_i1, point4_1_i2, point4_1_i3, point4_1_i4;
  reg signed [63:0] point4_2_i1, point4_2_i2, point4_2_i3, point4_2_i4;

  reg signed [63:0] point4_1_d1, point4_1_d2, point4_1_d3, point4_1_d4;
  reg signed [63:0] next_point4_1_d1, next_point4_1_d2, next_point4_1_d3, next_point4_1_d4;
  reg signed [63:0] point4_2_d1, point4_2_d2, point4_2_d3, point4_2_d4;
  reg signed [63:0] next_point4_2_d1, next_point4_2_d2, next_point4_2_d3, next_point4_2_d4;

  wire signed [15:0] point4_1_o1, point4_1_o2, point4_1_o3, point4_1_o4;
  wire signed [15:0] point4_2_o1, point4_2_o2, point4_2_o3, point4_2_o4;
  reg signed [31:0] a_i_r, a_i_i, b_i_r, b_i_i, c_i_r, c_i_i, d_i_r, d_i_i;
  reg signed [31:0] e_i_r, e_i_i, f_i_r, f_i_i, g_i_r, g_i_i, h_i_r, h_i_i;

  reg state_r,state_w,valid_r,valid_w;
  wire point4_1_valid,point4_2_valid;
  wire point4_1_start,point4_2_start;

  POINT4 point4_1(.a_i(point4_1_d1), .b_i(point4_1_d2),.c_i(point4_1_d3), .d_i(point4_1_d4), .a_o(point4_1_o1), .b_o(point4_1_o2), .c_o(point4_1_o3), .d_o(point4_1_o4),
                  .clk(clk), .rst(rst),.i_start(point4_1_start),.o_out_valid(point4_1_valid));
  POINT4 point4_2(.a_i(point4_2_d1), .b_i(point4_2_d2),.c_i(point4_2_d3), .d_i(point4_2_d4), .a_o(point4_2_o1), .b_o(point4_2_o2), .c_o(point4_2_o3), .d_o(point4_2_o4),
                  .clk(clk), .rst(rst),.i_start(point4_2_start),.o_out_valid(point4_2_valid));

  assign o_out_valid = point4_1_valid & point4_2_valid;
  assign point4_1_start = valid_r;
  assign point4_2_start = valid_r;

  always @(*)begin
    state_w = state_r;
    valid_w = 0;

    case(state_r)
      IDLE: begin
          if(i_start) begin
              state_w = RUN;
          end
          else begin
              // wait for fft 4 bits finished
          end
      end

      RUN: begin
        a_i_r = a_i[63:32];    a_i_i = a_i[31:0];
        b_i_r = b_i[63:32];    b_i_i = b_i[31:0];
        c_i_r = c_i[63:32];    c_i_i = c_i[31:0];
        d_i_r = d_i[63:32];    d_i_i = d_i[31:0];
        e_i_r = e_i[63:32];    e_i_i = e_i[31:0];
        f_i_r = f_i[63:32];    f_i_i = f_i[31:0];
        g_i_r = g_i[63:32];    g_i_i = g_i[31:0];
        h_i_r = h_i[63:32];    h_i_i = h_i[31:0];

        temp_a_r = (a_i_r - e_i_r)*W0_R;
        temp_a_i = (e_i_i - a_i_i)*W0_I;
        temp_e_r = (a_i_r - e_i_r)*W0_I;
        temp_e_i = (a_i_i - e_i_i)*W0_R;
        temp_real_1 = temp_a_r + temp_a_i; //64 bit
        temp_imaginary_1 = temp_e_r + temp_e_i; //64 bit
        next_point4_1_d1 = {{a_i_r + e_i_r},{a_i_i + e_i_i}};
        next_point4_2_d1 = {{(temp_real_1[63]==1)? {temp_real_1[47:16]+1}:{temp_real_1[47:16]}},{(temp_imaginary_1[63]==1)? {temp_imaginary_1[47:16]+1}:temp_imaginary_1[47:16]}};

        temp_b_r = (b_i_r - f_i_r)*W2_R;
        temp_b_i = (f_i_i - b_i_i)*W2_I;
        temp_f_r = (b_i_r - f_i_r)*W2_I;
        temp_f_i = (b_i_i - f_i_i)*W2_R;
        temp_real_2 = temp_b_r + temp_b_i; //64 bit
        temp_imaginary_2 = temp_f_r + temp_f_i; //64 bit
        next_point4_1_d2 = {{b_i_r + f_i_r},{b_i_i + f_i_i}};
        next_point4_2_d2 = {{(temp_real_2[63]==1)? {temp_real_2[47:16]+1}:{temp_real_2[47:16]}},{(temp_imaginary_2[63]==1)? {temp_imaginary_2[47:16]+1}:temp_imaginary_2[47:16]}};

        temp_c_r = (c_i_r - g_i_r)*W4_R;
        temp_c_i = (g_i_i - c_i_i)*W4_I;
        temp_g_r = (c_i_r - g_i_r)*W4_I;
        temp_g_i = (c_i_i - g_i_i)*W4_R;
        temp_real_3 = temp_c_r + temp_c_i; //64 bit
        temp_imaginary_3 = temp_g_r + temp_g_i; //64 bit
        next_point4_1_d3 = {{c_i_r + g_i_r},{c_i_i + g_i_i}};
        next_point4_2_d3 = {{(temp_real_3[63]==1)? {temp_real_3[47:16]+1}:{temp_real_3[47:16]}},{(temp_imaginary_3[63]==1)? {temp_imaginary_3[47:16]+1}:temp_imaginary_3[47:16]}};

        temp_d_r = (d_i_r - h_i_r)*W6_R;
        temp_d_i = (h_i_i - d_i_i)*W6_I;
        temp_h_r = (d_i_r - h_i_r)*W6_I;
        temp_h_i = (d_i_i - h_i_i)*W6_R;
        temp_real_4 = temp_d_r + temp_d_i; //64 bit
        temp_imaginary_4 = temp_h_r + temp_h_i; //64 bit
        next_point4_1_d4 = {{d_i_r + h_i_r},{d_i_i + h_i_i}};
        next_point4_2_d4 = {{(temp_real_4[63]==1)? {temp_real_4[47:16]+1}:{temp_real_4[47:16]}},{(temp_imaginary_4[63]==1)? {temp_imaginary_4[47:16]+1}:temp_imaginary_4[47:16]}};
      
        state_w = IDLE;
        valid_w = 1;
      end
    
    endcase

    a_o = point4_1_o1;
    b_o = point4_1_o2;
    c_o = point4_1_o3;
    d_o = point4_1_o4;
    e_o = point4_2_o1;
    f_o = point4_2_o2;
    g_o = point4_2_o3;
    h_o = point4_2_o4;

  end

  always @(posedge clk or posedge rst)begin
    if(rst)begin
      state_r <= IDLE;
      valid_r <= 0;
      point4_1_d1 <= 0;
      point4_1_d2 <= 0;
      point4_1_d3 <= 0;
      point4_1_d4 <= 0;
      point4_2_d1 <= 0;
      point4_2_d2 <= 0;
      point4_2_d3 <= 0;
      point4_2_d4 <= 0;
    end 
    else begin
      state_r <= state_w;
      valid_r <= valid_w;
      point4_1_d1 <= next_point4_1_d1;
      point4_1_d2 <= next_point4_1_d2;
      point4_1_d3 <= next_point4_1_d3;
      point4_1_d4 <= next_point4_1_d4;
      point4_2_d1 <= next_point4_2_d1;
      point4_2_d2 <= next_point4_2_d2;
      point4_2_d3 <= next_point4_2_d3;
      point4_2_d4 <= next_point4_2_d4;
    end
  end

endmodule