#!/bin/bash

set -e

if [[ -z "$1" ]]
then
  echo "Usage: generate-index.sh <googleapis directory>"
  exit 1
fi

GOOGLEAPIS=$1

SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
REPO_ROOT=$(realpath "$SCRIPT_DIR/..")

cd $REPO_ROOT

source $SCRIPT_DIR/toolfunctions.sh

rm -rf tmp
mkdir tmp

echo "-I$PROTOBUF_ROOT/include" > tmp/protoc-options.txt
echo "-I$GOOGLEAPIS" >> tmp/protoc-options.txt
echo "--include_imports" >> tmp/protoc-options.txt
echo "--descriptor_set_out=tmp/all-protos.ds" >> tmp/protoc-options.txt
echo "--experimental_allow_proto3_optional" >> tmp/protoc-options.txt
find $GOOGLEAPIS/google -name '*.proto' >> tmp/protoc-options.txt
find $GOOGLEAPIS/grafeas -name '*.proto' >> tmp/protoc-options.txt

echo "Generating descriptor set."
# Generate the descriptor set, but ignore import warnings (and
# ignore the exit code of grep).
$PROTOC @tmp/protoc-options.txt 2>&1 | \
  grep -v -E "Import [^ ]* is unused." || true

# Arguments to generator:
# - Descriptor set
# - googleapis directory to find service config files
# - Output directory
echo "Generating index."
dotnet run -p src/Google.Cloud.Tools.ApiIndexGenerator -- tmp/all-protos.ds $GOOGLEAPIS tmp

echo "Done."
