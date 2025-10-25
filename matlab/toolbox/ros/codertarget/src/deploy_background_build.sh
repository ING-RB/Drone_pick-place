#!/bin/bash
#
# Copyright 2015-2024 The MathWorks, Inc.

BUILD_SCRIPT=$1
MODEL_NAME=$2
CATKIN_WS=$3
SUBDIR_PROJECT=$4

# Launch a background process and record return status to a file
if [ $# -eq 4 ] ; then
    "$BUILD_SCRIPT" "$MODEL_NAME".tgz "$CATKIN_WS" $SUBDIR_PROJECT &> "$MODEL_NAME"_build.log &
else
    "$BUILD_SCRIPT" "$MODEL_NAME".tgz "$CATKIN_WS" &> "$MODEL_NAME"_build.log &
fi
pid=$!
wait $pid
echo $? > "$MODEL_NAME"_build.stat

exit 0

