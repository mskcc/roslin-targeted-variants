# Create CWL Wrapper

This document will walk you through using *BCFTools v1.3.1* as an example, but specifically the `norm` command in BCFTools.

## Bird's Eye View

![/docs/cwl-autogen-process.png](/docs/cwl-autogen-process.png)

## Stay up-to-date

Some CWL wrappers rely on cmo packages, thus your cmo package inside the vagrant box must be up-to-date in order to generate the correct program arguments.

```
$ cd /usr/local/bin/cmo-gxargparse/cmo
$ git pull
```

The build scripts use `ruamel.yaml` to handle YAML version 1.2. In case you want to stay up-to-date with `ruamel.yaml` without re-creating the vagrant box, you can run the following command inside the vagrant box:

```
$ sudo su
$ pip install ruamel.yaml --upgrade
```

## tools.json

Define a dependency relationship in `/build/scripts/tools.json`. The `containerDependency` section describes that the `cmo_bcftools norm` command calls the containerized `bcftools norm` with tool-specific parameters. The suffix `.norm` below denotes that we are generating a CWL wrapper for BCFTools' `norm` command.

```
{
    "containerDependency": {
        ...
        "bcftools": [
            "cmo_bcftools.norm"
        ],
        ...
    }
}
```

Sometimes, there could be 1:N relationships, especially for those tools that provide a single binary/executable, but expose multiple functionalities via subcommands (e.g. GATK, Picard, BCFTools):

```
{
    "containerDependency": {
        ...
        "picard": [
            "cmo_picard.MarkDuplicates",
            "cmo_picard.AddOrReplaceReadGroups",
            "cmo_picard.FixMateInformation"
        ],
        "gatk": [
            "cmo_gatk.FindCoveredIntervals",
            "cmo_gatk.BaseRecalibrator",
            "cmo_gatk.PrintReads",
            "cmo_gatk.SomaticIndelDetector"
        ],
        ...
    }
}
```

## cmo_resources.json

Make sure that there is only the `default` key for a given tool in `/build/cwl-wrappers/cmo_resources.json`. If there are any other keys besides the `default` key, remove them.

Set the value to a Docker run command that can actually invoke the tool and output the tool-specific arguments. For example:

```
{
    "programs": {
        ...
        "bcftools": {
            "default": "sudo docker run -i bcftools:1.3.1"
        },
        ...
    }
}
```

What this does is that `gxargparse` will find this entry and call the Dockerized tool, collect the arguments printed out to the console, parse them, and finally convert to a CWL document.

The `cmo_resources.json` file is used only during the CWL generation process. This file won't be used at runtime.

## roslin_resources.json

What's actually used at runtime is `/build/cwl-wrappers/roslin_resources.json`. Make sure that this file has the correct key/value mapping, something like below under the tool name (e.g. `bcftools`).

```
"bcftools": {
    "1.3.1": "sing.sh bcftools 1.3.1",
    "default": "sing.sh bcftools 1.3.1"
}
```

