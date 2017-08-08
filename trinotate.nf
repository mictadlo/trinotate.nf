#!/usr/bin/env nextflow

log.info "T R I N O T A T E - N F  ~  version 0.1"
log.info "====================================="
log.info "genome                 : ${params.genome}"
log.info "swiss-prot             : ${params.swissProt}"
log.info "pfam-A                 : ${params.pfamA}"
log.info "trinotate-SQlite       : ${params.trinotateSqlite}"
log.info "output                 : ${params.output}"
log.info "      \n"

/*
 * Input parameters validation
 */

genome                        = file(params.genome)
chunks                        = params.chunks

params.chunk = 1
Channel.fromPath(params.swissProt)
       .set{swissProt}
       //.into{swissProt1; swissProt2; swissProt3; swissProt4}


process formatBlastDatabases {
    input:
    file 'uniprot_sprot.pep' from swissProt

    output:
    file 'blastdb' into blastDB
    set val ("uniprot_sprot"), file("blastdb") into blastDB

    script:
    """
    makeblastdb -dbtype prot -in uniprot_sprot.pep
    mkdir blastdb
    mv uniprot_sprot* blastdb/
    """
}



// Step 1: extract the long open reading frames
process transdecoder_LongOrfs {
    cache 'deep'

    input:
    file "target_transcripts.fasta" from genome

    output:

    file "target_transcripts.fasta.transdecoder_dir" into transdecoderLongOrfs
        

    """
    TransDecoder.LongOrfs -t target_transcripts.fasta
    """
}


process blast {
    cache 'deep'

    input:
    set transdecoderDir from transdecoderLongOrfs
    set val(blastfn), file(blastdbDir) from blastdb.first()
    
   output:
    file blastp.outfmt6

    
    """
    blastp -query ${transdecoderDir}/longest_orfs.pep -db ${blastdbDir/${blastfn}.pep -max_target_seqs 1 -outfmt 6 -evalue 1e-5 > blastp.outfmt6
    """
}


