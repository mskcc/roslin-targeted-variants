export ROSLIN_PIPELINE_DESCRIPTION="{{ pipeline_description }}"

# Roslin pipeline name/version
export ROSLIN_PIPELINE_NAME="{{ pipeline_name }}"
export ROSLIN_PIPELINE_VERSION="{{ pipeline_version }}"

# which version of Roslin Core is required?
export ROSLIN_CORE_MIN_VERSION="{{ core_min_version }}"
export ROSLIN_CORE_MAX_VERSION="{{ core_max_version }}"

# Roslin pipeline root path
export ROSLIN_PIPELINE_ROOT="{{ pipeline_root }}/${ROSLIN_PIPELINE_NAME}/${ROSLIN_PIPELINE_VERSION}"
export ROSLIN_ROOT="{{ pipeline_root }}"
#--> the following paths will be supplied to singularity as bind points

# binaries, executables, scripts
export ROSLIN_PIPELINE_BIN_PATH="${ROSLIN_PIPELINE_ROOT}/{{ binding_core }}"

export ROSLIN_PIPELINE_CWL_PATH="${ROSLIN_PIPELINE_BIN_PATH}/cwl"

# reference data (e.g. genome assemblies)
export ROSLIN_PIPELINE_DATA_PATH="${ROSLIN_PIPELINE_ROOT}/{{ binding_data }}"

# other paths that we'd like to bind (space separated)
export ROSLIN_EXTRA_BIND_PATH="{{ binding_extra }}"

# output path
export ROSLIN_PIPELINE_OUTPUT_PATH="${ROSLIN_PIPELINE_ROOT}/{{ binding_output }}"

# workspace
export ROSLIN_PIPELINE_WORKSPACE_PATH="${ROSLIN_PIPELINE_ROOT}/{{ binding_workspace }}"

# deduplicated bind points (space separated)
export SINGULARITY_BIND="{{ binding_deduplicated }}"
export DOCKER_BIND="{{ docker_binding }}"
#<--

# path to singularity executable
# singularity is expected to be found at the same location regardless of the nodes you're on
# override this if you want to test a different version of singularity.
export ROSLIN_SINGULARITY_VERSION="{{ dependencies_singularity_version }}"
{{ load_singularity }}

# cmo
export ROSLIN_CMO_VERSION="{{ dependencies_cmo_version }}"
export ROSLIN_CMO_INSTALL_PATH="{{ dependencies_cmo_install_path }}"

# toil
export ROSLIN_TOIL_VERSION="{{ dependencies_toil_version }}"
export ROSLIN_TOIL_INSTALL_PATH="{{ dependencies_toil_install_path }}"

export ROSLIN_CURRENT_USER=`python -c "import getpass; print getpass.getuser()"`
export ROSLIN_CURRENT_KERNEL=`python -c "import os; print '.'.join(os.uname()[2].split('.')[0:2])"`

export ROSLIN_USER_WORKSPACE_PATH=${ROSLIN_PIPELINE_WORKSPACE_PATH}/${ROSLIN_CURRENT_USER}-${ROSLIN_CURRENT_KERNEL}
export ROSLIN_PIPELINE_RESOURCE_PATH=${ROSLIN_USER_WORKSPACE_PATH}/resources
export ROSLIN_EXAMPLE_PATH=${ROSLIN_USER_WORKSPACE_PATH}/examples/
export NVM_DIR="$ROSLIN_PIPELINE_RESOURCE_PATH/.nvm"

