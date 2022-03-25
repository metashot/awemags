nextflow.enable.dsl=2


process mmseqs_easy_taxonomy {
    tag "${id}"
    
    publishDir "${params.outdir}/mmseqs/${id}" , mode: 'copy'

    input:
    tuple val(id), path(input)
    path(mmseqs_db)
    path(mmseqs_db_dir)

    output:
    path "${id}_lca.tsv", emit: lca
    path "${id}_*"
       
    script:
    task_memory_GB = Math.floor(0.7 * task.memory.toGiga()) as int
    """
    mmseqs easy-taxonomy \
        --tax-lineage 1 \
        --lca-ranks superkingdom,kingdom,phylum,class,order,family,genus,species \
        --threads ${task.cpus} \
        --split-memory-limit ${task_memory_GB}G \
        ${input} \
        ${mmseqs_db} \
        ${id} \
        tmp
    
    rm -rf tmp
    """
}
