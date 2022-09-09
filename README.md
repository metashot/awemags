**metashot/aweMAGs is currently under development!**

metashot/aweMAGs is an automated workflow for **large-scale microbial eukaryotic
MAGs** (metagenome assembled genomes) analysis. Although aweMAGs has been
specifically designed for eukaryotic genomes, it can also work on prokaryotic or
viral MAGs.

**Reproducibility** is guaranteed by Nextflow and versioned Docker images.

**Note**: This workflow is not intended for classifying and annotating
"finished" SAGs (single amplified genomes) or MAGs. The "finished" category is
reserved for genomes that can be assembled with extensive manual review and
editing.

[MetaShot Home](https://metashot.github.io/)

**Table of contents**

- [Main features](#main-features)
- [Quick start](#quick-start)
- [Documentation](#documentation)
  - [Input and output](#input-and-output)
  - [Quality assessment and genome filtering](#quality-assessment-and-genome-filtering)
  - [Dereplication](#dereplication)
  - [Taxonomy classification and gene prediction */](#taxonomy-classification-and-gene-prediction-)
  - [eggNOG](#eggnog)
  - [Resource limits](#resource-limits)
- [Output](#output)
  - [BUSCO and genome bins filtering](#busco-and-genome-bins-filtering)
  - [Dereplication](#dereplication-1)
  - [Taxonomy classification](#taxonomy-classification)
  - [Gene prediction](#gene-prediction)
  - [eggNOG](#eggnog-1)
- [Documentation](#documentation-1)
  - [A note on dereplication](#a-note-on-dereplication)
- [System requirements](#system-requirements)
  - [Memory](#memory)
  - [Disk](#disk)

## Main features
aweMAGs is a container-enabled [Nextflow](https://www.nextflow.io/) pipeline for
quality assessment, dereplication, gene discovery, taxonomic and functional
annotation of eukariotic MAGs. It can run out-of-the-box on any platform that
supports Nextflow, [Docker](https://www.docker.com/) or
[Singularity](https://sylabs.io/singularity), including computing clusters or
batch infrastructures in the cloud. Main features:

- Completeness, contamination estimates and basic assambly statistics using
  [BUSCO](https://busco.ezlab.org/) v5 and
  [BBTools](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/);
- Dereplication with [dRep](https://github.com/MrOlm/drep);
- Multiple sequence alignment (MSA) of BUSCO single copy genes (SGCs) with
  [MUSCLE](https://drive5.com/muscle5/) v5; phylogenetic tree inference with
  [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/); 
- Fast taxonomic classification using [MMseqs2
  taxonomy](https://github.com/soedinglab/MMseqs2);
- Sensitive, reference-based gene discovery with
  [MetaEuk](https://github.com/soedinglab/metaeuk);
- Fast functional annotation using
  [EggNOG-mapper](https://github.com/eggnogdb/eggnog-mapper);
- Internal transcriber spacers extraction using ITSx
- Automatic download of databases;
- Summary tables for genome quality, taxonomy predictions and functional
  annotations.

<img
src=https://github.com/metashot/awemags/blob/master/docs/images/awemags.png
width="800">

Software included:

| Software | Version |
| -------- | ------- |
| BUSCO | 5.1.3 |
| BBTools | 38.79 |
| dRep | 2.6.2 |
| MUSCLE | 5.1 |
| RAxML | 8.2.12 |
| MMSeq2 | 13 |
| MetaEuk | 5 |
| EggNOG-mapper | 2.1.5 |
| ITSx | 1.1.2 |

## Quick start

1. Install Docker (or Singulariry) and Nextflow (see
   [Dependencies](https://metashot.github.io/#dependencies));

1. Run the full pipeline:
   
  ```bash
  nextflow run metashot/aweMAGs -r 1.0.0 \
    --genomes '*.fa' \
    --outdir results
  ```

  Using this command, the reference databases (BUSCO, MMseqs2 and eggNOG) will
  be downloaded automatically from the Internet.

## Documentation
Options and default values are decladed in [`nextflow.config`](nextflow.config).

### Input and output
- `--genomes`: input genomes/bins in FASTA format (default `"data/*.fa"`)
- `--outdir`: output directory (default `"results"`)

### Quality assessment and genome filtering
- `--skip_filtering`: skip quality assessment and and genome filtering.
- `--busco_db`: BUSCO database path for offline mode. (default 'none': download
    from Internet)
- `--lineage`: BUSCO lineage or lineage mode (default `"auto-euk"`). Accepted
  values are:
  - `"auto-euk"`, `"auto-prok"`, `"auto"` (auto lineage mode)
  - a dataset name (e.g. `"fungi"` or `"fungi_odb10"`) or
  - a path (e.g. `"/home/user/fungi_odb10"`) 
- `--min_completeness`: discard sequences with less than `min_completeness`%
    completeness (default 50)
- `--max_contamination`: discard sequences with more than `max_contamination`%
    contamination (default 10)

### Dereplication
By default, genomes will be dereplicated. After dereplication, for each cluster
the genome with the higher score is selected as representative. The score will
be computed using the following formula:

  ```
  score = completeness - 5 x contamination + 0.5 x log(N50)
  ```

If the quality assessment was skipped (`--skip_filtering` parameter),
the following formula will be used:
  
  ```
  score =  log(size)
  ```

By default the dereplication is performed with the 99% ANI threshold
(0.99, parameter `--ani_thr`).

- `--skip_dereplication`: skip the dereplication step
- `--ani_thr`: ANI threshold for dereplication (> 0.90, default 0.99)
- `--min_overlap`: minimum overlap fraction between genomes (default 0.3)

### Taxonomy classification and gene prediction */
- `skip_taxonomy`: skip the taxonomy classification (MMseqs2)
- `skip_genepred`: skip the gene prediction (MetaEuk)
- `mmseqs_db`: MMseqs2 database path (used by MMseqs2 and MetaEuk) (default
  "none": download from Internet). See the `mmseqs_db_name` parameter.
- `mmseqs_db_name`: MMseqs2 database name, used when mmseqs_db_path = "none".  
  The available databases are listed at
  https://github.com/soedinglab/mmseqs2/wiki#downloading-databases (default
  "UniProtKB/Swiss-Prot")

### eggNOG
- `skip_eggnog`: skip eggNOG annotation
- `eggnog_db`: eggNOG v5.0 database dir. (default "none": download from
  Internet)
- `eggnog_db_mem`: store the eggNOG sqlite DB into memory (~44GB memory
  required) increasing the annotation speed.

### Resource limits
- `--max_cpus`: maximum number of CPUs for each process (default `8`)
- `--max_memory`: maximum memory for each process (default `240.GB`)
- `--max_time`: maximum time for each process (default `120.h`)

See also [System requirements](https://metashot.github.io/#system-requirements).

## Output
The files and directories listed below will be created in the `results`
directory after the pipeline has finished.

### BUSCO and genome bins filtering
- `quality.tsv`: summary of genomes quality (including completeness,
  contamination, N50 ...
- `filtered`: this folder contains the genomes filtered according to
  `--min_completeness` and `--max_contamination` options

### Dereplication
- `derep_info.tsv`: dereplication summary (if `--skip_dereplication=false`)
  This file contains:
  - Genome: genome filename
  - Cluster: the cluster ID (from 0 to N-1)
  - Representative: is this genome the cluster representative?
- `filtered_repr`: this folder contains the representative genomes
- `drep`: original data tables, figures and log of drep.

### Taxonomy classification
- `taxonomy.tsv`: summary of the taxonomic classification
- `mmseqs`: directory containing the original MMseqs2 taxonomy files (including
  the Kraken style reports)

### Gene prediction
- `metaeuk`: directory containing the original MetaEuk files (including the
  protein sequences and the GFF files)

### eggNOG
- `eggnog_*.tsv`: the count matrix for each transferred annotation
- `eggnog`: directory containing the original eggNOG files

## Documentation

### A note on dereplication


## System requirements
Please refer to [System
requirements](https://metashot.github.io/#system-requirements) for the complete
list of system requirements options.

### Memory
Meta


CheckM requires approximately 70 GB of memory. However, if you have only 16 GB
RAM, a reduced genome tree (`--reduced_tree` option) can also be used (see
https://github.com/Ecogenomics/CheckM/wiki/Installation#system-requirements).

### Disk
For each GB of input data the workflow requires approximately 0.5/1 GB for the
final output and 2/3 GB for the working directory.


mmseqs databases UniProtKB/Swiss-Prot outpath/swissprot tmp