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
  - [Example 1](#example-1)
  - [Example 2](#example-2)
- [Documentation](#documentation)
  - [Input and output](#input-and-output)
  - [Quality assessment](#quality-assessment)
  - [Genomes filtering](#genomes-filtering)
  - [Dereplication](#dereplication)
  - [Single-copy genes (SCG) MSA](#single-copy-genes-scg-msa)
  - [Phylogenetic tree inference (requires MSA)](#phylogenetic-tree-inference-requires-msa)
  - [Taxonomic classification](#taxonomic-classification)
  - [Gene discovery/prediction](#gene-discoveryprediction)
  - [The MMseqs2 database](#the-mmseqs2-database)
  - [EggNOG](#eggnog)
  - [ITSx](#itsx)
  - [Resource limits](#resource-limits)
- [System requirements](#system-requirements)

## Main features
aweMAGs is a container-enabled [Nextflow](https://www.nextflow.io/) pipeline for
an automated quality assessment, dereplication, gene discovery, taxonomic and
functional annotation of **eukariotic genomes/MAGs**. It can run out-of-the-box on
any platform that supports Nextflow, [Docker](https://www.docker.com/) or
[Singularity](https://sylabs.io/singularity), including computing clusters or
batch infrastructures in the cloud. Main features:

- Completeness, contamination estimates and basic assambly statistics using
  [BUSCO](https://busco.ezlab.org/)[^busco] v5 and
  [BBTools](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/);
- Dereplication with [dRep](https://github.com/MrOlm/drep)[^drep];
- Multiple sequence alignment (MSA) of BUSCO single copy genes (SGCs) with
  [MUSCLE](https://drive5.com/muscle5/)[^muscle5] v5; phylogenetic tree inference with
  [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/)[^raxml]; 
- Fast taxonomic classification using [MMseqs2
  taxonomy](https://github.com/soedinglab/MMseqs2)[^mmseqs2];
- Sensitive, reference-based gene discovery with
  [MetaEuk](https://github.com/soedinglab/metaeuk)[^metaeuk];
- Fast functional annotation using
  [EggNOG-mapper](https://github.com/eggnogdb/eggnog-mapper)[^eggnog_mapper];
- Internal transcriber spacers extraction using
  [ITSx](https://microbiology.se/software/itsx/)[^itsx];
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

Install Docker (or Singulariry) and Nextflow (see
[Dependencies](https://metashot.github.io/#dependencies))
   
### Example 1
Full pipeline, auto lineage mode (eukaryotes)
  
  ```bash
  nextflow run metashot/awemags -r 1.0.0 \
    --genomes '*.fa' \
    --outdir results
  ```
Using this command, the reference databases (BUSCO, MMseqs2 and eggNOG) will be
downloaded automatically from the Internet.

### Example 2
1. Manually download the MMseqs2 Swiss-Prot database for the taxonomic
classification;
1. Manually download the BUSCO fungal database;
1. Extract fungal genomes only, skip gene prediction and EggNOG annotation.

  ```bash
  # MMseq2 database download (Swiss-Prot)
  alias mmseqs='docker run --rm --user $(id -u):$(id -g) -v $PWD:/wd -w /wd metashot/mmseqs2:13-1 mmseqs'
  #alias mmseqs='singularity exec -B $PWD docker://metashot/mmseqs2:13-1 mmseqs'
  mkdir mmseqs2_db
  mmseqs databases UniProtKB/Swiss-Prot mmseqs2_db/swissprot tmp

  # BUSCO database download (fungi)
  wget https://busco-data.ezlab.org/v5/data/lineages/fungi_odb10.2021-06-28.tar.gz \
    --no-check-certificate -O fungi_odb10.tar.gz
  tar -zxf fungi_odb10.tar.gz

  # Run aweMAGs
  nextflow run metashot/awemags -r 1.0.0 \
    --genomes '*.fa' \
    --outdir results \
    --lineage ./fungi_odb10 \
    --mmseqs_db mmseqs2_db/swissprot \
    --skip_genepred \
    --skip_eggnog
  ```

## Documentation
Options and default values are decladed in [`nextflow.config`](nextflow.config).

### Input and output

#### Options
- `--genomes`: input genomes/bins in FASTA format (default `"data/*.fa"`).
- `--outdir`: output directory (default `"results"`).


### Quality assessment
Quality assessment is performed for each input genome/metagenomic bin using
BUSCO v5 and the BBTools's statswrapper program.

#### Options
- `--busco_db`: BUSCO database path for offline mode. (default 'none': download
    from Internet).
- `--lineage`: BUSCO lineage or lineage mode (default `"auto-euk"`). Accepted
  values are:
  - `"auto-euk"`, `"auto-prok"`, `"auto"` (auto lineage mode)
  - a dataset name (e.g. `"fungi"` or `"fungi_odb10"`) or
  - a path (e.g. `"/home/user/fungi_odb10"`) .

#### Outputs
- `quality.tsv`: summary of genomes quality (including completeness,
  contamination, N50 ...).
- `busco`: main BUSCO's original output files.
- `statswrapper`: original BBTools's statswrapper output.


### Genomes filtering
This step discards sequences that do not meet the filtering
(completeness/contamination) criteria.

#### Options
- `--skip_filtering`: skip genomes filtering.
- `--min_completeness`: discard sequences with less than `min_completeness`%
    completeness (default 50). Completeness is computed as the fraction of
    complete BUSCOs genes (single-copy or duplicate) found for a particular
    lineage.
- `--max_contamination`: discard sequences with more than `max_contamination`%
    contamination (default 10). Contamination (better "redundancy" in this case)
    is computed as ``# duplicated BUSCOs / # complete BUSCOs``.

#### Outputs
- `filtered`: this folder contains the genomes filtered according to
  `--min_completeness` and `--max_contamination` options.


### Dereplication
In this step, input genomes will be clustered using a defined average nucleotide
identity (ANI) threshold (by default 99% ANI, parameter `--ani_thr 0.99`). For
each cluster, the genome with the higher score is selected as representative.
The score will be computed using the following formula:

  ```
  score = completeness - 5 x contamination + 0.5 x log(N50)
  ```

If genomes filtering was not performed (`--skip_filtering` parameter), all the
input genomes will be analyzed and the following formula will be used:
  
  ```
  score =  log(size)
  ```

#### Options
- `--skip_dereplication`: skip the dereplication step.
- `--ani_thr`: ANI threshold for dereplication (> 0.90, default 0.99).
- `--min_overlap`: minimum overlap fraction between genomes (default 0.3).

#### Outputs
- `derep_info.tsv`: dereplication summary, a TSV file containing three columns:
  - Genome: genome filename
  - Cluster: the cluster ID (from 0 to N-1)
  - Representative: is this genome the cluster representative?
- `representatives`: this folder contains the representative genomes
- `drep`: original data tables, figures and log of dRep.


### Single-copy genes (SCG) MSA
When the BUSCO auto-lineage search is deactivaded (e.g. `--lineage fungi` and
not `auto`, `auto-prok` or `auto-euk`) the single-copy core genes predicted by
BUSCO will be aligned using MUSCLE v5.

#### Options
- `--skip_msa`: skip BUSCO SCG MSA

#### Outputs
- `sgc/faa`: this folder contains the single-copy genes (one SCG per FASTA file)
- `sgc/msa`: contains the MSA for each SCG


### Phylogenetic tree inference (requires MSA)
For each SCG MSA, columns represented in <50% of the genomes or columns with
less than 25% or more than 95% amino acid consensus are trimmed in order to
remove sites with weak phylogenetic signals[^gtdb_arc]. To reduce total number of
columns selected for tree inference, the alignment was further trimmed by
randomly selecting `floor( MAX_NCOLS / N_SGC )` columns, where `MAX_NCOLS`
is the maximum number of columns for the final MSA (parameter `--max_ncols`,
default 5000) and `N_SGC` is the total number of BUSCO SGC for the specified lineage. Finally,
the trimmed MSAs are concatenated into a single MSA and the phylogenomic tree is
inferred using RAxML. Two modes are available for RAxML:

- default mode: construct a maximum likelihood (ML) tree. This mode runs the
  default RAxML tree search algorithm[^raxml_search] and perform multiple
  searches for the best tree (10 distinct randomized MP trees by default, see
  the parameter `--raxml_nsearch`). The following RAxML parameters will be used:

  ```bash
  -f d -m PROTGAMMAWAG -N [RAXML_NSEARCH] -p 42
  ```
- rbs mode: assess the robustness of inference and construct a ML tree. This
  mode runs the rapid bootstrapping full analysis[^raxml_bootstrap]. The
  bootstrap convergence criterion or the number of bootstrap searches can be
  specified with the parameter `--raxml_nboot`. The following parameters will be
  used:

  ```bash
  -f a -m PROTGAMMAWAG -N [RAXML_NBOOT] -p 42 -x 43
  ```
#### Options
- `--skip_tree` skip phylogenetic tree inference.
- `--max_ncols`: maximum number of MSA columns (taken randomly) for tree
  inference (default 5000).
- `--seed_cols`: random seed for the random selection of the columns (default
  42).
- `--raxml_mode`: RAxML mode , "default": default RAxML tree search algorithm or
  "rbs": rapid bootstrapping full analysis.
- `--raxml_nsearch`: "default" mode only: number of inferences on the original
  alignment using distinct randomized MP trees (if ­10 is specified, RAxML will
  compute 10 distinct ML trees starting from 10 distinct randomized maximum
  parsimony starting trees) (default 10).
- `--raxml_nboot`: "rbs" mode only. Bootstrap convergence criterion or number of
  bootstrap searches (see -I and -#/-N options in RAxML) (default "autoMRE").

#### Outputs
- `tree/trim_msa`: this folder contains the trimmed MSA for each SCG.
- `tree/concat.msa.faa`: the concatenated MSA used for the tree inference.
- `tree/RAxML_bestTree.run`: the best-scoring ML tree of a thorough ML analysis.
- `tree/RAxML_bipartitions.run`: the best-scoring ML tree with the BS support
  values (from 0 to 100, when `--raxml_mode rbs`).


### Taxonomic classification 
This step takes advantage of the MMseqs2 easy-taxonomy workflow to predict the
taxonomy of each input genome. Before classification, for each genome contigs
are concatenated into a single pseudochromosome using the sequence
`NNNNNCATTCCATTCATTAATTAATTAATGAATGAATGNNNNN` as separator, which provides a
stop codon and a start site in all six reading frames[^sagalactiae].

This step requires a MMseqs2 database augmented with taxonomic information (see
[MMseqs2 database](mmseqs2-database)).

#### Options
- `--skip_taxonomy`: skip the taxonomic classification

#### Outputs
- `taxonomy.tsv`: a single TSV file containing the classification summary
- `mmseqs`: directory containing the original MMseqs2 taxonomy files (including
  the Kraken style reports)


### Gene discovery/prediction
Gene prediction is performed using the MetaEuk easy-predict workflow.  

This step requires a MMseqs2 database (see [MMseqs2 database](mmseqs2-database)).

#### Options
- `--skip_genepred`: skip the gene prediction 

#### Outputs
- `metaeuk`: directory containing the original MetaEuk files (including the
  predicted protein sequences and the GFF files)


### The MMseqs2 database
The available databases are listed at
https://github.com/soedinglab/mmseqs2/wiki#downloading-databases (default
"UniProtKB/Swiss-Prot").
  
#### Options
- `--mmseqs_db`: MMseqs2 database path (used by MMseqs2 and MetaEuk) (default
  "none": download from Internet). See the `mmseqs_db_name` parameter.
- `--mmseqs_db_name`: MMseqs2 database name, used when mmseqs_db_path = "none".  
  

### EggNOG
Translated CDS are functionally annotated using EggNOG-mapper against the
eggNOG Orthologous Groups (OGs) database [^eggnog] v5.0. The
eggNOG database integrates functional annotations collected from several
sources, including Gene Ontology (GO) terms, KEGG functional orthologs and COG
categories.

#### Options
- `--skip_eggnog`: skip EggNOG-mapper annotation.
- `--eggnog_db`: eggNOG v5.0 database dir. (default "none": download from
  Internet).
- `--eggnog_db_mem`: store the eggNOG sqlite DB into memory (~44GB memory
  required) increasing the annotation speed.

#### Outputs
- `eggnog_tables`: this folder contains the count matrix for each transferred
  annotation.
- `eggnog`: directory containing the original EggNOG-mapper files.


### ITSx
Extract ITS1, 5.8S and ITS2 regions, as well as full-length ITS sequences.

#### Options
- `--skip_itsx`: skip ITSx.

#### Outputs
- `itsx`: ITSx output for each input genome.


### Resource limits
- `--max_cpus`: maximum number of CPUs for each process (default `8`)
- `--max_memory`: maximum memory for each process (default `240.GB`)
- `--max_time`: maximum time for each process (default `240.h`)

See also [System requirements](https://metashot.github.io/#system-requirements).

## System requirements
Please refer to [System
requirements](https://metashot.github.io/#system-requirements) for the complete
list of system requirements options.


[^busco]: Manni, Mosè, Matthew R. Berkeley, Mathieu Seppey, Felipe A. Simão, and
    Evgeny M. Zdobnov. 2021. "BUSCO Update: Novel and Streamlined Workflows
    along with Broader and Deeper Phylogenetic Coverage for Scoring of
    Eukaryotic, Prokaryotic, and Viral Genomes." Molecular Biology and Evolution
    38 (10): 4647–54.

[^eggnog_mapper]: Cantalapiedra, Carlos P., Ana Hernández-Plaza, Ivica Letunic,
    Peer Bork, and Jaime Huerta-Cepas. 2021. "eggNOG-Mapper v2: Functional
    Annotation,Orthology Assignments, and Domain Prediction at the Metagenomic
    Scale." Molecular Biology and Evolution 38 (12): 5825–29.

[^eggnog]: Huerta-Cepas, Jaime, Damian Szklarczyk, Davide Heller, Ana
    Hernández-Plaza, Sofia K. Forslund, Helen Cook, Daniel R. Mende, et al.
    "eggNOG 5.0: A Hierarchical, Functionally and Phylogenetically Annotated
    Orthology Resource Based on 5090 Organisms and 2502 Viruses." Nucleic Acids
    Research. https://doi.org/10.1093/nar/gky1085.
    
[^muscle5]: Edgar, Robert C. 2022. "High-Accuracy Alignment Ensembles Enable
    Unbiased Assessments of Sequence Homology and Phylogeny." bioRxiv.
    https://doi.org/10.1101/2021.06.20.449169.

[^metaeuk]: Karin, Eli Levy, Milot Mirdita, and Johannes Söding. 2020.
    "MetaEuk—sensitive, High-Throughput Gene Discovery, and Annotation for
    Large-Scale Eukaryotic Metagenomics." Microbiome.
    https://doi.org/10.1186/s40168-020-00808-x.

[^drep]: Olm, Matthew R., Christopher T. Brown, Brandon Brooks, and Jillian F.
    Banfield. 2017. "dRep: A Tool for Fast and Accurate Genomic Comparisons That
    Enables Improved Genome Recovery from Metagenomes through de-Replication."
    The ISME Journal 11 (12): 2864–68.

[^raxml]: Stamatakis, Alexandros. 2014. "RAxML Version 8: A Tool for
    Phylogenetic Analysis and Post-Analysis of Large Phylogenies."
    Bioinformatics 30 (9): 1312–13.
    
[^mmseqs2]: Steinegger, Martin, and Johannes Söding. "MMseqs2 Enables Sensitive
    Protein Sequence Searching for the Analysis of Massive Data Sets." Nature
    Biotechnology 35 (11): 1026–28.

[^gtdb_arc]: Rinke, C., Chuvochina, M., Mussig, A.J. et al. *A standardized
    archaeal taxonomy for the Genome Taxonomy Database*. Nat Microbiol 6,
    946–959 (2021). https://doi.org/10.1038/s41564-021-00918-8

[^raxml_search]: Stamatakis A., Blagojevic F., Nikolopoulos D.S. et al.
    *Exploring New Search Algorithms and Hardware for Phylogenetics: RAxML Meets
    the IBM* Cell. J VLSI Sign Process Syst Sign Im 48, 271–286 (2007).
    [Link](https://doi.org/10.1007/s11265-007-0067-4).

[^raxml_bootstrap]: Stamatakis A., Hoover P., Rougemont J. *A Rapid Bootstrap
    Algorithm for the RAxML Web Servers*. Systematic Biology, Volume 57, Issue
    5, October 2008, Pages 758–771,
    [Link](https://doi.org/10.1080/10635150802429642).

[^sagalactiae]: Tettelin, Hervé, et al. *Genome analysis of multiple pathogenic
    isolates of Streptococcus agalactiae: implications for the microbial
    "pan-genome".* Proceedings of the National Academy of Sciences 102.39
    (2005): 13950-13955. https://www.pnas.org/doi/10.1073/pnas.0506758102

[^itsx]: Bengtsson-Palme, Johan, Martin Ryberg, Martin Hartmann, Sara Branco,
    Zheng Wang, Anna Godhe, Pierre De Wit, et al. 2013. "Improved Software
    Detection and Extraction of ITS1 and ITS2 from Ribosomal ITS Sequences of
    Fungi and Other Eukaryotes for Analysis of Environmental Sequencing Data."
    Methods in Ecology and Evolution. https://doi.org/10.1111/2041-210x.12073.


