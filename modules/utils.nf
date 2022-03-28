nextflow.enable.dsl=2


process pseudochr {
    tag "${id}"

    input:
    tuple val(id), path(input)
    
    output:
    tuple val(id), path ("${id}.pseudochr.fa"), emit: pseudochr
    
    script:   
    """
    pseudochr.py ${input} ${id}.pseudochr.fa
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

process merge_kofamscan {      
    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path(hits)
   
    output:
    path 'kofamscan_hits.tsv'

    script:
    """
    merge_kofamscan_hits.py -i ${hits}
    """
}