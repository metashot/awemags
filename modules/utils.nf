nextflow.enable.dsl=2


process pseudochr {
    tag "${id}"

    input:
    tuple val(id), path(input)
    
    output:
    tuple val(id), path ("${id}.pseudochr.fa"), emit: pseudochr
    
    script:   
    """
    pseudochr.py ${input} ${id}.pseudochr.fa
    """
}

process kofamscan_db_download {

    publishDir "${params.outdir}/dbs" , mode: 'copy'

    output:
    path 'kofamscan_db', type: 'dir', emit: kofamscan_db

    script:
    """
    mkdir kofamscan_db

    curl -s -L ftp://ftp.genome.jp/pub/db/kofam/profiles.tar.gz | \
        tar -zxf - -C kofamscan_db

    curl -s -L ftp://ftp.genome.jp/pub/db/kofam/ko_list.gz -o ko_list.gz && \
        gunzip -c ko_list.gz > kofamscan_db/ko_list
    """
}

process merge_eggnog_mapper {      
    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path(annotations)
   
    output:
    path 'eggnog_*.tsv'

    script:
    """
    merge_eggnog_mapper.py -i ${annotations}
    """
}

process merge_kofamscan {      
    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path(hits)
   
    output:
    path 'kofamscan_hits.tsv'

    script:
    """
    merge_kofamscan_hits.py -i ${hits}
    """
}