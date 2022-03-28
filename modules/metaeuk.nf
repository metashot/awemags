nextflow.enable.dsl=2


process metaeuk_easy_predict {
    tag "${id}"
    
    publishDir "${params.outdir}/metaeuk/${id}" , mode: 'copy'

    input:
    tuple val(id), path(input)
    path(mmseqs_db_dir)
    val(mmseq_db_name)

    output:
    tuple val(id), path ("${id}.fas"), emit: prot
    path "${id}*"
       
    script:
    db_name = mmseqs_db_dir / mmseq_db_name
    task_memory_GB = Math.floor(0.7 * task.memory.toGiga()) as int
    """
    metaeuk easy-predict \
        --threads ${task.cpus} \
        --split-memory-limit ${task_memory_GB}G \
        ${input} \
        ${db_name} \
        ${id} \
        tmp
    
    rm -rf tmp
    """
}
