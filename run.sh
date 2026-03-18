#!/bin/bash

export BASE_DIR="$(pwd)"
mode="run"
variables=""

parse_input_variables() {
  local input="$1"
  local result=""
  IFS=',' read -ra pairs <<< "$input"
  for p in "${pairs[@]}"; do
    result+=" -J$p"
  done
  echo "${result# }"
}

execute_test() {
    echo "Run jmeter test"
    TEST_DIR=$BASE_DIR/tests
    RESULTS_DIR=$BASE_DIR/results
    CMD="jmeter -n -t $TEST_DIR/test.jmx -l $RESULTS_DIR/test.jtl $(parse_input_variables "$variables")"
    echo "Running $CMD"
    eval "$CMD"
    cat $RESULTS_DIR/test.jtl
}

check() {
    echo "Validation successful [BASE_DIR=$BASE_DIR]"
}

parse_args() {
  if [ "$#" -eq "0" ]; then
    echo "ERROR: Illegal number of parameters" >&2
    exit 1
  fi

  OPTIND=1
  while getopts ":m:p:" option; do
    echo "Getting arg $option..."
    case $option in
      m)
        mode=${OPTARG,,}
        if ! [[ $mode =~ ^(run|check)$ ]]; then
          echo "ERROR: Unknown mode '$mode'. Allowed: [run, check]"
          exit 1
        fi
        echo "mode => $mode"
        ;;
      p) 
        variables="$OPTARG"
        echo "variables => $variables"
        ;;
      *)
        echo "ERROR: Unknown argument: $option"
        exit 1
        ;;
    esac
  done
}

cleanup_workspace_logs() {
  rm -r -f "${BASE_DIR}/jmeter.log"
}

main() {
  parse_args "$@"

  case "$mode" in
    check)
      check
      ;;
    run)
      execute_test
      cleanup_workspace_logs
      ;;
  esac
}

main "$@"