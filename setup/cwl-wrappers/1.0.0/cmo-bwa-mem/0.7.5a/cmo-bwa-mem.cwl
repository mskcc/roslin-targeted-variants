#!/usr/bin/env cwl-runner
# metadata:
#   - version.tool=0.7.5a
#   - timestamp.created=2017-03-15 19:04:50
#   - key1=value1
#   - key2=value2

# This tool description was generated automatically by argparse2cwl ver. 0.3.1
# To generate again: $ cmo_bwa_mem -o FILENAME --generate_cwl_tool
# Help: $ cmo_bwa_mem  --help_arg2cwl

cwlVersion: cwl:v1.0

class: CommandLineTool
baseCommand: [cmo_bwa_mem]

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 30
    coresMin: 5

doc: |
  run bwa mem

inputs:
  genome:
    type:
      type: enum
      symbols: [GRCm38, ncbi36, mm9, GRCh37, GRCh38, hg18, hg19, mm10]
    inputBinding:
      prefix: --genome

  fastq1:
    type: 


      - string
      - File
    inputBinding:
      prefix: --fastq1

  fastq2:
    type:
    - string
    - File
    inputBinding:
      prefix: --fastq2

  output:
    type: string


    inputBinding:
      prefix: --output

  sam:
    type: ['null', boolean]
    default: false
    doc: Produce Sam instead of the default bam (Boolean)
    inputBinding:
      prefix: --sam

  version:
    type:
      type: enum
      symbols: [default]
    inputBinding:
      prefix: --version


    default: default
outputs:
  bam:
    type: File
    outputBinding:
      glob: |-
        ${
          if (inputs.output)
            return inputs.output;
          return null;
        }
