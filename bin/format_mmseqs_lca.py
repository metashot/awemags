#!/usr/bin/env python3

import sys
import os.path
import re
import glob

import pandas as pd


INPUT_LCA=sys.argv[1]
OUTPUT_LCA=sys.argv[2]

def format_classification(elem):
    return ";".join([re.sub("(uc_.*)|(unknown)", "", tax) \
        for tax in elem.split(';')])


lca_header = [
    'Genome',
    'TaxID', 
    'TaxRank',
    'Final classification',
    '# prot',
    '# prot w/ label',
    '# prot agree',
    'Label support',
    'Classification',
    'Full classification'
    ]

lca_df = pd.read_table(INPUT_LCA, sep='\t', names=lca_header)
lca_df['Classification'] = lca_df['Classification'].map(format_classification)
lca_df.to_csv(OUTPUT_LCA, sep='\t', index=False, float_format='%.3f')
