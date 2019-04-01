#!/bin/bash

pipeline_name_version="$ROSLIN_PIPELINE_NAME/$ROSLIN_PIPELINE_VERSION"

roslin_request_to_yaml.py \
    --pipeline ${pipeline_name_version} \
    -m Proj_DEV_0003_sample_mapping.txt \
    -p Proj_DEV_0003_sample_pairing.txt \
    -g Proj_DEV_0003_sample_grouping.txt \
    -r Proj_DEV_0003_request.txt \
    -o . \
    -f inputs.yaml

roslin_submit.py \
    --id Proj_DEV_0003 \
    --path . \
    --workflow project-workflow-sv.cwl \
    --pipeline ${pipeline_name_version} \
