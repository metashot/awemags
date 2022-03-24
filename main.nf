#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { mmseqs_easy_taxonomy } from './modules/mmseqs'
include { pseudochrom } from './modules/utils'

workflow {
    
    Channel
        .fromPath( params.genomes )
        .map { file -> tuple(file.baseName, file) }
        .set { genomes_ch }

    mmseqs_db = file(params.mmseqs_db, checkIfExists: true)
    
    if (!params.contigs) {
        pseudochrom(genomes_ch)
        input_ch = pseudochrom.out.pc
    }
    else {
        input_ch = genomes_ch
    }

    mmseqs_easy_taxonomy(input_ch, mmseqs_db)
}
