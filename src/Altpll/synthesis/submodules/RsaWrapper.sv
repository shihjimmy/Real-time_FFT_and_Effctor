module Rsa256Wrapper (
    input          avm_rst,
    input          avm_clk,
    output [  4:0] avm_address,
    output         avm_read,
    input  [ 31:0] avm_readdata,
    output         avm_write,
    output [ 31:0] avm_writedata,
    input          avm_waitrequest,
    // frequencies to sent
    input  [127:0] freqs,            // 16 16bit frequency amplitude 
    // parameters
    output [ 15:0] threshold_gate,   // -inf ~ 0 (0 ~ 32767)
    output [ 15:0] threshold_comp,   // -inf ~ 0 (0 ~ 32767)
    output [  4:0] ratio,            // 1:1 ~ 31:1
    output [ 15:0] makeup            // (0 ~ 32767)
);

  localparam RX_BASE = 0 * 4;
  localparam TX_BASE = 1 * 4;
  localparam STATUS_BASE = 2 * 4;
  localparam TX_OK_BIT = 6;
  localparam RX_OK_BIT = 7;

  // States
  localparam S_IDLE = 0;
  localparam S_RECEIVE = 1;
  localparam S_SEND = 2;
  localparam S_UPDATE = 3;

  // parameters and frequencies
  logic [127:0] freqs_r, freqs_w;
  logic [15:0] threshold_gate_r, threshold_gate_w;
  logic [15:0] threshold_camp_r, threshold_camp_w;
  logic [4:0] ratio_r, ratio_w;
  logic [15:0] makeup_r, makeup_w;

  logic [1:0] state_r, state_w;
  logic [31:0] rcv_data_r, rcv_data_w;  // [31:16] id + [15:0] data
  logic [1:0] rcv_counter_r, rcv_counter_w;  // at most 4 bytes
  logic [3:0] send_counter_r, send_counter_w;  // at most 16 bytes
  logic [4:0] avm_address_r, avm_address_w;
  logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

  assign threshold_comp = threshold_camp_r;
  assign threshold_gate = threshold_gate_r;
  assign ratio = ratio_r;
  assign makeup = makeup_r;

  assign avm_address = avm_address_r;
  assign avm_read = avm_read_r;
  assign avm_write = avm_write_r;
  assign avm_writedata = freqs_r[127-:8];

  task StartRead;
    input [4:0] addr;
    begin
      avm_read_w = 1;
      avm_write_w = 0;
      avm_address_w = addr;
    end
  endtask

  task StartWrite;
    input [4:0] addr;
    begin
      avm_read_w = 0;
      avm_write_w = 1;
      avm_address_w = addr;
    end
  endtask

  always_comb begin
    state_w = state_r;
    rcv_counter_w = rcv_counter_r;
    send_counter_w = send_counter_r;
    rcv_data_w = rcv_data_r;
    avm_address_w = avm_address_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    state_w = state_r;
    rcv_counter_w = rcv_counter_r;
    send_counter_w = send_counter_r;
    rcv_data_w = rcv_counter_r;
    // parameters and frequencies
    freqs_w = freqs_r;
    threshold_gate_w = threshold_gate_r;
    threshold_camp_w = threshold_camp_r;
    ratio_w = ratio_r;

    case (state_r)
      S_IDLE: begin
        if (!avm_waitrequest && avm_readdata[RX_OK_BIT]) begin  // Rx ready => python ready to write
          state_w = S_RECEIVE;
          StartRead(RX_BASE);
        end else if (!avm_waitrequest && avm_readdata[TX_OK_BIT]) begin  // Tx ready => python ready to read
          state_w = S_SEND;
          StartWrite(TX_BASE);
        end
        begin
          // Rx isn't ready, do nothing
          state_w = S_IDLE;
          StartRead(STATUS_BASE);
        end
      end

      S_RECEIVE: begin
        StartRead(STATUS_BASE);
        if (!avm_waitrequest) begin
          rcv_data_w = (rcv_data_r << 8) + avm_readdata[7:0];
          if (&rcv_counter_r) begin  // finished
            state_w = S_UPDATE;
            rcv_counter_w = 2'd0;
          end else begin
            state_w = S_IDLE;
            rcv_counter_w = rcv_counter_r + 2'd1;
          end
        end else begin
          state_w = S_IDLE;
        end
      end

      S_SEND: begin
        StartRead(STATUS_BASE);
        if (!avm_waitrequest) begin
          freqs_w = freqs_r << 8;
          if (&send_counter_r) begin  // finished
            state_w = S_UPDATE;
            send_counter_w = 0;
          end else begin
            state_w = S_IDLE;
            send_counter_w = send_counter_r + 4'd1;
          end
        end else begin
          state_w = S_IDLE;
        end
      end

      S_UPDATE: begin
        state_w = S_IDLE;
        freqs_w = freqs;  // update freqs
        rcv_data_w = rcv_data_r;
        StartRead(STATUS_BASE);
        case (rcv_data_r[31:16])
          16'd0: begin  // threshold (gate)
            threshold_gate_w = rcv_data_r[14:0];
          end
          16'd1: begin  // threshold (compressor)
            threshold_camp_w = rcv_data_r[14:0];
          end
          16'd2: begin  // ratio
            ratio_w = rcv_data_r[4:0];
          end
          16'd3: begin  // makeup
            makeup_w = rcv_data_r[14:0];
          end
        endcase
      end
    endcase
  end

  always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin  // reset
      avm_address_r <= STATUS_BASE;
      avm_read_r <= 1;
      avm_write_r <= 0;
      state_r <= S_IDLE;
      rcv_counter_r <= 0;
      send_counter_r <= 0;
      rcv_data_r <= 32'd0;
      // parameters and frequencies
      freqs_r <= freqs;
      threshold_gate_r <= 15'd0;
      threshold_camp_r <= 15'd16383;
      ratio_r <= 1;
    end else begin
      avm_address_r <= avm_address_w;
      avm_read_r <= avm_read_w;
      avm_write_r <= avm_write_w;
      state_r <= state_w;
      rcv_counter_r <= rcv_counter_w;
      send_counter_r <= send_counter_w;
      rcv_data_r <= rcv_counter_w;
      // parameters and frequencies
      freqs_r = freqs_w;
      threshold_gate_r <= threshold_gate_w;
      threshold_camp_r <= threshold_camp_w;
      ratio_r <= ratio_w;
    end
  end

endmodule
