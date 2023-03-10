#!/bin/bash
source setenv-server.sh

function verifyDirectory() {
  deployDirectory="/home/$LXC_USER/deploy"
  if [ "$PWD" != "$deployDirectory" ]; then
    echo "Aborted: File has to be run from $deployDirectory but was run from $PWD"
    exit
  fi
}

function getPid() {
  versionFile=$1
  versionRunning=$(<"$versionFile")
  echo "$(jps | grep -i "$versionRunning" | awk -F " " '{print $1}')"
}

function killProcess() {
  pid=$1
  echo "Attempting to exit gracefully: kill -SIGTERM $pid"
  if [ "x$pid" == "x" ]; then
    rm "$versionFile"
    exit
  fi
  kill -SIGTERM "$pid"

  isProcessRunningValue=$(isProcessRunning "$pid")
  timeWaitedToShutdown=0
  interval=10
  maxWaitTime=30
  while [ "$isProcessRunningValue" == "true" ]; do
    if ((timeWaitedToShutdown > maxWaitTime)); then
      echo "Process could not exit gracefully: kill -SIGKILL $pid"
      kill -SIGKILL "$pid"
    fi
    sleep $interval
    isProcessRunningValue=$(isProcessRunning "$pid")
    timeWaitedToShutdown=$((timeWaitedToShutdown + interval))
    echo "Total time waited: $timeWaitedToShutdown"
  done
  echo "Process exited $pid: "
}

function isProcessRunning() {
  nrOfMatchingJpsPids="$(jps | grep -c "$1")"
  if ((nrOfMatchingJpsPids > 0)); then
    echo "true"
  else
    echo "false"
  fi
}

# Procedure
verifyDirectory
versionFile="$COMMON_VERSION_FILE"
pid=$(getPid "$versionFile")
killProcess "$pid"
rm "$versionFile"
