#!/usr/bin/env python3

import sys
import os.path

from Bio.SeqIO import FastaIO


INPUT = sys.argv[1]
OUTPUT = sys.argv[2]

seqs = []
with open(INPUT) as handle:
   for _, seq in FastaIO.SimpleFastaParser(handle):
        seqs.append(seq)

title_out = os.path.basename(INPUT)
seq_out = "NNNNNCATTCCATTCATTAATTAATTAATGAATGAATGNNNNN".join(seqs)

with open(OUTPUT, "w") as handle:
    handle.write(">{}\n".format(title_out))
    handle.write("{}\n".format(seq_out))
