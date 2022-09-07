nextflow.enable.dsl=2


process amas {      
    publishDir "${params.outdir}/tree/" , mode: 'copy'

    input:
    path(seqs)

    output:
    path 'concat.msa.faa', emit: concat_msa
    path 'partitions.txt'

    script:       
    """
    python3 /usr/local/lib/python3.9/dist-packages/amas/AMAS.py concat \
        -i ${seqs} \
        -f fasta \
        -d aa \
        -t concat.msa.faa
    """
}
