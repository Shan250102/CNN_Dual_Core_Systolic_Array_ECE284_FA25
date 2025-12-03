wfname = [f"weight_itile0_otile0_kij{k}.txt" for k in range(9)]
afname = "activation_tile0.txt"

wfs = []
for fn in wfname:
    with open(fn, "r") as f:
        wfs.append(f.read())

with open(afname, "r") as f:
    af = f.read()

wfs = [wf.strip().split("\n")[3:] for wf in wfs]
af = af.strip().split("\n")[3:] 

wrd = 4

# print(wf)

wfs = [
    [
        [(int(j, 2) - 2**4) 
        if ((j := row[i : i+4])[0] == '1')
        else int(j, 2) 
        for i in range(0, len(row), 4)] for row in wf]
     for wf in wfs
     ]

a = [
    [int(j, 2)
     if ((j := row[i : i+4])[0] == '1')
     else int(j,2) 
     for i in range(0, len(row), 4)] for row in af]

import numpy as np

wfs = [np.array(w).T[::-1] for w in wfs]
a = np.array(a)[:, ::-1]

acc = 0
for i in range(0,9):
    print(f"\t ============ psum {i} =============")
    # print(np.matmul(a, wfs[i]))
    acc = np.matmul(a, wfs[i]) + acc
    print(acc)

print(a.shape, wfs[0].shape)