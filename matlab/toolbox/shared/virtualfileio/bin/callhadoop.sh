#!/bin/sh
#
# Syntax:
#  callhadoop.sh ${JAVA_HOME} ${HADOOP_HOME}/bin/hadoop arguments
#

# Copyright 2018 The MathWorks, Inc.

# Extract out JAVA_HOME
export JAVA_HOME=${1}
shift;

# Forward everything else to the target being called.
${@}
rc=$?
