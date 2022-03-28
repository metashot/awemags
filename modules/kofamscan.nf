nextflow.enable.dsl=2

process kofamscan {
    tag "${id}"

    publishDir "${params.outdir}/kofamscan/${id}" , mode: 'copy'

    input:
    tuple val(id), path(seqs)
    path(kofamscan_db)

    output:
    path "${id}.hits.txt", emit: hits

    script:
    """
    exec_annotation \
        -f detail \
        --cpu ${task.cpus} \
        --tmp-dir tmp \
        -o ${id}.hits.txt \
        -p ${kofamscan_db}/profiles/prokaryote.hal \
        -k ${kofamscan_db}/ko_list \
        ${seqs}

    rm -rf tmp
    """
}

