#!/usr/bin/env python3

import sys
import os
import re
import shutil

import pandas as pd


GENOME_INFO = sys.argv[1]
INPUT_GENOMES_DIR = sys.argv[2]
FILTERED_GENOMES_DIR = sys.argv[3]
MIN_COMPLETENESS = float(sys.argv[4])
MAX_CONTAMINATION = float(sys.argv[5])

def filter(row):
    genome_fn = os.path.join(INPUT_GENOMES_DIR, row["Genome"])
    if (row["Completeness"] >= MIN_COMPLETENESS) & \
        (row["Contamination"] <= MAX_CONTAMINATION):
        shutil.copy(genome_fn, FILTERED_GENOMES_DIR)

try:
    os.mkdir(FILTERED_GENOMES_DIR)
except FileExistsError:
    pass

genome_info_df = pd.read_table(GENOME_INFO, 
    sep='\t', header=0, engine='python')

genome_info_df.apply(filter, axis=1)
