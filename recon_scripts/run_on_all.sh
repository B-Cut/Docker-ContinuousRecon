#!/bin/bash

MODE=$1
TARGETS_FILE_PATH=$2
SCRIPT_TO_USE=""

# We assume we are running in the container
FULL_PIPELINE_SCRIPT_PATH="/recon_scripts/pipeline.sh"
BASIC_PIPELINE_SCRIPT_PATH="/recon_scripts/basic_subdomain_enumeration.sh"

case $MODE in
    full)
        $SCRIPT_TO_USE=$FULL_PIPELINE_SCRIPT_PATH
        ;;
    basic)
        $SCRIPT_TO_USE=$BASIC_PIPELINE_SCRIPT_PATH
        ;;
    help)
        echo "Usage: $0 <full|basic|help> <targets_file_path>"
        exit 0
        ;;
    *)
        echo "Unrecognized option: $MODE"
        echo "Valid options: full, basic, help"
        exit 0
        ;;
esac

if [[ $# -ne 3 ]]; then
    echo "Error: 2 arguments expected, $# received"
    echo "Usage: $0 <full|basic|help> <targets_file_path>"
    exit 1



touch recon_lock
while IFS= read -r domain; do
    /bin/bash $SCRIPT_TO_USE $domain
done < $TARGETS_FILE_PATH
rm recon_lock