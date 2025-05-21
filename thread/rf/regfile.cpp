#include <ap_int.h>

void registerFile(
    bool clk,
    bool rst,
    ap_uint<4> rs0,
    ap_uint<4> rs1,
    ap_uint<56> data_in,
    ap_uint<4> dest_sel,
    bool isrdSIMD,
    bool iswrSIMD,
    bool wen,
    ap_uint<56> &dout0,
    ap_uint<56> &dout1
) {
    #pragma HLS INTERFACE ap_none port=clk
    #pragma HLS INTERFACE ap_none port=rst
    #pragma HLS INTERFACE ap_none port=rs0
    #pragma HLS INTERFACE ap_none port=rs1
    #pragma HLS INTERFACE ap_none port=data_in
    #pragma HLS INTERFACE ap_none port=dest_sel
    #pragma HLS INTERFACE ap_none port=isrdSIMD
    #pragma HLS INTERFACE ap_none port=iswrSIMD
    #pragma HLS INTERFACE ap_none port=wen
    #pragma HLS INTERFACE ap_none port=dout0
    #pragma HLS INTERFACE ap_none port=dout1
    #pragma HLS INTERFACE ap_ctrl_none port=return

    // Register file: 16 entries of 28-bit registers
    static ap_uint<28> rf[16];
    #pragma HLS ARRAY_PARTITION variable=rf complete dim=1
    #pragma HLS RESOURCE variable=rf core=Register

    #pragma HLS PIPELINE II=1

    // Reset logic
    if (rst) {
        for (int i = 0; i < 16; i++) {
            #pragma HLS UNROLL
            rf[i] = 0;
        }
    } else {
        // Write logic
        if (wen) {
            if (iswrSIMD) {
                rf[dest_sel]     = data_in.range(55, 28);
                rf[dest_sel + 1] = data_in.range(27, 0);
            } else {
                rf[dest_sel]     = data_in.range(55, 28);
            }
        }
    }

    // Read logic
    if (isrdSIMD) {
        dout0.range(55, 28) = rf[rs0];
        dout0.range(27, 0)  = rf[rs0 + 1];
        dout1.range(55, 28) = rf[rs1];
        dout1.range(27, 0)  = rf[rs1 + 1];
    } else {
        dout0.range(55, 28) = rf[rs0];
        dout0.range(27, 0)  = 0;
        dout1.range(55, 28) = rf[rs1];
        dout1.range(27, 0)  = 0;
    }
}
