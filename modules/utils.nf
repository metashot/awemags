nextflow.enable.dsl=2


process format_quality {      
    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'quality.tsv'

    input:
    path(summaries)
    path(stats)
   
    output:
    path 'quality.tsv', emit: quality 
    path 'genome_info_drep.csv', emit: genome_info_drep 

    script:
    """
    mkdir summaries_dir
    mv $summaries summaries_dir
    format_quality.py \
        summaries_dir \
        $stats \
        quality.tsv \
        genome_info_drep.csv
    """
}

process genome_filter {
    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path 'quality.tsv'
    path(genomes)

    output:
    path 'filtered/*', optional: true, emit: filtered
    
    script:   
    """
    mkdir genomes_dir
    mv $genomes genomes_dir
    genome_filter.py \
        quality.tsv \
        genomes_dir \
        filtered \
        ${params.min_completeness} \
        ${params.max_contamination}
    """
}

process pseudo_chr {
    tag "${id}"

    input:
    tuple val(id), path(input)
    
    output:
    tuple val(id), path ("${id}.pseudochr.fa"), emit: pseudochr
    
    script:   
    """
    pseudo_chr.py ${input} ${id}.pseudochr.fa
    """
}

process format_mmseqs_lca {
    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path(mmseqs_lca)
    
    output:
    path('taxonomy.tsv')
    
    script:   
    """
    format_mmseqs_lca.py \
        ${mmseqs_lca} \
        taxonomy.tsv
    """
}

process merge_eggnog_mapper {      
    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path(annotations)
   
    output:
    path 'eggnog_*.tsv'

    script:
    """
    merge_eggnog_mapper.py -i ${annotations}
    """
}

process derep_info {
    publishDir "${params.outdir}" , mode: 'copy'
    
    input:
    path 'Cdb.csv'
    path 'Wdb.csv'
    
    output:
    path 'derep_info.tsv'
    
    script:   
    """
    derep_info.py Cdb.csv Wdb.csv derep_info.tsv 
    """
}

process select_columns {

    publishDir "${params.outdir}/tree/trim_msa" , mode: 'copy'

    input:
    tuple val(id), path(seqs)
    val(n_busco_genes)

    output:
    tuple val(id), path("${id}.trim.msa.faa"), emit: trim_msa

    script:
    max_ncols_gene = Math.floor(params.max_ncols / n_busco_genes) as int
    """
    select_columns.py ${seqs} ${id}.trim.msa.faa 0.7 0.25 0.95 ${max_ncols_gene} ${params.seed_cols}
    """
}
