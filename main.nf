#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { busco } from './modules/busco'
include { statswrapper } from './modules/bbtools'
include { drep_with_genomeinfo; drep_without_genomeinfo } from './modules/drep'
include { itsx } from './modules/itsx'
include { mmseqs_db_download; mmseqs_easy_taxonomy } from './modules/mmseqs'
include { metaeuk_easy_predict } from './modules/metaeuk'
include { eggnog_db_download; eggnog_mapper } from './modules/eggnog_mapper'
include { format_quality; genome_filter; pseudo_chr; format_mmseqs_lca; merge_eggnog_mapper; derep_info; select_columns} from './modules/utils'
include { muscle } from './modules/muscle'
//include { trimal } from './modules/trimal'
include { amas } from './modules/amas'
include { raxml } from './modules/gubbins'

workflow {
    
    Channel
        .fromPath( params.genomes )
        .map { file -> tuple(file.baseName, file) }
        .set { genomes_ch }

    /* Filtering */
    if ( !params.skip_filtering ) {
        lineage = file(params.lineage, type: 'file')
        busco_db = file(params.busco_db, type: 'dir')
        busco(genomes_ch, lineage, busco_db)
        statswrapper(genomes_ch.map { row -> row[1] }.collect())
        format_quality(busco.out.summary.collect(), statswrapper.out.stats)
        genome_filter(format_quality.out.quality,
            genomes_ch.map { row -> row[1] }.collect())

        filtered_ch = genome_filter.out.filtered
            .flatMap()
            .map { file -> tuple(file.baseName, file) }
        
        /* BUSCO SCG MSA and phylogenetic tree inference */
        if ( (!params.skip_tree) & (!['auto', 'auto-prok', 'auto-euk'].contains(params.lineage)) ) {
            busco_genes_ch = filtered_ch
                .join(busco.out.scg, by: 0)
                .map { row -> [ row[0], row[2] ] }
                .transpose()
                .map { row -> [ row[1].baseName, row[0], row[1]] }
                .splitFasta( record: [id: true, seqString: true ], limit: 1)
                .map {
                    row -> 
                    def record = [:]
                        record.id        = row[1]
                        record.seqString = row[2].seqString
                    [ row[0], record ]
                }
                .collectFile(storeDir: "${params.outdir}/tree/faa") { 
                    gene, record ->
                    [ "${gene}.faa", ">" + record.id + '\n' + record.seqString + '\n' ]
                }
                .map { file -> tuple(file.baseName, file) }
                .filter { gene, file -> file.countFasta() > 1 }

            muscle(busco_genes_ch)
            nbusco_genes = busco_genes_ch.count()
            max_ncols_gene = params.max_ncols.intdiv(nbusco_genes)
            
            select_columns(muscle.out.msa, max_ncols_gene)
            
            // selected_genes_ch = trimal.out.trim_msa
            //     .map { row -> row[1] }
            //     .toSortedList()
            //     .flatten()
            //     .randomSample( params.concat_genes_nmax, params.concat_genes_seed )
            //     .collect()

            amas(select_columns.out.trim_msa.map { row -> row[1] }.collect())
            concat_msa_ch = amas.out.concat_msa
                .map { file -> tuple( file, file.countLines() ) }
            raxml(concat_msa_ch)
        }

        if ( !params.skip_dereplication ) {
            drep_with_genomeinfo(format_quality.out.genome_info_drep,
                filtered_ch.map { row -> row[1] }.collect())
            derep_info(drep_with_genomeinfo.out.cdb,
                drep_with_genomeinfo.out.wdb)
        }
    } else {
        filtered_ch = genomes_ch

        if ( !params.skip_dereplication ) {
            drep_without_genomeinfo(filtered_ch.map { row -> row[1] }.collect())
            derep_info(drep_without_genomeinfo.out.cdb,
                drep_without_genomeinfo.out.wdb)
        }
    }

    // MMseqs2 database
    if ( !(params.skip_taxonomy && params.skip_genepred) ) {
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
        pseudo_chr(filtered_ch)
        pseudo_chr_ch = pseudochr.out.pseudochr
        mmseqs_easy_taxonomy(pseudo_chr_ch, mmseqs_db_dir, mmseqs_db_name)
        mmseqs_lca_ch = mmseqs_easy_taxonomy.out.lca
            .collectFile(
                name:'mmseqs_lca.txt', 
                storeDir: "${params.outdir}/mmseqs",
                newLine: false)
        format_mmseqs_lca(mmseqs_lca_ch)
    }

    // MetaEuk
    if ( (!params.skip_genepred) || (!params.skip_eggnog)) {
        metaeuk_easy_predict(filtered_ch, mmseqs_db_dir, mmseqs_db_name)
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

    // ITSx
    if ( !params.skip_itsx ) {
        itsx(filtered_ch)
    }
}
