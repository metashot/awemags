import sys
import os.path

from Bio.SeqIO import FastaIO


seqs = []
with open(sys.argv[1]) as handle:
   for _, seq in FastaIO.SimpleFastaParser(handle):
        seqs.append(seq)

title_out = os.path.basename(sys.argv[1])
seq_out = "NNNNNCATTCCATTCATTAATTAATTAATGAATGAATGNNNNN".join(seqs)

with open(sys.argv[2], "w") as handle:
    handle.write(">{}\n".format(title_out))
    handle.write("{}\n".format(seq_out))