if [ -d $ROSLIN_PIPELINE_WORKSPACE_PATH ]
then
	if [ ! -d $ROSLIN_USER_WORKSPACE_PATH ]
	then
		echo "Setting up workspace for user ${ROSLIN_CURRENT_USER}"
		mkdir -p ${ROSLIN_PIPELINE_WORKSPACE_PATH}/${ROSLIN_CURRENT_USER}-${ROSLIN_CURRENT_KERNEL}

		if [ ! -d $ROSLIN_PIPELINE_RESOURCE_PATH ]
		then
			if [ -x "$(command -v roslin_create_test_files.py)" ]
			then
				CURRENT_DIR=$(pwd)
				mkdir -p $ROSLIN_PIPELINE_RESOURCE_PATH
				cd $ROSLIN_PIPELINE_RESOURCE_PATH

				${ROSLIN_PIPELINE_DATA_PATH}/build-node.sh

				# setup virtualenv
				virtualenv virtualenv
				source virtualenv/bin/activate
				export PATH=${ROSLIN_PIPELINE_RESOURCE_PATH}/virtualenv/bin/:$PATH
				pip install --requirement ${ROSLIN_PIPELINE_DATA_PATH}/run_requirements.txt

				# install toil
				if [ -x "$(command -v unsetopt)" ]
				then
					unsetopt nomatch
				fi

				{{ toil_install }}

				# create test files
				roslin_create_test_files.py --name ${ROSLIN_PIPELINE_NAME} --version ${ROSLIN_PIPELINE_VERSION}
				cd $CURRENT_DIR
cat << "EOF"

 ______     ______     ______     __         __     __   __
/\  == \   /\  __ \   /\  ___\   /\ \       /\ \   /\ "-.\ \
\ \  __<   \ \ \/\ \  \ \___  \  \ \ \____  \ \ \  \ \ \-.  \
 \ \_\ \_\  \ \_____\  \/\_____\  \ \_____\  \ \_\  \ \_\\"\_\
  \/_/ /_/   \/_____/   \/_____/   \/_____/   \/_/   \/_/ \/_/
 ______   __     ______   ______     __         __     __   __     ______
/\  == \ /\ \   /\  == \ /\  ___\   /\ \       /\ \   /\ "-.\ \   /\  ___\
\ \  _-/ \ \ \  \ \  _-/ \ \  __\   \ \ \____  \ \ \  \ \ \-.  \  \ \  __\
 \ \_\    \ \_\  \ \_\    \ \_____\  \ \_____\  \ \_\  \ \_\\"\_\  \ \_____\
  \/_/     \/_/   \/_/     \/_____/   \/_____/   \/_/   \/_/ \/_/   \/_____/

Roslin Pipeline

EOF

echo "Your workspace: ${ROSLIN_USER_WORKSPACE_PATH}"
echo
echo "Add the following line to your .profile or .bashrc if not already added:"
echo
echo "source ${ROSLIN_CORE_CONFIG_PATH}/settings.sh"
			fi
		fi
	else
		echo "Workspace: ${ROSLIN_USER_WORKSPACE_PATH}"
	fi
fi

# node
if [ -s $NVM_DIR/nvm.sh ]
then
	echo "Loading Node..."
	source $NVM_DIR/nvm.sh
fi

# Load the virtualenv
if [ -e $ROSLIN_PIPELINE_RESOURCE_PATH/virtualenv/bin/activate ]
then
	echo "Loading Virtualenv..."
	source $ROSLIN_PIPELINE_RESOURCE_PATH/virtualenv/bin/activate
fi

# Run environment
{{ run_env }}
if [[ $SINGULARITY_BIND == *"$TMPDIR"* && -n "$TMPDIR" ]]
then
	mkdir -p $TMPDIR >/dev/null 2>&1 || true
	export SINGULARITY_BIND="$SINGULARITY_BIND,$TMPDIR"
	export DOCKER_BIND="$DOCKER_BIND -v $TMPDIR:$TMPDIR"
fi

if [[ $SINGULARITY_BIND == *"$TMP"* && -n "$TMP" ]]
then
	mkdir -p $TMPDIR >/dev/null 2>&1 || true
	export SINGULARITY_BIND="$SINGULARITY_BIND,$TMP"
	export DOCKER_BIND="$DOCKER_BIND -v $TMP:$TMP"
fi
# Load singularity into PATH
singularity_bin_path=`dirname $ROSLIN_SINGULARITY_PATH`
export PATH=$singularity_bin_path:$PATH
echo "Loaded Roslin Pipeline - $ROSLIN_PIPELINE_NAME ( $ROSLIN_PIPELINE_VERSION )"
