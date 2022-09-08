#!/usr/bin/env python3

import sys
import os.path
import re
from collections import OrderedDict
import glob

import pandas as pd


BUSCO_SUMMARY_DIR=sys.argv[1]
STATS = sys.argv[2]
QUALITY=sys.argv[3]
GENOME_INFO_DREP=sys.argv[4]


class BuscoSummary():
    
    busco_counts_keys = OrderedDict([
        ('Complete', 'Complete BUSCOs'),
        ('Single', 'Complete and single-copy BUSCOs'), 
	    ('Duplicated', 'Complete and duplicated BUSCOs'),
        ('Fragmented', 'Fragmented BUSCOs'),
        ('Missing', 'Missing BUSCOs'),
        ('Total', 'Total BUSCO groups searched')
    ])

    def parse(self, fn):
        with open(fn) as fo:
            summary = fo.read()

        summary_dict = OrderedDict()

        # File
        p = re.compile(r'Summarized benchmarking in BUSCO notation for file '
                       r'(.+)' )
        m = p.search(summary)
        summary_dict['Genome'] = os.path.basename(m.group(1))
        
        # Lineage
        p = re.compile(r'The lineage dataset is: (\S+)' )
        m = p.search(summary)
        summary_dict['Lineage'] = m.group(1)
        
        # Counts        
        for key, value in self.busco_counts_keys.items():
            p = re.compile(r'([0-9]+)\t{}'.format(value))
            m = p.search(summary)
            summary_dict[key] = m.group(1)

        summary_dict['Completeness'] = \
            100. - 100. * int(summary_dict['Missing']) / \
                int(summary_dict['Total'])
        summary_dict['Contamination'] = \
            100. * int(summary_dict['Duplicated']) / \
                int(summary_dict['Complete'])

        return pd.Series(summary_dict)

# Busco summary
bs = BuscoSummary()
summary_list = []
for fn in glob.glob(os.path.join(BUSCO_SUMMARY_DIR, "*")):
    try:
        summary_list.append(bs.parse(fn))
    except:
        pass

summary_df = pd.DataFrame(summary_list).set_index("Genome")

# Stats
stats_df = pd.read_table(STATS, sep='\t')
stats_df = stats_df.rename(columns={
    "filename": "Genome",
    "scaf_bp": "Genome size (bp)",
    "n_scaffolds": "# scaffolds",
    "n_contigs": "# contigs",
    "scaf_N50": "N50 (scaffolds)",
    "ctg_N50": "N50 (contigs)",
    "scaf_L50": "L50 (scaffolds)",
    "ctg_L50": "L50 (contigs)",
    "scaf_max": "Longest scaffold (bp)",
    "ctg_max": "Longest contig (bp)",
    "gc_avg": "GC avg",
    "gc_std": "GC std"    
})

stats_df["Genome"] = stats_df["Genome"].apply(os.path.basename)
stats_df = stats_df.set_index("Genome")

# Concatenate Busco summary and stats
quality_df = pd.concat([summary_df, stats_df], axis=1, sort=False)
quality_df['Genome'] = quality_df.index
quality_df = quality_df[[
    "Genome",
    "Completeness",
    "Contamination",
    "Genome size (bp)",
    "# scaffolds",
    "# contigs",
    "N50 (scaffolds)",
    "N50 (contigs)",
    "L50 (scaffolds)",
    "L50 (contigs)",
    "Longest scaffold (bp)",
    "Longest contig (bp)",
    "GC avg",
    "GC std",
    "Lineage",
    "Complete",
    "Single",
    "Duplicated",
    "Fragmented",
    "Missing",
    "Total"
]]

quality_df[["Completeness", "Contamination"]] = \
    quality_df[["Completeness", "Contamination"]].fillna(0.0)
quality_df.fillna("NA", inplace=True)

quality_df.to_csv(QUALITY, sep='\t', index=False, float_format='%.2f')

# genome info for dRep
genome_info_drep = quality_df[[
    "Genome",
    "Completeness",
    "Contamination"]]

genome_info_drep.rename(columns={
    "Genome": "genome",
    "Completeness":"completeness",
    "Contamination": "contamination"
    }, inplace=True)

genome_info_drep.to_csv(GENOME_INFO_DREP, sep=',',
    index=False)