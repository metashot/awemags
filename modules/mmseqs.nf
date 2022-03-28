nextflow.enable.dsl=2


process mmseqs_db_download {

    publishDir "${params.outdir}/dbs" , mode: 'copy'

    output:
    path 'mmseqs_db', type: 'dir', emit: mmseqs_db

    script:
    """
    mkdir mmseqs_db
    mmseqs databases ${params.mmseq_db_name} mmseqs_db/db tmp
    rm -rf tmp
    """
}

process mmseqs_easy_taxonomy {
    tag "${id}"
    
    publishDir "${params.outdir}/mmseqs/${id}" , mode: 'copy'

    input:
    tuple val(id), path(input)
    path(mmseqs_db_dir)
    val(mmseq_db_name)
    

    output:
    path "${id}_lca.tsv", emit: lca
    path "${id}_*"
       
    script:
    db_name = mmseqs_db_dir / mmseq_db_name
    task_memory_GB = Math.floor(0.7 * task.memory.toGiga()) as int
    """
    mmseqs easy-taxonomy \
        --tax-lineage 1 \
        --lca-ranks superkingdom,kingdom,phylum,class,order,family,genus,species \
        --threads ${task.cpus} \
        --split-memory-limit ${task_memory_GB}G \
        ${input} \
        ${db_name} \
        ${id} \
        tmp
    
    rm -rf tmp
    """
}
