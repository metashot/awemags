nextflow.enable.dsl=2


process mmseqs_easy_taxonomy {
    tag "${id}"
    
    publishDir "${params.outdir}/mmseqs2/${id}" , mode: 'copy'

    input:
    tuple val(id), path(input)
    path(mmseqs_db)

    output:
    path "${id}_lca.tsv", emit: lca
    path "${id}_*"
       
    script:
    """
    mkdir ${id}
    mmseqs easy-taxonomy \
        --tax-lineage 1 \
        --lca-ranks superkingdom,kingdom,phylum,class,order,family,genus,species \
        --threads ${task.cpus}
        ${input} \
        ${mmseqs_db} \
        ${id} \
        tmp
    
    rm -rf tmp
    """
}
