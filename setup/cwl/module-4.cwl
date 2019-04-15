#!/usr/bin/env cwl-runner

$namespaces:
  dct: http://purl.org/dc/terms/
  foaf: http://xmlns.com/foaf/0.1/
  doap: http://usefulinc.com/ns/doap#

$schemas:
- http://dublincore.org/2012/06/14/dcterms.rdf
- http://xmlns.com/foaf/spec/20140114.rdf
- http://usefulinc.com/ns/doap#

doap:release:
- class: doap:Version
  doap:name: module-4
  doap:revision: 1.0.0
- class: doap:Version
  doap:name: cwl-wrapper
  doap:revision: 1.0.0

dct:creator:
- class: foaf:Organization
  foaf:name: Memorial Sloan Kettering Cancer Center
  foaf:member:
  - class: foaf:Person
    foaf:name: Jaeyoung Chun
    foaf:mbox: mailto:chunj@mskcc.org

dct:contributor:
- class: foaf:Organization
  foaf:name: Memorial Sloan Kettering Cancer Center
  foaf:member:
  - class: foaf:Person
    foaf:name: Jaeyoung Chun
    foaf:mbox: mailto:chunj@mskcc.org
  - class: foaf:Person
    foaf:name: Nikhil Kumar
    foaf:mbox: mailto:kumarn1@mskcc.org

cwlVersion: v1.0

class: Workflow
label: module-4
requirements:
    MultipleInputFeatureRequirement: {}
    ScatterFeatureRequirement: {}
    SubworkflowFeatureRequirement: {}
    InlineJavascriptRequirement: {}
    StepInputExpressionRequirement: {}

inputs:
    db_files:
        type:
            type: record
            fields:
                pairing_file: File
    runparams:
        type:
            type: record
            fields:
                tmp_dir: string
    bams:
        type:
            type: array
            items: File
        secondaryFiles:
            - ^.bai
    annotate_vcf:
        type: File
    tumor_sample_name: string
    normal_sample_name: string
    genome: string
    ref_fasta: string

    exac_filter:
        type: File
        secondaryFiles:
            - .tbi
    vep_data: string
    curated_bams:
        type:
            type: array
            items: string
    hotspot_list:
        type: File

outputs:

    maf:
        type: File
        outputSource: ngs_filters/output

steps:

    vcf2maf:
        run: cmo-vcf2maf/1.6.17/cmo-vcf2maf.cwl
        in:
            runparams: runparams
            tmp_dir:
                valueFrom: ${ return inputs.runparams.tmp_dir; }
            input_vcf: annotate_vcf
            tumor_id: tumor_sample_name
            vcf_tumor_id: tumor_sample_name
            normal_id: normal_sample_name
            vcf_normal_id: normal_sample_name
            ncbi_build: genome
            filter_vcf: exac_filter
            vep_data: vep_data
            ref_fasta: ref_fasta
            retain_info:
                default: "set,TYPE,FAILURE_REASON,MSI,MSILEN,SSF,LSEQ,RSEQ,STATUS,VSB"
            retain_fmt:
                default: "QUAL,BIAS,HIAF,PMEAN,PSTD,ALD,RD,NM,MQ,IS"
            output_maf:
                valueFrom: ${ return inputs.tumor_id + "." + inputs.normal_id + ".combined-variants.vep.maf" }
        out: [output]

    remove_variants:
        run: remove-variants/0.1.1/remove-variants.cwl
        in:
            inputMaf: vcf2maf/output
            outputMaf:
                valueFrom: ${ return inputs.inputMaf.basename.replace(".vep.maf", ".vep.rmv.maf") }
        out: [maf]

    fillout_tumor_normal:
        run: cmo-fillout/1.2.2/cmo-fillout.cwl
        in:
            db_files: db_files
            pairing:
                valueFrom: ${ return inputs.db_files.pairing_file; }
            maf: remove_variants/maf
            bams: bams
            genome: genome
            output_format:
                default: "1"
        out: [fillout_out, portal_fillout]

    fillout_normal_panel:
        in:
            maf: remove_variants/maf
            genome: genome
            curated_bams: curated_bams
        out: [fillout_curated_bams]
        run:
            class: Workflow
            inputs:
                maf: File
                genome: string
                curated_bams:
                    type:
                        type: array
                        items: string
            outputs:
                fillout_curated_bams:
                    type: File
                    outputSource: fillout_curated_bams_step/fillout_out
            steps:
                fillout_curated_bams_step:
                    run: cmo-fillout/1.2.2/cmo-fillout.cwl
                    in:
                        maf: maf
                        bams: curated_bams
                        genome: genome
                        output_format:
                            default: "1"
                        output:
                            valueFrom: ${ return inputs.maf.basename.replace(".maf", ".curated.fillout"); }
                        n_threads:
                            default: 10
                    out: [fillout_out]

    ngs_filters:
        run: ngs-filters/1.4/ngs-filters.cwl
        in:
            tumor_sample_name: tumor_sample_name
            normal_sample_name: normal_sample_name
            inputMaf: fillout_tumor_normal/portal_fillout
            outputMaf:
                valueFrom: ${ return inputs.tumor_sample_name + "." + inputs.normal_sample_name + ".muts.maf" }
            NormalPanelMaf: fillout_normal_panel/fillout_curated_bams
            inputHSP: hotspot_list
        out: [output]
