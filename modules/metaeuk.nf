nextflow.enable.dsl=2


process metaeuk_easy_predict {
    tag "${id}"
    
    publishDir "${params.outdir}/metaeuk/${id}" , mode: 'copy'

    input:
    tuple val(id), path(input)
    path(mmseqs_db)

    output:
    path "${id}.fas", emit: prot
    path "${id}*"
       
    script:
    task_memory_GB = Math.floor(0.7 * task.memory.toGiga()) as int
    """
    metaeuk easy-predict \
        --threads ${task.cpus} \
        --split-memory-limit ${task_memory_GB}G \
        ${input} \
        ${mmseqs_db} \
        ${id} \
        tmp
    
    rm -rf tmp
    """
}
