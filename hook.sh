#!/bin/bash

PROJECT_DIR="$1"
if [[ ! "$PROJECT_DIR" || ! -d "$PROJECT_DIR" ]]; then
  echo "Could not find project directory: $PROJECT_DIR"
  exit 1
fi

# the temp directory used, within $DIR
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=`mktemp -d -p .`

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# deletes the temp directory
function cleanup {
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

cd "$WORK_DIR"
curl -sOL https://github.com/octarinesec/publicfiles/raw/demo_0.1/dagent.tar.gz
if [[ "$?" -ne "0" ]]; then
  echo "Unable to download agent."
  exit 1
fi

tar -xf dagent.tar.gz
if [[ "$?" -ne "0" ]]; then
  echo "Unable to extract agent."
  exit 1
fi

env_vars="OCTARINE_SERVICE_ARTIFACT=\"\${OCTARINE_SERVICE_ARTIFACT:-agroup:amember}\" \
OCTARINE_SERVICE_DEPLOYMENT=\"\${OCTARINE_SERVICE_DEPLOYMENT:-agroup:amember}\" \
OCTARINE_NAMESPACE=\"\${OCTARINE_NAMESPACE:-demo}\" \
OCTARINE_ARTIFACT_NAME=\"\${OCTARINE_ARTIFACT_NAME:-foo}\" \
OCTARINE_SERVICE_VERSION=\"\${OCTARINE_SERVICE_VERSION:-1.0}\" \
OCTARINE_KAFKA_HOSTNAME=\"\${OCTARINE_KAFKA_HOSTNAME:-localhost}\" \
OCTARINE_KAFKA_PORT=\"\${OCTARINE_KAFKA_PORT:-9093}\" \
OCTARINE_BACKEND_HOSTNAME=\"\${OCTARINE_BACKEND_HOSTNAME:-localhost}\" \
OCTARINE_BACKEND_USERNAME=\"\${OCTARINE_BACKEND_USERNAME:-configuser}\" \
OCTARINE_BACKEND_PASSWORD=\"\${OCTARINE_BACKEND_PASSWORD:-configpass}\" \
OCTARINE_BACKEND_LOGIN_PORT=\"\${OCTARINE_BACKEND_LOGIN_PORT:-8080}\" \
OCTARINE_BACKEND_CONFIG_PORT=\"\${OCTARINE_BACKEND_CONFIG_PORT:-8080}\""

pip3 install plumbum weka-easypy pyaml
if [[ "$?" -ne "0" ]]; then
  echo "Unable to install python requirements."
  exit 1
fi

cd hooker
python3 ./hook.py hook "$PROJECT_DIR" "$env_vars"
if [[ "$?" -ne "0" ]]; then
  echo "Unable to hook the agent to the project."
  exit 1
fi
