# systolic_array
## todo
- [x] mac tile 2-4 bit switchable
- [x] mac tile tb
- [X] mac row
- [X] mac row tb 2-bit
- [X] mac row tb 4-bit
- [X] mac array
- [X] mac array tb
- [X] corelet
- [X] core
- [X] core tb 4 bit act 8x8
- [X] core tb 2 bit act 16x8
- [X] tiling 2 bit act 16x16 
- [X] core tb tiling 2 bit act 16x16 

## tiling notes
idea: parallel tiling, instantiate 2 corelets fed by same SRAM that output into 2 separate SRAM sets. 

1. load tile0's set of weights into SRAM, enable l0/loading for tile0, then load tile1's set of weights into SRAM, then enable L0/loading for tile1.

2. load activation into SRAM

3. enable execution for both in parallel; their respective data is stored into OFIFO.

4. write/acc into SRAM banks

5. goto 1 if kij < 9

6. 2 cycles to compare 1 "row" of OCs to output when verifying.