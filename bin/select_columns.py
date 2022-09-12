#!/usr/bin/env python3

import sys
import os.path
import random
from collections import Counter

from Bio.SeqIO import FastaIO
from Bio import AlignIO


INPUT = sys.argv[1]
OUTPUT = sys.argv[2]
N_GENOMES = int(sys.argv[3])
GAP_THR = float(sys.argv[4])
MIN_CONS = float(sys.argv[5])
MAX_CONS = float(sys.argv[6])
MAX_COLS = int(sys.argv[7])
RANDOM_SEED = int(sys.argv[8])


align = AlignIO.read(INPUT, "fasta")
n_rows = len(align)
n_cols = align.get_alignment_length()
keep = []
for col in range(n_cols):
    col_counter = Counter(align[:, col])
    n_gaps = col_counter['-'] + (N_GENOMES - n_rows)
    del col_counter['-']
    n_most_common = col_counter.most_common(1)[0][1]
    frac_gaps = n_gaps / N_GENOMES
    cons = n_most_common / n_rows
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
