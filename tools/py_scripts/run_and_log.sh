#!/bin/bash
echo "Running command : $*"
echo "Run directory is set to : $BAZEL_RUN_DIRECTORY"
$* | tee test.log

# Copy result after done execution
cp -r ./ $BAZEL_RUN_DIRECTORY
