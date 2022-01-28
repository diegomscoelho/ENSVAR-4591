#!/usr/bin/env nextflow
// Benchmark VEP --everything arguments
nextflow.enable.dsl=2

params.repeat    = 10 // times to repeat each run
params.vep       = "/hps/software/users/ensembl/repositories/diegomscoelho/ensembl-vep/vep"
params.cache     = "/nfs/production/flicek/ensembl/variation/data/VEP/tabixconverted"
params.fasta     = "/nfs/production/flicek/ensembl/variation/data/Homo_sapiens.GRCh38.dna.toplevel.fa.gz"
params.vcf       = "/nfs/production/flicek/ensembl/variation/data/PlatinumGenomes/NA12878.vcf.gz"

// to pass flags in CLI besides the ones used as baselin, use double quotes
// and add a space somewhere inside the string
//   e.g. nextflow run main.nf --flags "--regulatory "
params.flags     = null 

// params.flagsFile is ignored if params.flags is set
params.flagsFile = "input/vep_flags.txt"

process vep {
    tag "$args $iter"
    publishDir 'logs'

    time '6h'
    memory '3 GB'

    input:
        path vep
        path vcf
        path fasta
        path cache
        val args
        each iter
    output:
        path '*.out' optional true
    """
    name=vep-arg-\$( echo ${args} | sed 's/-//g' | sed 's/ /-/g' )
    log=\${name}-\${LSB_JOBID}-${iter}.out
    perl ${vep} \
         --i $vcf \
         --o \${name}-\${LSB_JOBID}.txt \
         --offline \
         --cache \
         --dir_cache ${cache} \
         --assembly GRCh38 \
         --fasta ${fasta} \
         ${args} > \${log} 2>&1

    # remove log file if empty
    [ -s \${log} ] || rm \${log}
    """
}

def joinFlags (f) {
    f.reduce{ a, b -> return "$a $b" }
}

def discardFlags (allFlags, discarded) {
    joinFlags(allFlags.filter{ !(it in discarded) })
}

workflow {
    if ( params.flags ) {
        flagTests = Channel.of( params.flags )
    } else {
        // get a list of flags set with --everything in VEP
        flags = Channel.fromPath( params.flagsFile )
                       .splitText()
                       .map{it -> it.trim()}

        // all flags explicitly stated (same runtime as --everything)
        allFlags = joinFlags(flags)

        // discard specific flags
        noClinVar    = discardFlags(flags, ["--custom /nfs/production/flicek/ensembl/variation/data/ClinVar/clinvar_20210102.vcf.gz,clinvar_20210102,vcf,exact,0,CLNSIG"])
        noTOPMED    = discardFlags(flags, ["--custom /nfs/production/flicek/ensembl/variation/data/TopMed/TOPMED_GRCh38_20180418.vcf.gz,topmed_20180418,vcf,exact,0,TOPMED"])
        noUK10K    = discardFlags(flags, ["--custom /nfs/production/flicek/ensembl/variation/data/UK10K/UK10K_COHORT.20160215.sites.GRCh38.vcf.gz,uk10k_20160215,vcf,exact,0,AF_TWINSUK,AF_ALSPAC"])

        // VEP with no extra flags (baseline)
        otherFlags = Channel.from( "" )

        flagTests = allFlags.concat( otherFlags, noClinVar, noTOPMED, noUK10K, flags )
        flagTests.view()
    }
    loop = Channel.from(1..params.repeat)
    vep( params.vep, params.vcf, params.fasta, params.cache, flagTests, loop )
}

// Print summary
workflow.onComplete {
    println ( workflow.success ? """
        Workflow summary
        ----------------
        Completed at: ${workflow.complete}
        Duration    : ${workflow.duration}
        Success     : ${workflow.success}
        workDir     : ${workflow.workDir}
        exit status : ${workflow.exitStatus}
        """ : """
        Failed: ${workflow.errorReport}
        exit status : ${workflow.exitStatus}
        """
    )
}
