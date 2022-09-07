#!/usr/bin/env python3

import sys
import os.path
import random
from collections import Counter

from Bio.SeqIO import FastaIO
from Bio import AlignIO


INPUT = sys.argv[1]
OUTPUT = sys.argv[2]
GAP_THR = float(sys.argv[3])
MIN_CONS = float(sys.argv[4])
MAX_CONS = float(sys.argv[5])
MAX_COLS = int(sys.argv[6])
RANDOM_SEED = int(sys.argv[7])


align = AlignIO.read(INPUT, "fasta")
n_rows = len(align)
n_cols = align.get_alignment_length()
keep = []
for col in range(n_cols):
    col_counter = Counter(align[:, col])
    n_gaps = 0
    for c in ['?', '-']:
        if c in col_counter:
            n_gaps += col_counter[c]

    n_most_common = col_counter.most_common(1)[0][1]
    
    frac_gaps = n_gaps / n_rows
    cons = n_most_common / n_rows
    print(frac_gaps)
    if (frac_gaps > GAP_THR) or (cons > MAX_CONS) or (cons < MIN_CONS):
        pass
    else:
        keep.append(col)

random.seed(RANDOM_SEED)
keep = random.sample(keep, min(len(keep), MAX_COLS))

with open(OUTPUT, "w") as handle:
    for record in align:
        new_seq = "".join([record.seq[i] for i in keep])
        handle.write(">{}\n".format(record.description))
        handle.write("{}\n".format(new_seq))
