nextflow.enable.dsl=2

process busco {
    tag "${id}"

    publishDir "${params.outdir}/busco" , mode: 'copy'

    input:
    tuple val(id), path(genome)
    path (lineage)
    path busco_db, stageAs: 'busco_downloads'

    output:
    path "${id}/*"
    path "${id}/logs"
    path "${id}/exit_info.txt", optional: true
    path "${id}/short_summary.*", optional: true
    path "${id}/short_summary.specific.*.${id}.txt", optional: true, emit: summary
    

    script:
    if( params.lineage == 'auto' ) {
        param_auto_lineage = '--auto-lineage'
        param_lineage_dataset = ''
    }
    else if ( params.lineage == 'auto-prok' ) {
        param_auto_lineage = '--auto-lineage-prok'
        param_lineage_dataset = ''
    }
    else if ( params.lineage == 'auto-euk' ) {
        param_auto_lineage = '--auto-lineage-euk'
        param_lineage_dataset = ''
    }
    else {
        param_auto_lineage = ''
        param_lineage_dataset = "-l ${params.lineage}"
    }

    if( params.busco_db == 'none' ) {
        param_offline = ''
    }
    else {
        param_offline = '--offline'
    }

    """
    # Avoid the "FileExistsError" in inline mode
    if [ "${param_offline}" = "" ]; then
        rm busco_downloads
    fi

    set +e
    busco \
        -i ${genome} \
        -o ${id} \
        -m genome \
        ${param_lineage_dataset} \
        ${param_auto_lineage} \
        ${param_offline} \
        --cpu ${task.cpus}
    BUSCO_EXIT=\$?
      
    BUSCO_LOG=${id}/logs/busco.log
    if [ "\$BUSCO_EXIT" -eq 1 ] && [ -f \$BUSCO_LOG ]; then
        
        EXIT_MSG='SystemExit: Augustus did not recognize any genes'
        grep -q "\$EXIT_MSG" \$BUSCO_LOG
        if [ "\$?" -eq 0 ]; then
            echo "Augustus did not recognize any genes." >> ${id}/exit_info.txt
            exit 0
        fi

        EXIT_MSG='SystemExit: Placements failed'
        grep -q "\$EXIT_MSG" \$BUSCO_LOG
        if [ "\$?" -eq 0 ]; then
            echo "Placements failed." >> ${id}/exit_info.txt
            exit 0
        fi

    fi

    exit \$BUSCO_EXIT
    """
}
