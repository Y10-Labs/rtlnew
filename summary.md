# Lambda Generation Hardware Pipeline Implementation

## Complete Hardware Pipeline Implementation Table

| Stage | Operation | Hardware Expression | Python Equivalent | Notes |
|-------|-----------|-------------------|------------------|-------|
| **STAGE 0** | **Input Decode** | | | |
| | Unpack input bus | `{tID_s0, z1_s0, _, y1_s0, y2_s0, y3_s0, __, x1_s0, x2_s0, x3_s0, z2_s0, z3_s0} <= input_bus` | `tID, x1, x2, x3, y1, y2, y3, z1, z2, z3 = unpack_input(packed)` | 128-bit bus unpacking |
| **STAGE 1** | **Edge Vectors** | | | |
| | dl1x calculation | `dl1x_s1 <= y2_s0 - y1_s0` | `dl1x_s1 = y2 - y1` | Y-coordinate difference |
| | dl2x calculation | `dl2x_s1 <= y3_s0 - y2_s0` | `dl2x_s1 = y3 - y2` | Y-coordinate difference |
| | dl1y calculation | `dl1y_s1 <= x1_s0 - x2_s0` | `dl1y_s1 = x1 - x2` | X-coordinate difference |
| | dl2y calculation | `dl2y_s1 <= x2_s0 - x3_s0` | `dl2y_s1 = x2 - x3` | X-coordinate difference |
| | Pass through | `x1_s1 <= x1_s0`, `x2_s1 <= x2_s0`, etc. | `x1_s1 = x1`, `x2_s1 = x2`, etc. | Register propagation |
| **STAGE 2** | **Cross Products** | | | |
| | x12y1 product | `x12y1_s2 <= -$signed(dl1x_s1 * y1_s1)` | `x12y1_s2 = -(dl1x_s1 * y1)` | Negated signed multiply |
| | x23y2 product | `x23y2_s2 <= -$signed(dl2x_s1 * y2_s1)` | `x23y2_s2 = -(dl2x_s1 * y2)` | Negated signed multiply |
| | y12x1 product | `y12x1_s2 <= -$signed(dl1y_s1 * x1_s1)` | `y12x1_s2 = -(dl1y_s1 * x1)` | Negated signed multiply |
| | y23x2 product | `y23x2_s2 <= -$signed(dl2y_s1 * x2_s1)` | `y23x2_s2 = -(dl2y_s1 * x2)` | Negated signed multiply |
| | a0 calculation | `a0_s2 <= -$signed(dl1y_s1 * dl2x_s1)` | `a0_s2 = -(dl1y_s1 * dl2x_s1)` | Negated cross product |
| | a1 calculation | `a1_s2 <= -$signed(dl1x_s1 * dl2y_s1)` | `a1_s2 = -(dl1x_s1 * dl2y_s1)` | Negated cross product |
| | Pass through | `dl1x_s2 <= dl1x_s1`, `dl2x_s2 <= dl2x_s1`, etc. | `dl1x_s2 = dl1x_s1`, etc. | Register propagation |
| **STAGE 3** | **Edge Functions & Area** | | | |
| | E1 calculation | `E1_s3 <= (x12y1_s2 + y23x2_s2)` | `E1_s3 = x12y1_s2 + y23x2_s2` | Edge function 1 |
| | E2 calculation | `E2_s3 <= (x23y2_s2 + y12x1_s2)` | `E2_s3 = x23y2_s2 + y12x1_s2` | Edge function 2 |
| | Area calculation | `area_s3 <= a0_s2 + a1_s2` | `area_s3 = a0_s2 + a1_s2` | Triangle area (2x) |
| | Pass through | `dl1x_s3 <= dl1x_s2`, `dl2x_s3 <= dl2x_s2`, etc. | `dl1x_s3 = dl1x_s2`, etc. | Register propagation |
| **STAGE 4** | **Division with Scaling** | | | |
| | l1 calculation | `quo1 = (area_s3 != 0) ? (E1_s3 <<< 8) / area_s3 : 0` | `l1_s4 = int((E1_s3 << 8) / area_s3) if area_s3 != 0 else 0` | 8-bit scaled division, truncate toward zero |
| | l2 calculation | `quo2 = (area_s3 != 0) ? (E2_s3 <<< 8) / area_s3 : 0` | `l2_s4 = int((E2_s3 << 8) / area_s3) if area_s3 != 0 else 0` | 8-bit scaled division, truncate toward zero |
| | dl1x calculation | `quo3 = (area_s3 != 0) ? (dl1x_s3 <<< 8) / area_s3 : 0` | `dl1x_s4 = int((dl1x_s3 << 8) / area_s3) if area_s3 != 0 else 0` | 8-bit scaled division, truncate toward zero |
| | dl2x calculation | `quo4 = (area_s3 != 0) ? (dl2x_s3 <<< 8) / area_s3 : 0` | `dl2x_s4 = int((dl2x_s3 << 8) / area_s3) if area_s3 != 0 else 0` | 8-bit scaled division, truncate toward zero |
| | dl1y calculation | `quo5 = (area_s3 != 0) ? (dl1y_s3 <<< 8) / area_s3 : 0` | `dl1y_s4 = int((dl1y_s3 << 8) / area_s3) if area_s3 != 0 else 0` | 8-bit scaled division, truncate toward zero |
| | dl2y calculation | `quo6 = (area_s3 != 0) ? (dl2y_s3 <<< 8) / area_s3 : 0` | `dl2y_s4 = int((dl2y_s3 << 8) / area_s3) if area_s3 != 0 else 0` | 8-bit scaled division, truncate toward zero |
| | Register assignment | `l1_s4 <= quo1`, `l2_s4 <= quo2`, etc. | Store division results | Division results stored in registers |
| **STAGE 5** | **Z-Coordinate Interpolation** | | | |
| | l1*z1 product | `l1z1_s5 <= l1_s4 * z1_s4` | `l1z1_s5 = l1_s4 * z1` | Lambda 1 × Z1 |
| | l2*z2 product | `l2z2_s5 <= l2_s4 * z2_s4` | `l2z2_s5 = l2_s4 * z2` | Lambda 2 × Z2 |
| | l3*z3 product | `l3z3_s5 <= (256 - l1_s4 - l2_s4) * z3_s4` | `l3z3_s5 = (256 - l1_s4 - l2_s4) * z3` | Lambda 3 × Z3, where λ3 = 1-λ1-λ2 (scaled by 256) |
| | dlx1*z1 product | `dlx1z1_s5 <= dl1x_s4 * z1_s4` | `dlx1z1_s5 = dl1x_s4 * z1` | dλ1/dx × Z1 |
| | dlx2*z2 product | `dlx2z2_s5 <= dl2x_s4 * z2_s4` | `dlx2z2_s5 = dl2x_s4 * z2` | dλ2/dx × Z2 |
| | dlx3*z3 product | `dlx3z3_s5 <= (256 - dl1x_s4 - dl2x_s4) * z3_s4` | `dlx3z3_s5 = (256 - dl1x_s4 - dl2x_s4) * z3` | dλ3/dx × Z3 |
| | dly1*z1 product | `dly1z1_s5 <= dl1y_s4 * z1_s4` | `dly1z1_s5 = dl1y_s4 * z1` | dλ1/dy × Z1 |
| | dly2*z2 product | `dly2z2_s5 <= dl2y_s4 * z2_s4` | `dly2z2_s5 = dl2y_s4 * z2` | dλ2/dy × Z2 |
| | dly3*z3 product | `dly3z3_s5 <= (256 - dl1y_s4 - dl2y_s4) * z3_s4` | `dly3z3_s5 = (256 - dl1y_s4 - dl2y_s4) * z3` | dλ3/dy × Z3 |
| | Pass through | `l1_s5 <= l1_s4`, `l2_s5 <= l2_s4`, etc. | Register propagation of lambda values |
| **STAGE 6** | **Final Interpolation** | | | |
| | Z interpolation | `z_ <= l1z1_s5 + l2z2_s5 + l3z3_s5` | `z_ = l1z1_s5 + l2z2_s5 + l3z3_s5` | Final interpolated Z value |
| | Z derivative X | `dzx <= dlx1z1_s5 + dlx2z2_s5 + dlx3z3_s5` | `dzx = dlx1z1_s5 + dlx2z2_s5 + dlx3z3_s5` | dZ/dx derivative |
| | Z derivative Y | `dzy <= dly1z1_s5 + dly2z2_s5 + dly3z3_s5` | `dzy = dly1z1_s5 + dly2z2_s5 + dly3z3_s5` | dZ/dy derivative |
| | Pass through outputs | `l1_s6 <= l1_s5`, `l2_s6 <= l2_s5`, etc. | Final output assignments |