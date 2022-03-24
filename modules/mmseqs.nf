nextflow.enable.dsl=2


process mmseqs_db_download {
    publishDir "${params.outdir}/dbs" , mode: 'copy'

    input:


    output:
    path 'mmseqs_db/db', emit: mmseqs_db
    path 'mmseqs_db', type: 'dir', emit: mmseqs_db_dir

    script:
    """
    mkdir mmseqs_db
    mmseqs databases ${params.mmseqs_db} mmseqs_db/db tmp
    rm -rf tmp
    """
}


process mmseqs_easy_taxonomy {
    tag "${id}"
    
    publishDir "${params.outdir}/mmseqs2/${id}" , mode: 'copy'

    input:
    path(input)
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
