module FFT(
  input clk,
  input rst,
  input i_start,
  input  reg signed [15:0] i_n[0:15],
  output reg signed [15:0] o_n[0:15],
  output reg o_out_valid
  );

  localparam IDLE = 0;
  localparam RUN = 1;

  logic state_r,state_w;
  logic valid,start_r,start_w,finish_r,finish_w;
  logic signed [63:0] a_i,b_i,c_i,d_i,e_i,f_i,g_i,h_i,i_i,j_i,k_i,l_i,m_i,n_i,o_i,p_i;
  logic signed [15:0] a_o,b_o,c_o,d_o,e_o,f_o,g_o,h_o,i_o,j_o,k_o,l_o,m_o,n_o,o_o,p_o;

  POINT16 point16_1(.clk(clk),.rst(rst),.i_start(start_r),.o_out_valid(valid),.a_i(a_i),.b_i(b_i),.c_i(c_i),.d_i(d_i),
                    .e_i(e_i),.f_i(f_i),.g_i(g_i),.h_i(h_i),.i_i(i_i),.j_i(j_i),.k_i(k_i),.l_i(l_i),.m_i(m_i),
                    .n_i(n_i),.o_i(o_i),.p_i(p_i),.a_o(a_o),.b_o(b_o),.c_o(c_o),.d_o(d_o),.e_o(e_o),.f_o(f_o),.g_o(g_o),
                    .h_o(h_o),.i_o(i_o),.j_o(j_o),.k_o(k_o),.l_o(l_o),.m_o(m_o),.n_o(n_o),.o_o(o_o),.p_o(p_o));

  assign  a_i = {i_n[0],48'b0};
  assign  b_i = {i_n[1],48'b0};
  assign  c_i = {i_n[2],48'b0};
  assign  d_i = {i_n[3],48'b0};
  assign  e_i = {i_n[4],48'b0};
  assign  f_i = {i_n[5],48'b0};
  assign  g_i = {i_n[6],48'b0};
  assign  h_i = {i_n[7],48'b0};
  assign  i_i = {i_n[8],48'b0};
  assign  j_i = {i_n[9],48'b0};
  assign  k_i = {i_n[10],48'b0};
  assign  l_i = {i_n[11],48'b0};
  assign  m_i = {i_n[12],48'b0};
  assign  n_i = {i_n[13],48'b0};
  assign  o_i = {i_n[14],48'b0};
  assign  p_i = {i_n[15],48'b0};

  assign  o_n[0] = a_o;
  assign  o_n[8] = b_o;
  assign  o_n[4] = c_o;
  assign  o_n[12] = d_o;
  assign  o_n[2] = e_o;
  assign  o_n[10] = f_o;
  assign  o_n[6] = g_o;
  assign  o_n[14] = h_o;
  assign  o_n[1] = i_o;
  assign  o_n[9] = j_o;
  assign  o_n[5] = k_o;
  assign  o_n[13] = l_o;
  assign  o_n[3] = m_o;
  assign  o_n[11] = n_o;
  assign  o_n[7] = o_o;
  assign  o_n[15] = p_o;

  assign o_out_valid = finish_r;

  always_comb begin
    state_w = state_r;
    start_w = 0;
    finish_w = finish_r;

    case(state_r) 
      IDLE: begin
        if(i_start) begin
          state_w = RUN;
          start_w = 1;
          finish_w = 0;
        end
      end

      RUN: begin
        if(valid) begin
          state_w = IDLE;
          start_w = 0;
          finish_w = 1;
        end
      end
    endcase
  end

  always_ff@ (posedge clk or posedge rst) begin
    if(rst) begin
      state_r <= IDLE;
      start_r <= 0;
      finish_r <= 0;
    end
    else begin
      state_r <= state_w;
      start_r <= start_w;
      finish_r <= finish_w;
    end
  end

endmodule