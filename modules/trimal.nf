nextflow.enable.dsl=2


process trimal {      
    tag "BUSCO SCG ${id}"

    publishDir "${params.outdir}/tree/trim_msa" , mode: 'copy'

    input:
    tuple val(id), path(seqs)

    output:
    tuple val(id), path("${id}.trim.msa.faa"), emit: trim_msa

    script:       
    """
    trimal -in ${seqs} -out ${id}.trim.msa.faa -automated1  
    sed -i 's/ [[:digit:]]\\+ bp\$//g' ${id}.trim.msa.faa
    """
}
