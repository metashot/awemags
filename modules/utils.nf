nextflow.enable.dsl=2


process pseudochrom {
    input:
    path(input)
    
    output:
    path "${id}.pc.fa", emit: pc
    
    script:   
    """
    python3 pseudochrom.py ${input} ${id}.pc.fa
    """
}
