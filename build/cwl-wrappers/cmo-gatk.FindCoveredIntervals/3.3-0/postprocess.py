#!/usr/bin/python
"""postprocess"""

import argparse
import ruamel.yaml


def read(filename):
    """return file contents"""

    with open(filename, 'r') as file_in:
        return file_in.read()


def write(filename, cwl):
    """write to file"""

    with open(filename, 'w') as file_out:
        file_out.write(cwl)


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

# 1) we're doing this way to preserve the order
#    can't figure out other ways.
# 2) the prefix --input_file param must be set up this way to have
#    GATK output --input_file multiple times
    input_file_type = """
type: array
items: File
inputBinding:
  prefix: --input_file
"""
    cwl['inputs']['input_file']['type'] = ruamel.yaml.load(input_file_type, ruamel.yaml.RoundTripLoader)
    del cwl['inputs']['input_file']['inputBinding']

    cwl['inputs']['num_threads']['type'] = ['null', 'string']
    cwl['inputs']['out']['type'] = 'string'

    #-->
    # fixme: until we can auto generate cwl for GATK
    # set outputs using outputs.yaml
    import os
    cwl['outputs'] = ruamel.yaml.load(
        read(os.path.dirname(params.filename_cwl) + "/outputs.yaml"),
        ruamel.yaml.RoundTripLoader)['outputs']

    # from : ['cmo_gatk', '-T FindCoveredIntervals', '--version 3.3-0']
    # to   : ['cmo_gatk', '-T', 'FindCoveredIntervals', '--version', '3.3-0']
    cwl['baseCommand'] = ['cmo_gatk', '-T', 'FindCoveredIntervals', '--version', '3.3-0']
    #<--

    write(params.filename_cwl, ruamel.yaml.dump(
        cwl, Dumper=ruamel.yaml.RoundTripDumper))


if __name__ == "__main__":

    main()
