#!/usr/bin/env bash

#This script haplotags the BAM file using the phased VCF from WhatsHap.

#Use: bash variant_haplotag_whatshap.sh -i <input_bam> -v <phased_vcf> -c <caller_name>

set -euo pipefail

#Inizializate variables to avoid error with set -u
INPUT_BAM=""
INPUT_VCF=""
CALLER_NAME=""

#Define usage of the script
usage () {
    echo "scripts/07_variant_phasing/variant_haplotag_whatshap.sh"
    echo ""
    echo "Usage: bash $0 -i <input_bam> -v <phased_vcf> -c <caller_name>"
    echo ""
    echo "Description:"
    echo "  Haplotag the BAM file using the phased VCF from WhatsHap."
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file (marked duplicates)"
    echo "  -v  Input phased VCF file (from WhatsHap)"
    echo "  -c  Variant caller name (e.g., clair3, deepvariant)"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:v:c:h" opt; do
    case "${opt}" in
        i ) INPUT_BAM="${OPTARG}"
            ;;
        v ) INPUT_VCF="${OPTARG}"
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
if [[ -z "${INPUT_BAM}" ]]; then
    echo "[ERROR] Missing required input BAM" >&2
    usage
    exit 1
fi

if [[ -z "${INPUT_VCF}" ]]; then
    echo "[ERROR] Missing required phased VCF" >&2
    usage
    exit 1
fi

if [[ -z "${CALLER_NAME}" ]]; then
    echo "[ERROR] Missing required caller name" >&2
    usage
    exit 1
fi

#Check caller name
case "${CALLER_NAME}" in
    clair3|deepvariant )
        ;;
    * )
        echo "[ERROR] Invalid caller name: ${CALLER_NAME}" >&2
        echo "[ERROR] Accepted values: clair3 or deepvariant" >&2
        exit 1
        ;;
esac

#Load project config
source "${GEPI_ONT_CONFIG:-config/project_config.sh}"

#Check if the required files exist
#Check input BAM
if [[ ! -s "${INPUT_BAM}" ]]; then
    echo "[ERROR] Input BAM not found or empty:"
    echo "[ERROR] ${INPUT_BAM}"
    exit 1
fi

#Check BAM index
if [[ ! -s "${INPUT_BAM}.bai" && \
      ! -s "${INPUT_BAM%.bam}.bai" ]]; then
    echo "[ERROR] BAM index not found for:"
    echo "[ERROR] ${INPUT_BAM}"
    exit 1
fi  

#Check input phased VCF
if [[ ! -s "${INPUT_VCF}" ]]; then
    echo "[ERROR] Input phased VCF not found or empty:"
    echo "[ERROR] ${INPUT_VCF}"
    exit 1
fi

#Check input phased VCF index
if [[ ! -s "${INPUT_VCF}.tbi" ]]; then
    echo "[ERROR] Phased VCF index not found for:"
    echo "[ERROR] ${INPUT_VCF}"
    exit 1
fi

#Check reference genome
if [[ ! -s "${REFERENCE_GENOME}" ]]; then
    echo "[ERROR] Reference genome not found or empty:"
    echo "[ERROR] ${REFERENCE_GENOME}"
    exit 1
fi

#check reference index
if [[ ! -s "${REFERENCE_GENOME}.fai" ]]; then
    echo "[ERROR] Reference genome index not found:"
    echo "[ERROR] ${REFERENCE_GENOME}.fai"
    exit 1
fi

#Sample name
SAMPLE_NAME="$(basename "$INPUT_VCF" _${CALLER_NAME}_phased.vcf.gz)"

#Output and logs
OUTPUT_DIR="${HAPLOTAGGED_RESULTS_DIR}/${CALLER_NAME}/${SAMPLE_NAME}"
HAPLOTAGGED_BAM="${OUTPUT_DIR}/${SAMPLE_NAME}_${CALLER_NAME}_haplotagged.bam"

#Logging
LOG_FILE="${VARIANT_PHASING_LOGS_DIR}/${CALLER_NAME}/${SAMPLE_NAME}_${CALLER_NAME}_whatshap_haplotag.log"

#Info messages
echo "###########################################"
echo "Running BAM haplotagging with WhatsHap"
echo "Sample: ${SAMPLE_NAME}"
echo "Caller: ${CALLER_NAME}"
echo "Input BAM: ${INPUT_BAM}"
echo "Input phased VCF: ${INPUT_VCF}"
echo "###########################################"

echo "Creating output and log directories if they don't exist..."

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "Executing WhatsHap..."
    
whatshap haplotag \
    --reference "$REFERENCE_GENOME" \
    --ignore-read-groups \
    -o "$HAPLOTAGGED_BAM" \
    --skip-missing-contigs \
    "$INPUT_VCF" \
    "$INPUT_BAM" \
    > "$LOG_FILE" 2>&1

echo "Indexing haplotagged BAM with samtools..."
samtools index "$HAPLOTAGGED_BAM" >> "$LOG_FILE" 2>&1

#Check if haplotagged BAM and index were created successfully
if [[ ! -s "$HAPLOTAGGED_BAM" || ! -s "${HAPLOTAGGED_BAM}.bai" ]]; then
    echo "[ERROR] Haplotagged BAM or its index not created successfully:"
    echo "[ERROR] ${HAPLOTAGGED_BAM}"
    exit 1
fi

#Final messages
echo "###########################################"
echo "Haplotagging completed"
echo "Sample: ${SAMPLE_NAME}"
echo "Input BAM: ${INPUT_BAM}"
echo "Input phased VCF: ${INPUT_VCF}"
echo "Haplotagged BAM: ${HAPLOTAGGED_BAM}"
echo "BAM index: ${HAPLOTAGGED_BAM}.bai"
echo "Log file: ${LOG_FILE}"
echo "###########################################"

