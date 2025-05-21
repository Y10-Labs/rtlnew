#include "ap_int.h" // Required for ap_uint data types

/**
 * @brief C equivalent of the Verilog registerFile module for HLS.
 *
 * This function models a register file with 16 entries, each 28 bits wide.
 * It supports both single-word (28-bit) and SIMD (56-bit) read/write operations.
 *
 * @param rst Asynchronous reset signal. When high, all registers are cleared.
 * @param rs0 Read select address for output 0.
 * @param rs1 Read select address for output 1.
 * @param data_in Input data for write operations (56 bits).
 * @param dest_sel Destination address for write operations.
 * @param isrdSIMD Flag to enable SIMD read mode.
 * @param iswrSIMD Flag to enable SIMD write mode.
 * @param wen Write enable signal. When high, a write operation occurs.
 * @param dout0 Output data for read port 0 (56 bits). Passed by reference.
 * @param dout1 Output data for read port 1 (56 bits). Passed by reference.
 */
void registerFile(
    bool rst,            // Asynchronous reset
    ap_uint<4> rs0,      // Read select address 0
    ap_uint<4> rs1,      // Read select address 1
    ap_uint<56> data_in, // Input data for write
    ap_uint<4> dest_sel, // Destination address for write
    bool isrdSIMD,       // Is read SIMD?
    bool iswrSIMD,       // Is write SIMD?
    bool wen,            // Write enable
    ap_uint<56> &dout0,  // Output data 0
    ap_uint<56> &dout1   // Output data 1
) {
    // Declare the register file.
    // 'static' keyword is crucial for HLS to infer this as a state element (registers/memory).
    // It will be mapped to a Block RAM or distributed RAM depending on size and access patterns.
    static ap_uint<28> rf[16]; // 16 entries, each 28 bits wide

    // HLS PRAGMA: Explicitly infer 'rf' as individual registers.
    // This partitions the array 'rf' completely, meaning each element rf[i] will be a separate register.
    #pragma HLS ARRAY_PARTITION variable=rf complete dim=1

    // Asynchronous Reset Logic:
    // If 'rst' is high, clear all register file entries.
    // This logic takes precedence over other operations.
    if (rst) {
        for (int i = 0; i < 16; i++) {
            rf[i] = 0; // Reset each register to 0
        }
    } else {
        // Synchronous Write Logic:
        // This block describes the behavior that occurs on the active clock edge
        // (inferred by the HLS tool).
        if (wen) { // Only perform write if write enable is active
            if (iswrSIMD) {
                // SIMD Write Mode:
                // The 56-bit 'data_in' is split into two 28-bit halves.
                // The upper 28 bits (55:28) go into rf[dest_sel].
                // The lower 28 bits (27:0) go into rf[dest_sel + 1].
                rf[dest_sel] = data_in.range(55, 28);   // HLS C bit slicing: .range(MSB, LSB)
                rf[dest_sel + 1] = data_in.range(27, 0);
            } else {
                // Non-SIMD Write Mode:
                // Only the upper 28 bits (55:28) of 'data_in' are written into rf[dest_sel].
                rf[dest_sel] = data_in.range(55, 28);
            }
        }
    }

    // Combinational Read Logic:
    // These assignments are always active, similar to 'assign' statements in Verilog.
    // They reflect the current state of the register file based on read addresses.

    // Calculate dout0:
    if (isrdSIMD) {
        // SIMD Read Mode:
        // Concatenate rf[rs0] (upper 28 bits) and rf[rs0 + 1] (lower 28 bits)
        // to form the 56-bit 'dout0'.
        // Explicit cast to ap_uint<56> before shifting ensures the shift operates on 56 bits.
        dout0 = ((ap_uint<56>)rf[rs0] << 28) | rf[rs0 + 1];
    } else {
        // Non-SIMD Read Mode:
        // Concatenate rf[rs0] (upper 28 bits) with 28'b0 (lower 28 bits)
        // to form the 56-bit 'dout0'.
        dout0 = ((ap_uint<56>)rf[rs0] << 28);
    }

    // Calculate dout1:
    if (isrdSIMD) {
        // SIMD Read Mode:
        // Concatenate rf[rs1] (upper 28 bits) and rf[rs1 + 1] (lower 28 bits)
        // to form the 56-bit 'dout1'.
        dout1 = ((ap_uint<56>)rf[rs1] << 28) | rf[rs1 + 1];
    } else {
        // Non-SIMD Read Mode:
        // Concatenate rf[rs1] (upper 28 bits) with 28'b0 (lower 28 bits)
        // to form the 56-bit 'dout1'.
        dout1 = ((ap_uint<56>)rf[rs1] << 28);
    }
}