What this does is, upon calling `cmo_bcftools norm`, it will find this entry and call the Singularity wrapper `sing.sh` with a specific version of the tool image. The `default` key is not really used (more like shouldn't be used) because all our workflow written in CWL calls specific versions of the tools.

## Create Directory

Create a directory `/bulid/cwl-wrapers/cmo-bcftools.norm/1.3.1`.

At the end of the day, this directory would look something like below:

```bash
cmo-bcftools.norm/
└── 1.3.1
    ├── cmo-bcftools.norm.cwl
    ├── metadata.yaml
    ├── outputs.yaml
    ├── postprocess.py
    └── requirements.yaml
```

`postprocess.py` is optional in case a given tool does not require any postprocess steps.

## metadata.yaml

Add metadata about the CWL wrapper, creator, and contributor.

### Tool Name/Version, CWL Wrapper Version

In the example below, cmo-bcftools.norm has the version tag 1.3.1 whereas cwl wrapper has 1.0.0. The tool's version stays the same, but cwl-wrapper version can still change (e.g. default value changed)

```yaml
doap:release:
- class: doap:Version
  doap:name: cmo-bcftools.norm
  doap:revision: 1.3.1
- class: doap:Version
  doap:name: cwl-wrapper
  doap:revision: 1.0.0
```

### Creator

```yaml
dct:creator:
- class: foaf:Organization
  foaf:name: Memorial Sloan Kettering Cancer Center
  foaf:member:
  - class: foaf:Person
    foaf:name: Jaeyoung Chun
    foaf:mbox: mailto:chunj@mskcc.org
```

### Contributor

```yaml
dct:contributor:
- class: foaf:Organization
  foaf:name: Memorial Sloan Kettering Cancer Center
  foaf:member:
  - class: foaf:Person
    foaf:name: John Doe
    foaf:mbox: mailto:djohn@mskcc.org
```

## outputs.yaml

Make sure there are no trailing whitespaces, otherwise YAML complains.

```yaml
outputs:
  bam:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output)
            return inputs.output;
          return null;
        }
```

## requirements.yaml

This file defines how much memory and CPU cores is required to run this tool:

```yaml
requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 30
    coresMin: 5
```

## postproces.py

Sometimes, the CWL file generated by `gxargparse` alone is not sufficient to do what we want. For example, most of the time `gxargparse` uses the `string` type for file inputs whereas our preferred type is `File`. In this case, you can program this in `postprocess.py`. The example below shows how to convert the `fastq` input type from `string` only to `string` and `File`.

Make sure not to change anything other than what's between `# --------->` and `# <--------`.

```python
def main():
    """main function"""

    parser = argparse.ArgumentParser(description='postprocess')

    parser.add_argument(
        '-f',
        action="store",
        dest="filename_cwl",
        help='Name of the cwl file',
        required=True
    )

    params = parser.parse_args()

    cwl = ruamel.yaml.load(read(params.filename_cwl),
                           ruamel.yaml.RoundTripLoader)

    # --------> do not change above

    cwl['inputs']['fastq1']['type'] = ['string', 'File']

    # <-------- do not change below

    write(params.filename_cwl, ruamel.yaml.dump(
        cwl, Dumper=ruamel.yaml.RoundTripDumper))


if __name__ == "__main__":

    main()

```

## cmo-bcftools.norm.original.cwl

Sometimes, `cmo_bcftools` and `gxargparse` cannot generate CWL file for us in an automatic fashion. In this case, you can add a manually created CWL wrapper, use this as the basis, and apply any necessary postprocess steps. This manually generated CWL wrapper file must end with `.original.cwl`.

Also, note that any underscore (`_`) characters in the file name must be replaced with dash (`-`) character.

## Build

Note that this part must be done inside the virtual machine.

To see what tools can be built, run `build-cwl.sh` with the `-z` parameter:

```bash
$ ./build-cwl.sh -z
trimgalore:0.4.3:cmo_trimgalore
trimgalore:0.2.5.mod:cmo_trimgalore
pindel:0.2.5b8:cmo_pindel
pindel:0.2.5a7:cmo_pindel
picard:1.96:cmo_picard.MarkDuplicates
picard:1.96:cmo_picard.AddOrReplaceReadGroups
picard:1.96:cmo_picard.FixMateInformation
mutect:1.1.4:cmo_mutect
vardict:1.4.6:cmo_vardict
bwa:0.7.15:cmo_bwa_mem
bwa:0.7.12:cmo_bwa_mem
bwa:0.7.5a:cmo_bwa_mem
abra:0.92:cmo_abra
gatk:3.3-0:cmo_gatk.FindCoveredIntervals
gatk:2.3-9:cmo_gatk.FindCoveredIntervals
gatk:3.3-0:cmo_gatk.BaseRecalibrator
gatk:2.3-9:cmo_gatk.BaseRecalibrator
gatk:3.3-0:cmo_gatk.PrintReads
gatk:2.3-9:cmo_gatk.PrintReads
gatk:3.3-0:cmo_gatk.SomaticIndelDetector
gatk:2.3-9:cmo_gatk.SomaticIndelDetector
bcftools:1.3.1:cmo_bcftools.norm
list2bed:1.0.1:cmo_list2bed
```

To generate a CWL wrapper for a specific tool, run `build-cwl.sh` with the `-t` parameter:

```bash
$ ./build-cwl.sh -t bcftools:1.3.1:cmo_bcftools.norm
```

If the CWL wrapper is successfully created, you will see the following output:

```bash
Generating CWL: cmo_bcftools.norm (bcftools version 1.3.1)
../cwl-wrappers/cmo-bcftools.norm/1.3.1
├── cmo-bcftools.norm.cwl
├── cmo-bcftools.norm.original.cwl
├── metadata.yaml
├── outputs.yaml
└── requirements.yaml

0 directories, 5 files
```

If not successful, you can find any error message in this file `error.cmo_bcftools.norm-1.3.1.txt`.

## Verify

For now, there is no easy way to verify the tool's functionality except creating a simple example and running it on Luna.

Here is a bwa mem example:

### inputs.yaml

```yaml
genome: "GRCh37"

fastq1:
  class: File
  path: ../data/fastq/P1_R1.fastq.gz
fastq2:
  class: File
  path: ../data/fastq/P1_R2.fastq.gz

output: P1.bam
```

### run-example.sh

```bash
#!/bin/bash

roslin-runner.sh \
    -w cmo-bwa-mem/0.7.5a/cmo-bwa-mem.cwl \
    -i inputs.yaml \
    -b lsf
```
