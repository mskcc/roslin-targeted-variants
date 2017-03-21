#!/bin/bash

# load build-related settings
source ./settings-build.sh

# load utils
source ./tools-utils.sh


# flag for interactive mode
if [ "`whoami`" != 'root' ]
then
    echo "Run sudo su first."
    exit 1
fi

usage()
{
cat << EOF

USAGE: $0 [options]

OPTIONS:

   -t      List of tools to build (comma-separated list)
           All pre-defined tools will be built if -t is not specified.
           
           Example: $0 -t bwa:0.7.12:cmo_bwa_mem,trimgalore:0.4.3:cmo_trimgalore

   -z      Show list of tools that be built

   -h      Help

EOF
}

while getopts “t:zh” OPTION
do
    case $OPTION in
        t) SELECTED_TOOLS_TO_BUILD=$OPTARG ;;
        z) for tool in $(get_tools_name_version_cmo); do echo $tool; done; exit 1 ;;
        h) usage; exit 1 ;;
        *) usage; exit 1 ;;
    esac
done

# comma-separated list of [tool-name]:[tool-version]:[corresponding-cmo-wrapper]
if [ -z "$SELECTED_TOOLS_TO_BUILD" ]
then    
    SELECTED_TOOLS_TO_BUILD=$(get_tools_name_version_cmo)
fi


# override cmo_resources.json in git repository.
# the paths in the new cmo_resources.json point to the location of each tool in the containers.
cp ${CWL_WRAPPER_DIRECTORY}/cmo_resources.json ${MY_TEMP_DIRECTORY}/cmo-gxargparse/cmo/cmo/data/

# this will be used for local cache for alpine linux package manager & python pip.
# this let us avoid from downloading the same packages over and over again for each and every tool.
# https://wiki.alpinelinux.org/wiki/Local_APK_cache
# https://pip.pypa.io/en/latest/reference/pip_install/#caching
mkdir -p ${MY_TEMP_DIRECTORY}/cache/

for tool_info in $(echo $SELECTED_TOOLS_TO_BUILD | sed "s/,/ /g")
do
    tool_name=$(get_tool_name $tool_info)
    tool_version=$(get_tool_version $tool_info)
    cmo_wrapper=$(get_cmo_wrapper_name $tool_info)

    if [ "$tool_name" == "abra" ] || [ "$tool_name" == "gatk" ]
    then
        continue
    fi

    echo "Generating CWL: ${cmo_wrapper} (${tool_name} version ${tool_version})"

    docker_image_full_name="localhost:5000/${DOCKER_REPO_TOOLNAME_PREFIX}-${tool_info}"

    error_file_name="error.${cmo_wrapper}-${tool_version}.txt"
    ./process-cwl-2.sh -t ${tool_name} -v ${tool_version} -c ${cmo_wrapper} #2>${error_file_name}

done
