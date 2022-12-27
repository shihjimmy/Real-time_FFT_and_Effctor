module PanLR(
    input  [15:0] i_seq_l[16],
    input  [15:0] i_seq_r[16],
    input  [2:0] Pan, 
    //  Pan == 0->0  1->25  2->50 3->75 4->100
    output [15:0] o_seq_l[16],
    output [15:0] o_seq_r[16]
);

always_comb begin
    for(int i=0;i<16;i=i+1) begin
        case(Pan)
                4: begin
                    o_seq_l[i] = 0;
                    o_seq_r[i] = i_seq_r[i];
                end
                3: begin
                    o_seq_l[i] = i_seq_l[i]>>2;
                    o_seq_r[i] = (i_seq_r[i]>>1) + (i_seq_r[i]>>2); 
                end
                2: begin
                    o_seq_l[i] = i_seq_l[i]>>1;
                    o_seq_r[i] = i_seq_r[i]>>1;
                end
                1: begin
                    o_seq_r[i] = i_seq_r[i]>>2;
                    o_seq_l[i] = (i_seq_l[i]>>1) + (i_seq_l[i]>>2); 
                end
                0: begin
                    o_seq_r[i] = 0;
                    o_seq_l[i] = i_seq_l[i];
                end
                default: begin
                    o_seq_l[i] = i_seq_l[i];
                    o_seq_r[i] = i_seq_r[i];
                end
        endcase
    end
end

endmodule