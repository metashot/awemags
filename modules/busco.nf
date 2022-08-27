nextflow.enable.dsl=2

process busco {
    tag "${id}"

    publishDir "${params.outdir}/busco" , mode: 'copy'

    input:
    tuple val(id), path(genome)
    path (lineage)
    path busco_db, stageAs: 'busco_downloads'

    output:
    path "${id}/logs"
    path "${id}/exit_info.txt", optional: true
    path "${id}/${id}_full_table.tsv", optional: true
    path "${id}/${id}_missing_busco_list.tsv", optional: true
    path "${id}/${id}_busco_sequences/multi_copy_busco_sequences", optional: true
    path "${id}/${id}_busco_sequences/fragmented_busco_sequences", optional: true
    path "${id}/${id}_busco_sequences/single_copy_busco_sequences/*.fna", optional: true
    path "${id}/${id}_short_summary.txt", optional: true, emit: summary
    tuple val(id), path("${id}/${id}_busco_sequences/single_copy_busco_sequences/*.faa"), optional: true, emit: scg

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
    
    cp -r /config/augustus/ config_augustus
    set +e
    AUGUSTUS_CONFIG_PATH=config_augustus busco \
        -i ${genome} \
        -o busco_out \
        -m genome \
        ${param_lineage_dataset} \
        ${param_auto_lineage} \
        ${param_offline} \
        --cpu ${task.cpus}
    BUSCO_EXIT=\$?
    rm -rf config_augustus

    mkdir ${id}
    cp -R busco_out/logs ${id}

    ##### Check the errors

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

    ##### Get the final lineage

    SUMMARY_SPECIFIC=(busco_out/short_summary.specific.*.txt)
    if [ \${#SUMMARY_SPECIFIC[@]} -ne 1 ]; then
        echo "Zero or multiple 'short_summary.specific.*.txt' files found." >> ${id}/exit_info.txt
        exit 0
    fi

    REGEX="short_summary.specific.([^.]+).*.txt"
    if [[ \$SUMMARY_SPECIFIC =~ \$REGEX ]]; then
        LINEAGE="\${BASH_REMATCH[1]}"
    else
        echo "Invalid 'short_summary.specific.*.txt' file found." >> ${id}/exit_info.txt
        exit 0
    fi

    ##### Prepare output
    
    LINEAGE_DIR="busco_out/run_\$LINEAGE"
    
    if [ ! -d \$LINEAGE_DIR ]; then
        echo "'\$LINEAGE_DIR' directory not found." >> ${id}/exit_info.txt
        exit 0
    fi
        
    cp -R \${LINEAGE_DIR}/busco_sequences ${id}/${id}_busco_sequences
    cp \${LINEAGE_DIR}/missing_busco_list.tsv ${id}/${id}_missing_busco_list.tsv
    cp \${LINEAGE_DIR}/full_table.tsv ${id}/${id}_full_table.tsv
    cp \${LINEAGE_DIR}/short_summary.txt ${id}/${id}_short_summary.txt

    ##### Remove unnecessary directories

    rm -rf busco_out busco_downloads
    
    ##### Exit

    exit \$BUSCO_EXIT
    """
}
