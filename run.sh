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
    CMD="jmeter -n -t $TEST_DIR/test.jmx -l $RESULTS_DIR/test.jtl $(parse_input_variables "$variables") -Lorg.apache.jmeter.visualizers.backend=DEBUG"
    echo "Running $CMD"
    eval "$CMD"
    cat $RESULTS_DIR/test.jtl
}

check() {
    echo "Validation successful [BASE_DIR=$BASE_DIR]"
}

prepare_influx_bucket() {
    # Check required environment variables
    if [ -z "$INFLUXDB_URL" ] || [ -z "$INFLUXDB_ORG_ID" ] || [ -z "$INFLUXDB_TOKEN" ] || [ -z "$INFLUXDB_BUCKET_NAME" ]; then
        echo "Error: One or more required environment variables are missing."
        echo "Required: INFLUXDB_URL, INFLUXDB_ORG_ID, INFLUXDB_TOKEN, INFLUXDB_BUCKET_NAME"
        return 1
    fi

    # Ensure dependencies
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed."
        return 1
    fi

    if ! command -v curl &> /dev/null; then
        echo "Error: curl is required but not installed."
        return 1
    fi

    echo "Checking InfluxDB at $INFLUXDB_URL for Org: $INFLUXDB_ORG_ID"

    # 1. Get Organization ID
    # We use -g/--globoff to handle square brackets in URLs if necessary
    local ORG_RESPONSE
    ORG_RESPONSE=$(curl -s "$INFLUXDB_URL/api/v2/orgs?org=$INFLUXDB_ORG_ID" \
      -H "Authorization: Token $INFLUXDB_TOKEN")

    # Check if org exists (using jq to parse ID)
    local ORG_ID
    ORG_ID=$(echo "$ORG_RESPONSE" | jq -r '.orgs[0].id')

    if [ "$ORG_ID" == "null" ] || [ -z "$ORG_ID" ]; then
        echo "Error: Organization '$INFLUXDB_ORG_ID' not found."
        echo "Response was: $ORG_RESPONSE"
        return 1
    fi

    echo "Found Organization ID: $ORG_ID"

    # 2. Check if Bucket exists
    local BUCKET_RESPONSE
    BUCKET_RESPONSE=$(curl -s "$INFLUXDB_URL/api/v2/buckets?org=$INFLUXDB_ORG_ID&name=$INFLUXDB_BUCKET_NAME" \
      -H "Authorization: Token $INFLUXDB_TOKEN")

    local BUCKET_ID
    BUCKET_ID=$(echo "$BUCKET_RESPONSE" | jq -r '.buckets[0].id')

    if [ "$BUCKET_ID" != "null" ] && [ -n "$BUCKET_ID" ]; then
        echo "Bucket '$INFLUXDB_BUCKET_NAME' already exists (ID: $BUCKET_ID). Skipping creation."
        return 0
    fi

    # 3. Create Bucket if it doesn't exist
    echo "Bucket '$INFLUXDB_BUCKET_NAME' not found. Creating with infinite retention..."

    local CREATE_RESPONSE
    # Retention rules empty list means infinite retention
    CREATE_RESPONSE=$(curl -s -X POST "$INFLUXDB_URL/api/v2/buckets" \
      -H "Authorization: Token $INFLUXDB_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"orgID\": \"$ORG_ID\",
        \"name\": \"$INFLUXDB_BUCKET_NAME\",
        \"retentionRules\": []
      }")

    local NEW_BUCKET_ID
    NEW_BUCKET_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id')

    if [ "$NEW_BUCKET_ID" != "null" ] && [ -n "$NEW_BUCKET_ID" ]; then
        echo "Successfully created bucket '$INFLUXDB_BUCKET_NAME' (ID: $NEW_BUCKET_ID)."
    else
        echo "Failed to create bucket. Response:"
        echo "$CREATE_RESPONSE"
        return 1
    fi
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
  # rm -r -f "${BASE_DIR}/jmeter.log"
  echo 'cleanup_workspace_logs'
  cat ${BASE_DIR}/jmeter.log
}

main() {
  parse_args "$@"

  case "$mode" in
    check)
      check
      prepare_influx_bucket
      ;;
    run)
      execute_test
      cleanup_workspace_logs
      ;;
  esac
}

main "$@"