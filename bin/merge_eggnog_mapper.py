#!/usr/bin/env python3

import argparse
import os.path

import pandas as pd


parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', metavar='input', nargs='+',
                    required=True, help='input files', )
parser.add_argument('-s', '--suffix', dest='suffix', required=False,
                    help='filename suffix', default='.emapper.annotations')              
args = parser.parse_args()


def split_annot(annot, delim=','):
    if delim == '':
        return list(annot)
    else:
        return annot.split(delim)

def count(input_df, input_id, col, delim=','):
    output_df = input_df[["#query", col]].copy()
    output_df[col] = output_df.apply(lambda row: split_annot(row[col], delim),
        axis=1)
    output_df = output_df.explode(col).reset_index(drop=True)
    output_df = output_df.groupby([col]).nunique()
    
    output_df = output_df.rename(columns = {"#query": input_id})
    return output_df


cols = {
    'COG_category': ['', 'eggnog_COG_category.tsv'],
    'GOs': [',', 'eggnog_GOs.tsv'],
    'EC': [',', 'eggnog_EC.tsv'],
    'KEGG_ko': [',', 'eggnog_KEGG_ko.tsv'],
    'KEGG_Pathway': [',', 'eggnog_KEGG_Pathway.tsv'],
    'KEGG_Module': [',', 'eggnog_KEGG_Module.tsv'],
    'KEGG_Reaction': [',', 'eggnog_KEGG_Reaction.tsv'],
    'KEGG_rclass': [',', 'eggnog_KEGG_rclass.tsv'],
    'BRITE': [',', 'eggnog_BRITE.tsv'],
    'KEGG_TC': [',', 'eggnog_KEGG_TC.tsv'],
    'CAZy': [',', 'eggnog_CAZy.tsv'],
    'BiGG_Reaction': [',', 'eggnog_BiGG_Reaction.tsv'],
    'PFAMs': [',', 'eggnog_PFAMs.tsv']
}

seed_ortholog_df = pd.DataFrame()
count_dfs = {}
for col in cols:
    count_dfs[col] = pd.DataFrame()

for input_fn in args.input:
    input_bn = os.path.basename(input_fn)
    input_id = input_bn.split(args.suffix)[0]
    input_df = pd.read_table(input_fn, sep='\t', skiprows=4, skipfooter=3,
        engine='python')
    
    for col, col_feats in cols.items():
        tmp_df = count(input_df, input_id, col, delim=col_feats[0])
        count_dfs[col] = pd.concat([count_dfs[col], tmp_df], axis=1,
            join='outer')

for col, col_feats in cols.items():
    count_dfs[col].fillna(0, inplace=True)
    count_dfs[col].to_csv(col_feats[1], sep='\t', float_format='%.d')
