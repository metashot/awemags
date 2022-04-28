nextflow.enable.dsl=2


process itsx {      
        tag "${id}"

        publishDir "${params.outdir}/itsx/${id}" , mode: 'copy'

        input:
        tuple val(id), path(genome)

        output:
        path "${id}.itsx*"

        script:       
        """
        ITSx \
            -i ${genome} \
            -o ${id}.itsx \
            --cpu ${task.cpus} \
            --save_regions all \
        """
}
