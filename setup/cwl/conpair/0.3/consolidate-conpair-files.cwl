#!/usr/bin/env cwl-runner

$namespaces:
  dct: http://purl.org/dc/terms/
  foaf: http://xmlns.com/foaf/0.1/
  doap: http://usefulinc.com/ns/doap#

$schemas:
- file:///juno/work/pi/roslin-pipelines/2.5.0-su/roslin-core/2.0.6/schemas/dcterms.rdf
- file:///juno/work/pi/roslin-pipelines/2.5.0-su/roslin-core/2.0.6/schemas/foaf.rdf
- file:///juno/work/pi/roslin-pipelines/2.5.0-su/roslin-core/2.0.6/schemas/doap.rdf

doap:release:
- class: doap:Version
  doap:name: consolidate-files
  doap:revision: 1.0.0
- class: doap:Version
  doap:name: cwl-wrapper
  doap:revision: 1.0.0

dct:creator:
- class: foaf:Organization
  foaf:name: Memorial Sloan Kettering Cancer Center
  foaf:member:
  - class: foaf:Person
    foaf:name: Ian Johnson
    foaf:mbox: mailto:johnsoni@mskcc.org

dct:contributor:
- class: foaf:Organization
  foaf:name: Memorial Sloan Kettering Cancer Center
  foaf:member:
  - class: foaf:Person
    foaf:name: Allan Bolipata
    foaf:mbox: mailto:bolipatc@mskcc.org

cwlVersion: v1.0

class: ExpressionTool
id: consolidate-conpair-files

requirements:
  - class: InlineJavascriptRequirement

inputs:

  output_directory_name: string

  files:
    type:
      type: array
      items: File

outputs:

  directory:
    type: Directory

# This tool returns a Directory object,
# which holds all output files from the list
# of supplied input files
expression: |
  ${
    var output_files = [];

    for (var i = 0; i < inputs.files.length; i++) {
        output_files.push(inputs.files[i]);    
    }

    return {
      'directory': {
        'class': 'Directory',
        'basename': inputs.output_directory_name,
        'listing': output_files
      }
    };
  }