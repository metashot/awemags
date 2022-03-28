nextflow.enable.dsl=2


process statswrapper {      

        publishDir "${params.outdir}/statswrapper" , mode: 'copy'

        input:
        path(genomes)

        output:
        path 'stats.tsv', emit: stats

        script:       
        """
        mkdir genomes_dir
        mv ${genomes} genomes_dir
        statswrapper.sh genomes_dir/* > stats.tsv
        """
}
