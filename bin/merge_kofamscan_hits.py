#!/usr/bin/env python3

import argparse
import os.path

import pandas as pd


parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', metavar='input', nargs='+',
                    required=True, help='input files', )
parser.add_argument('-s', '--suffix', dest='suffix', required=False,
                    help='filename suffix', default='.hits.txt')              
args = parser.parse_args()

compl_df = pd.DataFrame()
for input_fn in args.input:
    input_bn = os.path.basename(input_fn)
    input_id = input_bn.split(args.suffix)[0]
    input_df = pd.read_fwf(input_fn, skiprows=[1],
        colspecs = [(0, 1), (2, 22), (22, 29), (54, 1024)])
    input_df = input_df[input_df['#'] == '*']
    input_df = input_df.groupby(["KO", "KO definition"]) \
        [["gene name"]].nunique()
    input_df = input_df.rename(columns = {"gene name": input_id})
    compl_df = pd.concat([compl_df, input_df], axis=1, join='outer')

compl_df.fillna(0, inplace=True)
compl_df.to_csv('kofamscan_hits.tsv', sep='\t', float_format='%.d')
