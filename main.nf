#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { mmseqs_db_download; mmseqs_easy_taxonomy } from './modules/mmseqs'
include { metaeuk_easy_predict } from './modules/metaeuk'
include { eggnog_db_download; eggnog_mapper } from './modules/eggnog_mapper'
include { pseudochr; merge_eggnog_mapper } from './modules/utils'

workflow {
    
    Channel
        .fromPath( params.genomes )
        .map { file -> tuple(file.baseName, file) }
        .set { genomes_ch }


    // MMseqs2 database
    if (!(params.skip_taxonomy && params.skip_genepred)) {
        if (params.mmseqs_db == 'none') {
            mmseqs_db_download()
            mmseqs_db_dir = mmseqs_db_download.out.mmseqs_db
            mmseqs_db_name = "db"
        }
        else {
            mmseqs_db = file(params.mmseqs_db, checkIfExists: true)
            mmseqs_db_dir = mmseqs_db.parent
            mmseqs_db_name = mmseqs_db.name
        }
    }

    // MMseq2 taxonomy
    if ( !params.skip_taxonomy ) {
        pseudochr(genomes_ch)
        pseudochr_ch = pseudochr.out.pseudochr
        mmseqs_easy_taxonomy(pseudochr_ch, mmseqs_db_dir, mmseqs_db_name)
        mmseqs_lca_ch = mmseqs_easy_taxonomy.out.lca
            .collectFile(
                name:'mmseqs_lca.txt', 
                storeDir: "${params.outdir}/mmseqs",
                newLine: false)
    }

    // MetaEuk
    if ( (!params.skip_genepred) || (!params.skip_eggnog)) {
        metaeuk_easy_predict(genomes_ch, mmseqs_db_dir, mmseqs_db_name)
        prot_ch = metaeuk_easy_predict.out.prot
    }

    // eggNOG
    if ( !params.skip_eggnog ) {
        if (params.eggnog_db == 'none') {
            eggnog_db_download()
            eggnog_db = eggnog_db_download.out.eggnog_db
        }
        else {
            eggnog_db = file(params.eggnog_db, type: 'dir', 
                checkIfExists: true)
        }

        eggnog_mapper(prot_ch, eggnog_db)
        merge_eggnog_mapper(eggnog_mapper.out.annotations.collect())
    }
}
