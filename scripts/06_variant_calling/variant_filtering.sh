#!/usr/bin/env bash

#This script filters the variants based on PASS status.

#Use: bash variant_filtering.sh -i <input_vcf.gz> -c <caller_name>

set -euo pipefail

#Inizializate variables to avoid error with set -u
INPUT_VCF=""
CALLER_NAME=""

#Define usage of the script
usage () {
    echo "scripts/06_variant_calling/variant_filtering.sh"
    echo ""
    echo "Usage: bash $0 -i <input_vcf.gz> -c <caller_name>"
    echo ""
    echo "Description:"
    echo "  Filter variants from a VCF file based on PASS status."
    echo ""
    echo "Options:"
    echo "  -i  Input VCF file (bgzipped and indexed)"
    echo "  -c  Name of the variant caller (clair3 or deepvariant)"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:c:h" opt; do
    case "${opt}" in
        i ) INPUT_VCF="${OPTARG}"
            ;;
        c ) CALLER_NAME="${OPTARG}"
            ;;
        h ) usage
            exit 0
            ;;
        \? )
            echo "[ERROR] Invalid option: -${OPTARG}" >&2
            usage
            exit 1
            ;;
        : )
            echo "[ERROR] Option -${OPTARG} requires an argument." >&2
            usage
            exit 1
            ;;
    esac
done

#Check if the required arguments are provided
if [[ -z "${INPUT_VCF}" ]]; then
    echo "[ERROR] Missing required input VCF" >&2
    usage
    exit 1
fi

if [[ -z "${CALLER_NAME}" ]]; then
    echo "[ERROR] Missing required caller name" >&2
    usage
    exit 1
fi

#Load project config
source "${GEPI_ONT_CONFIG:-config/project_config.sh}"

#Check if the required files exist
if [[ ! -s "${INPUT_VCF}" ]]; then
    echo "[ERROR] Input VCF not found or empty:"
    echo "[ERROR] ${INPUT_VCF}"
    exit 1
fi

#Check caller name
case "${CALLER_NAME}" in
    clair3|deepvariant )
        ;;
    *)  echo "[ERROR] Invalid caller name: ${CALLER_NAME}" >&2
        echo "[ERROR] Must be 'clair3' or 'deepvariant'." >&2
        exit 1
        ;;
esac

#Sample name
SAMPLE="$(basename "$INPUT_VCF" _${CALLER_NAME}.vcf.gz)"

#Output and log directories
OUTPUT_DIR="${VARIANT_FILTERING_RESULTS_DIR}/${CALLER_NAME}/${SAMPLE}"
LOG_DIR="${VARIANT_FILTERING_LOGS_DIR}/${CALLER_NAME}/${SAMPLE}"


OUTPUT_VCF="${OUTPUT_DIR}/${SAMPLE}_${CALLER_NAME}_pass.vcf.gz"
LOG="${LOG_DIR}/${SAMPLE}_${CALLER_NAME}_pass.log"

#Skip execution if output already exists
if [[ -s "$OUTPUT_VCF" && -s "${OUTPUT_VCF}.tbi" ]]; then
    echo "[INFO] Output VCF and index already exist. Skipping filtering."
    echo "[INFO] Output VCF: $OUTPUT_VCF"
    echo "[INFO] Index: ${OUTPUT_VCF}.tbi"
    exit 0
fi

#Information
echo "###########################################"
echo "Filtering variants based on PASS status"
echo "Sample: ${SAMPLE}"
echo "Caller: ${CALLER_NAME}"
echo "Input VCF: ${INPUT_VCF}"
echo "###########################################"

#Create directories if they don't exist
echo "Creating output and log directories if they don't exist..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

#BCFTools execution
echo "Filtering PASS variants from ${INPUT_VCF}..."
bcftools view \
    -f PASS \
    -Oz \
    -o "${OUTPUT_VCF}" \
    "${INPUT_VCF}" \
    2> "${LOG}"

#BCFTools indexing
echo "Indexing filtered VCF..."
bcftools index -t "${OUTPUT_VCF}" 2>> "${LOG}"

#Check if the output VCF and index were created successfully
if [[ ! -s "${OUTPUT_VCF}" || ! -s "${OUTPUT_VCF}.tbi" ]]; then
    echo "[ERROR] Filtering failed or output files not created." >&2
    echo "[ERROR] Check the log: $LOG" >&2
    exit 1
fi

#Final message
echo "###########################################"
echo "Variants filtered successfully based on PASS status."
echo "PASS variants saved to $OUTPUT_VCF."
echo "Index: ${OUTPUT_VCF}.tbi."
echo "Log saved to $LOG."
echo "###########################################"