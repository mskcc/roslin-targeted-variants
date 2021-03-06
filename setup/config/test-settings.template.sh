#!/bin/bash
export ROSLIN_TEST_ROOT="{{ test_root }}"
export ROSLIN_TEST_BATCHSYSTEM="{{ test_batchsystem }}"
export ROSLIN_TEST_CWL_BATCHSYSTEM="{{ test_cwl_batchsystem }}"
export ROSLIN_TEST_USE_DOCKER="{{ test_use_docker }}"
export ROSLIN_TEST_DOCKER_REGISTRY="{{ test_docker_registry }}"
export ROSLIN_TEST_RUN_ARGS="{{ test_run_args }}"
export ROSLIN_TEST_DATA_PATH="{{ test_data_path }}"
export ROSLIN_TEST_DATA_URL="{{ test_data_url }}"
export TMPDIR="{{ test_tmp }}"
export TMP="{{ test_tmp }}"
{{ test_env }}
case "$SINGULARITY_BIND" in
	*$TMPDIR*)
		if [ -n "$TMPDIR" ]
		then
			mkdir -p $TMPDIR >/dev/null 2>&1 || true
			export SINGULARITY_BIND="$SINGULARITY_BIND,$TMPDIR"
			export DOCKER_BIND="$DOCKER_BIND -v $TMPDIR:$TMPDIR"
		fi
	;;
	*$TMP*)
		if [ -n "$TMP" ]
		then
			mkdir -p $TMP >/dev/null 2>&1 || true
			export SINGULARITY_BIND="$SINGULARITY_BIND,$TMP"
			export DOCKER_BIND="$DOCKER_BIND -v $TMP:$TMP"
		fi
	;;
esac