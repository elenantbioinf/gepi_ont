#!/usr/bin/env bash

#This script performs variant calling using DeepVariant on BAM files.

#Use: bash variant_calling_deepvariant.sh -i <input.bam>

set -euo pipefail

#Inizializate variables to avoid error with set -u
INPUT_BAM=""

#Define usage of the script
usage () {
    echo "scripts/06_variant_calling/variant_calling_deepvariant.sh"
    echo ""
    echo "Usage: bash $0 -i <input.bam>"
    echo ""
    echo "Description:"
    echo "  Run DeepVariant for germline SNV/indel calling on an indexed ONT BAM file."
    echo ""
    echo "Options:"
    echo "  -i  Input BAM file"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":i:h" opt; do
    case "${opt}" in
        i ) INPUT_BAM="${OPTARG}"
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

#Check if the input BAM file is provided
if [[ -z "$INPUT_BAM" ]]; then
    echo "[ERROR] Input BAM file is required." >&2
    usage
    exit 1
fi

#Load project config
source "${GEPI_ONT_CONFIG:-config/project_config.sh}"

#Check if the required files exists 
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

#Check reference genome
if [[ ! -s "${REFERENCE_GENOME}" ]]; then
    echo "[ERROR] Reference genome not found or empty:"
    echo "[ERROR] ${REFERENCE_GENOME}"
    exit 1
fi

#Check reference index
if [[ ! -s "${REFERENCE_GENOME}.fai" ]]; then
    echo "[ERROR] Reference genome index not found:"
    echo "[ERROR] ${REFERENCE_GENOME}.fai"
    exit 1
fi

#Check DeepVariant container
if [[ ! -s "${DEEPVARIANT_CONTAINER}" ]]; then
    echo "[ERROR] DeepVariant container not found:"
    echo "[ERROR] ${DEEPVARIANT_CONTAINER}"
    exit 1
fi

#Check if Apptainer is installed
if ! command -v apptainer > /dev/null 2>&1; then
    echo "[ERROR] Apptainer is not installed. Please install Apptainer to run DeepVariant." >&2
    exit 1
fi

#Sample name
SAMPLE="$(basename "$INPUT_BAM" .bam)"

#Outputs and logs
OUTDIR="${DEEPVARIANT_RESULTS_DIR}/${SAMPLE}"
INTERMEDIATE_DIR="${OUTDIR}/intermediate_files"

LOG="${DEEPVARIANT_LOGS_DIR}/${SAMPLE}_deepvariant.log"

FINAL_VCF="${OUTDIR}/${SAMPLE}_deepvariant.vcf.gz"
FINAL_GVCF="${OUTDIR}/${SAMPLE}_deepvariant.g.vcf.gz"
FINAL_TBI="${FINAL_VCF}.tbi"
FINAL_GVCF_TBI="${FINAL_GVCF}.tbi"

# Skip execution if final output already exists
if [[ -s "$FINAL_VCF" && -s "$FINAL_TBI" ]]; then
    if [[ "$DEEPVARIANT_OUTPUT_GVCF" != "true" ]] || \
       [[ -s "$FINAL_GVCF" && -s "$FINAL_GVCF_TBI" ]]; then
        echo "[SKIP] DeepVariant results already exist:"
        echo "[SKIP] $FINAL_VCF"
        exit 0
    fi
fi

#Convert the BAM argument to an absolute path to avoid issues with Apptainer's working directory
INPUT_BAM="$(realpath "$INPUT_BAM")"

INPUT_BAM_DIR="$(dirname "$INPUT_BAM")"
REFERENCE_DIR="$(dirname "$REFERENCE_GENOME")"

#Build Deepvariant arguments
DEEPVARIANT_ARGS=(
    /opt/deepvariant/bin/run_deepvariant
    --model_type="${DEEPVARIANT_MODEL_TYPE}"
    --ref="${REFERENCE_GENOME}"
    --reads="${INPUT_BAM}"
    --output_vcf="${FINAL_VCF}"
    --intermediate_results_dir="${INTERMEDIATE_DIR}"
    --num_shards="${DEEPVARIANT_THREADS}"
)

#Choose the command to run based on the boolean variables in the config file
if [[ "${DEEPVARIANT_REGIONS}" != "" ]]; then
    DEEPVARIANT_ARGS+=("--regions=${DEEPVARIANT_REGIONS}")
fi

if [[ "${DEEPVARIANT_VCF_STATS_REPORT}" == "true" ]]; then
    DEEPVARIANT_ARGS+=("--vcf_stats_report=true")
fi

if [[ "${DEEPVARIANT_OUTPUT_GVCF}" == "true" ]]; then
    DEEPVARIANT_ARGS+=("--output_gvcf=${FINAL_GVCF}")
fi

#Information
echo "###########################################"
echo "Running DeepVariant"
echo "Sample: ${SAMPLE}"
echo "Input BAM: ${INPUT_BAM}"
echo "Reference: ${REFERENCE_GENOME}"
echo "Model: ${DEEPVARIANT_MODEL_TYPE}"
echo "Threads: ${DEEPVARIANT_THREADS}"
if [[ "${DEEPVARIANT_REGIONS}" != "" ]]; then
    echo "Regions: ${DEEPVARIANT_REGIONS}"
fi
echo "Output directory: ${OUTDIR}"
echo "Log: ${LOG}"
echo "###########################################"

#Create directories
echo "Creating output directory for DeepVariant results if it doesn't exist..."
mkdir -p "$DEEPVARIANT_RESULTS_DIR"
mkdir -p "$OUTDIR"
mkdir -p "$INTERMEDIATE_DIR"
mkdir -p "$DEEPVARIANT_LOGS_DIR"

#Run DeepVariant using Apptainer
echo "Executing DeepVariant..."
apptainer run \
    -B "$INPUT_BAM_DIR":"$INPUT_BAM_DIR" \
    -B "$REFERENCE_DIR":"$REFERENCE_DIR" \
    -B "${OUTDIR}:${OUTDIR}" \
    -B /tmp:/tmp \
    "$DEEPVARIANT_CONTAINER" \
    "${DEEPVARIANT_ARGS[@]}" \
    > "$LOG" 2>&1

#Check if required VCF outputs exist
echo "Checking if DeepVariant generated the expected output files..."
if [[ ! -s "$FINAL_VCF" || ! -s "$FINAL_TBI" ]]; then
    echo "[ERROR] DeepVariant did not generate the expected VCF and index." >&2
    echo "[ERROR] Check the log: $LOG" >&2
    exit 1
fi

#Check optional gVCF outputs
if [[ "$DEEPVARIANT_OUTPUT_GVCF" == "true" ]]; then
    if [[ ! -s "$FINAL_GVCF" || ! -s "$FINAL_GVCF_TBI" ]]; then
        echo "[ERROR] DeepVariant did not generate the requested gVCF and index." >&2
        echo "[ERROR] Check the log: $LOG" >&2
        exit 1
    fi
fi

echo "###########################################"
echo "DeepVariant run complete."
echo "Results saved to $FINAL_VCF."
if [[ "$DEEPVARIANT_OUTPUT_GVCF" == "true" ]]; then
    echo "gVCF: $FINAL_GVCF"
fi
echo "Log saved to $LOG."
echo "###########################################"
