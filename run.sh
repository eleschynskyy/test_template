#!/bin/bash

echo "Run jmeter test"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR=$SCRIPT_DIR/tests
RESULTS_DIR=$SCRIPT_DIR/results
shopt -s extglob
rm -rf $RESULTS_DIR/!(.gitkeep)

jmeter -n -t $TEST_DIR/test.jmx -l $RESULTS_DIR/test.jtl
# rm $SCRIPT_DIR/jmeter.log