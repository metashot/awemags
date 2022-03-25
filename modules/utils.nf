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
