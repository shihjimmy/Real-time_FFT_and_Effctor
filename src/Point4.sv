module POINT4 (
  input clk,
  input rst,
  input i_start,
  input signed [63:0] a_i,
  input signed [63:0] b_i,
  input signed [63:0] c_i,
  input signed [63:0] d_i,
  output reg signed [15:0] a_o,
  output reg signed [15:0] b_o,
  output reg signed [15:0] c_o,
  output reg signed [15:0] d_o,
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
  reg signed [31:0] a_i_r, a_i_i, b_i_r, b_i_i, c_i_r, c_i_i, d_i_r, d_i_i;
  reg signed [31:0] e_i_r, e_i_i, f_i_r, f_i_i, g_i_r, g_i_i, h_i_r, h_i_i;
  reg signed [63:0] temp_real_1, temp_imaginary_1;
  reg signed [63:0] temp_real_2, temp_imaginary_2;

  reg signed [63:0] point2_1_i1, point2_1_i2;
  reg signed [63:0] point2_2_i1, point2_2_i2;

  reg signed [63:0] point2_1_d1, point2_1_d2;
  reg signed [63:0] next_point2_1_d1, next_point2_1_d2;
  reg signed [63:0] point2_2_d1, point2_2_d2;
  reg signed [63:0] next_point2_2_d1, next_point2_2_d2;

  wire signed [15:0] point2_1_o1, point2_1_o2;
  wire signed [15:0] point2_2_o1, point2_2_o2;

  reg state_r,state_w,valid_r,valid_w;
  wire point2_1_valid,point2_2_valid;
  wire point2_1_start,point2_2_start;

  POINT2 point2_1(.a_i(point2_1_d1), .b_i(point2_1_d2), .a_o(point2_1_o1), .b_o(point2_1_o2), .clk(clk), .rst(rst),.i_start(point2_1_start),.o_out_valid(point2_1_valid));
  POINT2 point2_2(.a_i(point2_2_d1), .b_i(point2_2_d2), .a_o(point2_2_o1), .b_o(point2_2_o2), .clk(clk), .rst(rst),.i_start(point2_2_start),.o_out_valid(point2_2_valid));

  assign o_out_valid = point2_1_valid & point2_2_valid;
  assign point2_1_start = valid_r;
  assign point2_2_start = valid_r;

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
              // wait for fft 2 bits finished
          end
      end

      RUN: begin
          a_i_r = a_i[63:32];    a_i_i = a_i[31:0];
          b_i_r = b_i[63:32];    b_i_i = b_i[31:0];
          c_i_r = c_i[63:32];    c_i_i = c_i[31:0];
          d_i_r = d_i[63:32];    d_i_i = d_i[31:0];

          temp_a_r = (a_i_r - c_i_r)*W0_R;
          temp_a_i = (c_i_i - a_i_i)*W0_I;
          temp_c_r = (a_i_r - c_i_r)*W0_I;
          temp_c_i = (a_i_i - c_i_i)*W0_R;
          temp_real_1 = temp_a_r + temp_a_i; //64 bit
          temp_imaginary_1 = temp_c_r + temp_c_i; //64 bit
          next_point2_1_d1 = {{a_i_r + c_i_r},{a_i_i + c_i_i}};
          next_point2_2_d1 = {{(temp_real_1[63]==1)? {temp_real_1[47:16]+1}:{temp_real_1[47:16]}},{(temp_imaginary_1[63]==1)? {temp_imaginary_1[47:16]+1}:temp_imaginary_1[47:16]}};

          temp_b_r = (b_i_r - d_i_r)*W4_R;
          temp_b_i = (d_i_i - b_i_i)*W4_I;
          temp_d_r = (b_i_r - d_i_r)*W4_I;
          temp_d_i = (b_i_i - d_i_i)*W4_R;
          temp_real_2 = temp_b_r + temp_b_i; //64 bit
          temp_imaginary_2 = temp_d_r + temp_d_i; //64 bit
          next_point2_1_d2 = {{b_i_r + d_i_r},{b_i_i + d_i_i}};
          next_point2_2_d2 = {{(temp_real_2[63]==1)? {temp_real_2[47:16]+1}:{temp_real_2[47:16]}},{(temp_imaginary_2[63]==1)? {temp_imaginary_2[47:16]+1}:temp_imaginary_2[47:16]}};

          a_o = point2_1_o1;
          b_o = point2_1_o2;
          c_o = point2_2_o1;
          d_o = point2_2_o2;

          state_w = IDLE;
          valid_w = 1;
      end
    endcase
  end

  always @(posedge clk or posedge rst)begin
    if(rst)begin
      state_r <= IDLE;
      valid_r <= 0;
      point2_1_d1 <= 0;
      point2_1_d2 <= 0;
      point2_2_d1 <= 0;
      point2_2_d2 <= 0;
    end 
    else begin
      state_r <= state_w;
      valid_r <= valid_w;
      point2_1_d1 <= next_point2_1_d1;
      point2_1_d2 <= next_point2_1_d2;
      point2_2_d1 <= next_point2_2_d1;
      point2_2_d2 <= next_point2_2_d2; 
    end
  end

endmodule