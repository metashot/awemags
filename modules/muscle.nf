nextflow.enable.dsl=2


process muscle {      
        tag "BUSCO SCG ${id}"

        publishDir "${params.outdir}/tree/msa" , mode: 'copy'

        input:
        tuple val(id), path(seqs)

        output:
        tuple val(id), path ("${id}.msa.faa"), emit: msa

        script:       
        """
        muscle \
            -align ${seqs} \
            -output ${id}.msa.faa \
            -threads ${task.cpus}
        """
}
