import torch
import torch.nn as nn
import numpy as np

reluEnable = True


# Set random seed for reproducibility
torch.manual_seed(42)

# Create the convolution layer
conv = nn.Conv2d(
    in_channels=8,     # 8 input channels
    out_channels=8,    # 8 output channels  
    kernel_size=3,     # 3x3 kernel
    padding=0,         # no padding
    bias=False          # include bias term
)
prefix = "tests/4_8x8/"
# Print layer information
print(f"Conv layer: {conv}")
print(f"Weight shape: {conv.weight.shape}")  # [out_channels, in_channels, kernel_h, kernel_w]
conv.weight = nn.Parameter(torch.randint(-8, 8, (8, 8, 3, 3)), requires_grad=False)

# Create random input tensor: [batch_size, channels, height, width]
input_tensor = torch.randint(16, (8, 6, 6))  # batch_size=1, 8 channels, 6x6 spatial
print(f"Input shape: {input_tensor.shape}")

# Perform convolution
output = conv(input_tensor)
print(f"Output shape: {output.shape}")  # Should be [1, 8, 4, 4] (6-3+1=4)

# print(output)


X = torch.flatten(input_tensor, 1,2)

tile_id = 0 
nij = 200 # just a random number


bit_precision = 4
file = open(prefix+'act_tile0.txt', 'w') #write to file
file.write('#time0row7[msb-lsb],time0row6[msb-lst],....,time0row0[msb-lst]#\n')
file.write('#time1row7[msb-lsb],time1row6[msb-lst],....,time1row0[msb-lst]#\n')
file.write('#................#\n')

for i in range(X.size(1)):  # time step
    for j in range(X.size(0)): # row #
        X_bin = '{0:04b}'.format(round(X[7-j,i].item()))
        for k in range(bit_precision):
            file.write(X_bin[k])        
        #file.write(' ')  # for visibility with blank between words, you can use
    file.write('\n')
file.close() #close file    

# print(X)


z = lambda x: ("{0:04b}".format(x) if x >= 0 else "1{0:03b}".format(8+x))

tile_id = 0 
kij = 0

W = torch.flatten(conv.weight, 2,3)
# W[:,:,0] = (torch.arange((8*8))%16 - 8).reshape(8,8)

# W = w_tile[tile_id,:,:,kij]  # w_tile[tile_num, array col num, array row num, kij]

bit_precision = 4

for kij in range(9):
    file = open(f'{prefix}w_i0_o0_kij{kij}.txt', 'w') #write to file
    file.write('#time0row7[msb-lsb],time0row6[msb-lst],....,time0row0[msb-lst]#\n')
    file.write('#time1row7[msb-lsb],time1row6[msb-lst],....,time1row0[msb-lst]#\n')
    file.write('#................#\n')
    for j in range(W.size(0)): # per OC
        for i in range(W.size(1)):  # per IC
            W_bin = z(round(W[j,7-i,kij].item())) # reverse IC
            for k in range(bit_precision):
                file.write(W_bin[k])        
            #file.write(' ')  # for visibility with blank between words, you can use
        file.write('\n')
    file.close() #close file   

print(W.shape)

# want input  channel to be a row?
# output channel is columns


# OC IC KIJ

print(output.flatten(1,2).T)

'''
tensor([[ -841,   108,  -367,  -164,  -677,  -677,  -362,  -425],
        [    6,    89,  -535,   112,  -168,   -83,  -640,  -617],
        [ -122,   140,  -550,  -440,   255,    41,  -506,  -270],
        [ -121,  -234,  -674,  -487,   -93,  -134,  -443,  -199],
        [ -203,   -13,  -643,  -404,   -65,   -67,  -753,  -171],
        [   77,   -89,  -705,  -331,  -527,  -142, -1035,  -409],
        [ -270,   -32,  -486,   160,  -398,   -42,  -605,  -592],
        [ -185,   -16,  -828,  -150,   -63,  -119,  -418,  -607],
        [ -252,   306,  -636,  -125,  -277,  -293,  -627,  -738],
        [ -315,    54,  -814,  -168,   -44,   125,  -810,  -599],
        [ -343,   375,  -790,  -461,  -254,   137,  -563,  -325],
        [ -178,    90,  -563,  -400,  -463,   -28,  -592,  -306],
        [ -361,   396,  -754,  -188,   -72,  -187,  -888,  -570],
        [   64,   437,  -820,  -404,  -225,  -252,  -521,  -756],
        [ -355,     7,  -719,   315,  -594,  -281,  -466,  -261],
        [ -318,   272,  -461,  -150,  -312,  -332,  -680,  -409]])


'''

P = output.flatten(1,2).T
if reluEnable:
    P = nn.ReLU()(P)

z = lambda x: ("{0:016b}".format(x) if x >= 0 else "1{0:015b}".format(2**15+x))

# W[:,:,0] = (torch.arange((8*8))%16 - 8).reshape(8,8)

# W = w_tile[tile_id,:,:,kij]  # w_tile[tile_num, array col num, array row num, kij]

bit_precision = 16
file = open(f'{prefix}out.txt', 'w') #write to file

file.write('#time0row7[msb-lsb],time0row6[msb-lst],....,time0row0[msb-lst]#\n')
file.write('#time1row7[msb-lsb],time1row6[msb-lst],....,time1row0[msb-lst]#\n')
file.write('#................#\n')
for j in range(P.size(0)): # per row
    for i in range(P.size(1)):  # per col
        W_bin = z(round(P[j,7-i].item())) # reverse OC
        for k in range(bit_precision):
            file.write(W_bin[k])        
        #file.write(' ')  # for visibility with blank between words, you can use
    file.write('\n')
file.close() #close file   

# print(W.shape)