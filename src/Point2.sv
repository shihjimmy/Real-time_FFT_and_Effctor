module POINT2 (
  input clk,
  input rst,
  input i_start,
  input signed [63:0] a_i,
  input signed [63:0] b_i,
  output reg signed [15:0] a_o,             //16bit real, 16bit imaginary
  output reg signed [15:0] b_o,
  output reg o_out_valid
  );

  // W0_R: 16 bit + 16 bit floating point, total 32bit 
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
  reg signed [31:0] a_i_r, a_i_i, b_i_r, b_i_i;
  reg signed [63:0] temp_real, temp_imaginary;
  reg signed [63:0] temp_a_o, temp_b_o;
  reg signed [15:0] a_o_d1, b_o_d1;
  reg signed [15:0] next_a_o_d1, next_b_o_d1;
  reg state_r,state_w;
  reg valid_r,valid_w;

  assign o_out_valid = valid_r;
  assign a_o = a_o_d1;
  assign b_o = b_o_d1;

  always @(*)begin
    valid_w = valid_r;
    state_w = state_r;

    case(state_r)
      IDLE: begin
        if(i_start) begin  
            state_w = RUN;
            valid_w = 0;
        end
      end

      RUN: begin
        // a_i[31:0] is imaginary part
        // a_i[63:32] is real part
        a_i_r = a_i[63:32];    a_i_i = a_i[31:0];
        b_i_r = b_i[63:32];    b_i_i = b_i[31:0];

        temp_a_r = (a_i_r - b_i_r)*W0_R;
        temp_a_i = (b_i_i - a_i_i)*W0_I;
        temp_b_r = (a_i_r - b_i_r)*W0_I;
        temp_b_i = (a_i_i - b_i_i)*W0_R;
        temp_real = temp_a_r + temp_a_i; //64 bit
        temp_imaginary = temp_b_r + temp_b_i; //64 bit

        temp_a_o = {{a_i_r + b_i_r},{a_i_i + b_i_i}};
        temp_b_o = {{(temp_real[63]==1)? {temp_real[47:16]+1}:{temp_real[47:16]}},{(temp_imaginary[63]==1)? {temp_imaginary[47:16]+1}:temp_imaginary[47:16]}};
        
        next_a_o_d1 = {temp_a_o[55:48], temp_a_o[23:16]};
        next_b_o_d1 = {temp_b_o[55:48], temp_b_o[23:16]};

        valid_w = 1;
        state_w = IDLE;
      end

    endcase
  end

  always @(posedge clk or posedge rst)begin
    if(rst)begin
      state_r <= IDLE;
      valid_r <= 0;
      a_o_d1 <= 0;
      b_o_d1 <= 0;
    end 
    else begin
      state_r <= state_w;
      valid_r <= valid_w;
      a_o_d1 <= next_a_o_d1;
      b_o_d1 <= next_b_o_d1;
    end
  end

endmodule