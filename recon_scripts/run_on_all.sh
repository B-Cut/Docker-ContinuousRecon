#!/bin/bash

MODE=$1
TARGETS_FILE_PATH=$2
SCRIPT_TO_USE=""

# We assume we are running in the container
FULL_PIPELINE_SCRIPT_PATH="/recon_scripts/pipeline.sh"
BASIC_PIPELINE_SCRIPT_PATH="/recon_scripts/basic_subdomain_enumeration.sh"

case $MODE in
    full)
        SCRIPT_TO_USE=$FULL_PIPELINE_SCRIPT_PATH
        ;;
    basic)
        SCRIPT_TO_USE=$BASIC_PIPELINE_SCRIPT_PATH
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

if [[ $# -ne 2 ]]; then
    echo "Error: 2 arguments expected, $# received"
    echo "Usage: $0 <full|basic|help> <targets_file_path>"
    exit 1
fi

touch recon_lock
while IFS= read -r line; do
    echo "====================== Scanning $line ============================="
    /bin/bash $SCRIPT_TO_USE $line
done < "$TARGETS_FILE_PATH"
rm recon_lock