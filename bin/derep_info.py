#!/usr/bin/env python3

import sys

import numpy as np
import pandas as pd
from sklearn import preprocessing


DREP_CDB = sys.argv[1]
DREP_WDB = sys.argv[2]
GENOME_EXT = sys.argv[3]
DEREP_INFO = sys.argv[4]


drep_cdb_df = pd.read_table(DREP_CDB, sep=',', header=0, engine='python') \
    .set_index('genome')
drep_wdb_df = pd.read_table(DREP_WDB, sep=',', header=0, engine='python') \
    .set_index("genome")

derep_info_df = drep_cdb_df.join(drep_wdb_df, on="genome")

derep_info_df["Representative"] = \
    np.where(pd.isnull(derep_info_df["cluster"]), "False", "True") 

derep_info_df = derep_info_df[["secondary_cluster", "Representative"]]. \
    reset_index(). \
    rename(columns={"genome": "Genome", "secondary_cluster": "Cluster"})

le = preprocessing.LabelEncoder()
derep_info_df["Cluster"] = le.fit_transform(derep_info_df["Cluster"])

derep_info_df["Genome"] = \
    derep_info_df["Genome"].str.replace(r'.{}$'.format(GENOME_EXT), '')

derep_info_df.to_csv(DEREP_INFO, sep='\t', index=False)
