nextflow.enable.dsl=2

process drep_with_genomeinfo {
    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'representatives/*'

    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'drep/{data_tables,figures,log}/*'

    input:
    path 'genome_info_drep.csv'
    path(genomes)

    output:
    path 'representatives/*'
    path 'drep/{data_tables,figures,log}/*'
    path 'drep/data_tables/Cdb.csv', emit: cdb
    path 'drep/data_tables/Wdb.csv', emit: wdb

    script:   
    """
    mkdir genomes_dir
    mv $genomes genomes_dir
    dRep dereplicate \
        drep \
        --genomeInfo genome_info_drep.csv \
        -p ${task.cpus} \
        -nc ${params.min_overlap} \
        -sa ${params.ani_thr} \
        -comp ${params.min_completeness} \
        -con ${params.max_contamination} \
        -strW 0 \
        -g genomes_dir/*

    mv drep/dereplicated_genomes representatives
    """
}

process drep_without_genomeinfo {
    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'representatives/*'

    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'drep/{data_tables,figures,log}/*'

    input:
    path(genomes)

    output:
    path 'representatives/*'
    path 'drep/{data_tables,figures,log}/*'
    path 'drep/data_tables/Cdb.csv', emit: cdb
    path 'drep/data_tables/Wdb.csv', emit: wdb

    script:   
    """
    mkdir genomes_dir
    mv $genomes genomes_dir
    dRep dereplicate \
        drep \
        --ignoreGenomeQuality \
        -ms 5000 \
        -p ${task.cpus} \
        -nc ${params.min_overlap} \
        -sa ${params.ani_thr} \
        -sizeW 1 \
        -strW 0 \
        -N50W 0 \
        -g genomes_dir/*

    mv drep/dereplicated_genomes representatives
    """
}

