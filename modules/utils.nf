nextflow.enable.dsl=2


process pseudochrom {
    tag "${id}"

    input:
    tuple val(id), path(input)
    
    output:
    path "${id}.pc.fa", emit: pc
    
    script:   
    """
    pseudochrom.py ${input} ${id}.pc.fa
    """
}
