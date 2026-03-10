#!/bin/bash

export BASE_DIR="$(pwd)"
mode="run" 

execute_test() {
    echo "Run jmeter test"

    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "BASE_DIR=$BASE_DIR : SCRIPT_DIR=$SCRIPT_DIR"
    # TEST_DIR=$SCRIPT_DIR/tests
    # RESULTS_DIR=$SCRIPT_DIR/results
    # shopt -s extglob
    # rm -rf $RESULTS_DIR/!(.gitkeep)

    # jmeter -n -t $TEST_DIR/test.jmx -l $RESULTS_DIR/test.jtl
}

check() {
    echo "Checking folder"

    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "BASE_DIR=$BASE_DIR : SCRIPT_DIR=$SCRIPT_DIR"
}

parse_args() {
  if [ "$#" -eq "0" ]; then
    echo "ERROR: Illegal number of parameters" >&2
    exit 1
  fi

  OPTIND=1
  while getopts ":m:" option; do
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