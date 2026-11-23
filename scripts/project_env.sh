#!/usr/bin/env bash
# Source this file in every terminal used for the assignment.
source /home/cse/.local/opt/bda-hadoop.env
export P7ZIP_HOME=/home/cse/.local/opt/p7zip-root
export MONGO_TOOLS_HOME=/home/cse/.local/opt/mongodb-tools
export PIG_HOME=/home/cse/.local/opt/pig-0.18.0
export HIVE_HOME=/home/cse/.local/opt/apache-hive-4.1.0-bin
export LD_LIBRARY_PATH="$P7ZIP_HOME/usr/lib/p7zip${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="/home/cse/.local/bin:$P7ZIP_HOME/usr/lib/p7zip:$MONGO_TOOLS_HOME/bin:$PIG_HOME/bin:$HIVE_HOME/bin:$PATH"
