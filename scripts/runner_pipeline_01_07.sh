#!/usr/bin/env bash

#This is the runner of the pipeline.

#version: 2026/08/12

#Run gepi_ont pipeline from module 01 to module 07 using a manifest file.
#Each module is executed in its corresponding Conda environment.

#These modules include:
# - 01_initial_qc
# - 02_filtering_and_qc
# - 03_bam_comparison
# - 04_coverage_gap
# - 05_mark_duplicates
# - 06_variant_calling
# - 07_variant_phasing

#Manifest: sample_id<\t>bam_path

#Use: bash scripts/runner_pipeline_01_07.sh -m path/to/manifest.tsv -c path/to/config.sh

##################################################
################## INTRODUCTION ##################
##################################################

set -euo pipefail

#Initialize variables to avoid errors with set -u
MANIFEST=""
CONFIG=""

#Define usage
usage () {
    echo "scripts/runner_pipeline_01_07.sh"
    echo ""
    echo "Usage: bash $0 -m <manifest.tsv> -c <config.sh>"
    echo ""
    echo "Description:"
    echo "  Run Gepi-ONT modules 01 to 07 using a sample manifest and project configuration file."
    echo ""
    echo "Options:"
    echo "  -m  Input manifest TSV file with columns: sample_id and bam_path"
    echo "  -c  Project configuration file"
    echo "  -h  Display this help message and exit"
}

#Parse command-line options
while getopts ":m:c:h" opt; do
    case ${opt} in
        m ) MANIFEST="$OPTARG" ;;
        c ) CONFIG="$OPTARG" ;;
        h )
            usage
            exit 0
            ;;
        \? )
            echo "[ERROR] Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
        : )
            echo "[ERROR] Option -$OPTARG requires an argument." >&2
            usage
            exit 1
            ;;
    esac
done

#Check if required options are provided
if [[ -z "$MANIFEST" || -z "$CONFIG" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    usage
    exit 1
fi

#Check if the manifest file exists
if [[ ! -f "$MANIFEST" ]]; then
    echo "[ERROR] Manifest file not found: $MANIFEST"
    exit 1
fi

#Check if the config file exists
if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] Config file not found: $CONFIG"
    exit 1
fi

#Load project configuration
source "$CONFIG"

#Export config path for internal scripts
export GEPI_ONT_CONFIG="$CONFIG"

#Validate boolean configuration values
boolean_values () {
    local name="$1"
    local value="$2"
    if [[ "$value" != "true" && "$value" != "false" ]]; then
        echo "[ERROR] ${name} must be true or false. Current value (${value}) not valid"
        exit 1
    fi
}

boolean_values "RUN_MODULE_01_INITIAL_QC" "$RUN_MODULE_01_INITIAL_QC"
boolean_values "RUN_MODULE_02_FILTERING_AND_QC" "$RUN_MODULE_02_FILTERING_AND_QC"
boolean_values "RUN_MODULE_03_BAM_COMPARISON" "$RUN_MODULE_03_BAM_COMPARISON"
boolean_values "RUN_MODULE_04_COVERAGE_GAP" "$RUN_MODULE_04_COVERAGE_GAP"
boolean_values "RUN_MODULE_05_MARK_DUPLICATES" "$RUN_MODULE_05_MARK_DUPLICATES"
boolean_values "RUN_MODULE_06_VARIANT_CALLING" "$RUN_MODULE_06_VARIANT_CALLING"
boolean_values "RUN_CLAIR3" "$RUN_CLAIR3"
boolean_values "RUN_DEEPVARIANT" "$RUN_DEEPVARIANT"
boolean_values "RUN_VARIANT_FILTERING" "$RUN_VARIANT_FILTERING"
boolean_values "RUN_MODULE_07_VARIANT_PHASING" "$RUN_MODULE_07_VARIANT_PHASING"

#Create execution log
PIPELINE_EXECUTION_LOGS_DIR="${LOGS_DIR}/pipeline_executions"

mkdir -p "$PIPELINE_EXECUTION_LOGS_DIR"

PIPELINE_EXECUTION_LOG="${PIPELINE_EXECUTION_LOGS_DIR}/execution_$(date +%Y%m%d_%H%M%S).log"

#Redirect all pipeline execution output to both terminal and execution log
exec > >(tee -a "$PIPELINE_EXECUTION_LOG") 2>&1

#Terminal colors
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
YELLOW="\033[0;33m"
RESET="\033[0m"

#Initial info messages
echo -e "${YELLOW}"
echo "============================================================================="
echo "============================================================================="
echo -e "${MAGENTA}"
echo "      GGGGGG  EEEEEEE  PPPPPP   III          OOOOOOO  NNN    NN  TTTTTTTT"
echo "     GG       EE       PP   PP  III          OO   OO  NN N   NN     TT   "
echo "     GG GGGG  EEEEE    PPPPPP   III   =====  OO   OO  NN  N  NN     TT   "
echo "     GG   GG  EE       PP       III          OO   OO  NN   N NN     TT   "
echo "      GGGGG   EEEEEEE  PP       III          OOOOOOO  NN    NNN     TT   "
echo -e "${YELLOW}"
echo "      Gepi-ONT: a modular pipeline for reproducible haplotype-resolved"
echo "            genomic and epigenomic analysis of ONT long-read data"
echo ""
echo "============================================================================="
echo "============================================================================="
echo -e "${CYAN}"
echo "[INFO] Manifest: ${MANIFEST}"
echo "[INFO] Config: ${CONFIG}"
echo "[INFO] Pipeline directory: ${PIPELINE_DIR}"
echo "[INFO] Working directory: ${WORKDIR}"
echo "[INFO] Results directory: ${RESULTS_DIR}"
echo "[INFO] Logs directory: ${LOGS_DIR}"
echo "[INFO] Pipeline execution log: ${PIPELINE_EXECUTION_LOG}"
echo "[INFO] Processed BAM directory: ${PROCESSED_DATA_DIR}"
echo "[INFO] Execution: $(date +%Y%m%d_%H%M%S)"
echo ""
echo -e "${RESET}"

##################################################
################ READ THE MANIFEST ###############
##################################################

# Read the manifest line by line, skip the header, and extract SAMPLE_ID and BAM_PATH
tail -n +2 "$MANIFEST" | while IFS=$'\t' read -r SAMPLE_ID BAM_PATH; do
    
    #Check if the line is empty
    if [[ -z "${SAMPLE_ID:-}" ]]; then
        continue
    fi

    #Info messages
    echo ""
    echo "============================================================================="
    echo "                             START PIPELINE"
    echo "============================================================================="
    echo "[INFO] Processing sample: ${SAMPLE_ID}"
    echo "============================================================================="
    echo ""

    #Check if input BAM of $SAMPLE_ID exists
    if [[ ! -f "$BAM_PATH" ]]; then
        echo "[ERROR] Input BAM not found for ${SAMPLE_ID}:"
        echo "[ERROR] ${BAM_PATH}"
        exit 1
    fi

    #Check that $SAMPLE_ID and BAM name matches
    #This is for avoid errors like sample_id = paciente01 and bam_path = muestra1.bam
    BAM_BASENAME="$(basename "$BAM_PATH" .bam)"

    if [[ "$SAMPLE_ID" != "$BAM_BASENAME" ]]; then
        echo "[ERROR] sample_id does not match BAM basename"
        echo "[ERROR] sample_id: ${SAMPLE_ID}"
        echo "[ERROR] BAM basename: ${BAM_BASENAME}"
        echo "[ERROR] Please, check and match sample_id with the BAM filename without .bam"
        exit 1
    fi

    ##################################################
    ############### START THE ANALYSIS ###############
    ##################################################

    #=============MODULE 01: QC RAW FILES=============
    if [[ "$RUN_MODULE_01_INITIAL_QC" == true ]]; then
        echo ""
        echo "-----------------------------------------------------------------------------"
        echo "[MODULE 01] INITIAL QUALITY CONTROL FOR ${SAMPLE_ID}"
        echo "-----------------------------------------------------------------------------"
        echo ""

        #Initial QC
        conda run -n gepi_ont_qc \
            bash "${INITIAL_QC_SCRIPTS_DIR}/run_quality_control.sh" -i "$BAM_PATH" -m initial
    else
        echo "[SKIP] Skipping module 01: initial QC for ${SAMPLE_ID}"
    fi

    #===============MODULE 02: FILTERING AND QC===============
    FILTERED_BAM="${FILTERED_BAM_DIR}/${SAMPLE_ID}/${SAMPLE_ID}_filtered.bam"

    if [[ "$RUN_MODULE_02_FILTERING_AND_QC" == true ]]; then
        echo ""
        echo "-----------------------------------------------------------------------------"
        echo "[MODULE 02] FILTERING AND QC FOR ${SAMPLE_ID}"
        echo "-----------------------------------------------------------------------------"
        echo ""

        #Filtering step
        conda run -n bam_processing \
            bash "${FILTERING_AND_QC_SCRIPTS_DIR}/filter_bam.sh" -i "$BAM_PATH"

        #Check if filtered BAM and index exists
        if [[ ! -f "$FILTERED_BAM" ]]; then
            echo "[ERROR] Filtered BAM was not created:"
            echo "[ERROR] ${FILTERED_BAM}"
            exit 1
        fi

        if [[ ! -f "${FILTERED_BAM}.bai" ]]; then
            echo "[ERROR] Filtered BAM index was not created:"
            echo "[ERROR] ${FILTERED_BAM}.bai"
            exit 1
        fi

        #Post-filtering QC step
        conda run -n gepi_ont_qc \
            bash "${INITIAL_QC_SCRIPTS_DIR}/run_quality_control.sh" -i "$FILTERED_BAM" -m post_filtering
    else
        echo "[SKIP] Skipping module 02: filtering and QC for ${SAMPLE_ID}"
    fi

    #===============MODULE 03: BAM COMPARISON ===============
    if [[ "$RUN_MODULE_03_BAM_COMPARISON" == true ]]; then
        echo ""
        echo "-----------------------------------------------------------------------------"
        echo "[MODULE 03] COMPARISON OF QC BEFORE AND AFTER FILTERING FOR ${SAMPLE_ID}"
        echo "-----------------------------------------------------------------------------"
        echo ""

        conda run -n gepi_ont_qc \
            bash "${BAM_COMPARISON_SCRIPTS_DIR}/run_comparison.sh" -s "$SAMPLE_ID"
    else
        echo "[SKIP] Skipping module 03: BAM comparison for ${SAMPLE_ID}"
    fi

    
    #===============MODULE 04: COVERAGE GAP===============
    if [[ "$RUN_MODULE_04_COVERAGE_GAP" == true ]]; then
        echo ""
        echo "-----------------------------------------------------------------------------"
        echo "[MODULE 04] COVERAGE GAP ANALYSIS FOR ${SAMPLE_ID}"
        echo "-----------------------------------------------------------------------------"
        echo ""

        conda run -n coverage_gap \
            bash "${COVERAGE_GAP_SCRIPTS_DIR}/run_coverage_gap.sh" -s "$SAMPLE_ID"
    else
        echo "[SKIP] Skipping module 04: coverage gap analysis for ${SAMPLE_ID}"
    fi
    
    #===============MODULE 05: MARK DUPLICATES===============

    #Define MarkDuplicates output paths
    FILTERED_SAMPLE="$(basename "$FILTERED_BAM" .bam)"
    MARKDUP_DIR="${MARK_DUPLICATES_RESULTS_DIR}/${FILTERED_SAMPLE}"
    MARKDUP_BAM="${MARKDUP_DIR}/${FILTERED_SAMPLE}_markdup.bam"
    MARKDUP_BAI="${MARKDUP_DIR}/${FILTERED_SAMPLE}_markdup.bai"
    MARKDUP_METRICS="${MARKDUP_DIR}/${FILTERED_SAMPLE}_markdup_metrics.txt"

    if [[ "$RUN_MODULE_05_MARK_DUPLICATES" == true ]]; then
        echo ""
        echo "-----------------------------------------------------------------------------"
        echo "[MODULE 05] MARK DUPLICATES FOR ${SAMPLE_ID}"
        echo "-----------------------------------------------------------------------------"
        echo ""

        conda run -n mark_duplicates \
            bash "${MARK_DUPLICATES_SCRIPTS_DIR}/mark_duplicates.sh" -i "$FILTERED_BAM"

        #Check if MarkDuplicates outputs exist
        if [[ ! -f "$MARKDUP_BAM" ]]; then
            echo "[ERROR] MarkDuplicates BAM was not created:"
            echo "[ERROR] ${MARKDUP_BAM}"
            exit 1
        fi

        if [[ ! -f "$MARKDUP_BAI" ]]; then
            echo "[ERROR] MarkDuplicates BAM index was not created:"
            echo "[ERROR] ${MARKDUP_BAI}"
            exit 1
        fi    

        if [[ ! -f "$MARKDUP_METRICS" ]]; then
            echo "[ERROR] MarkDuplicates metrics file was not created:"
            echo "[ERROR] ${MARKDUP_METRICS}"
            exit 1
        fi
    else
        echo "[SKIP] Skipping module 05: mark duplicates for ${SAMPLE_ID}"
    fi

    #===============MODULE 06: VARIANT CALLING===============

    if [[ "$RUN_MODULE_06_VARIANT_CALLING" == true ]]; then
        echo ""
        echo "-----------------------------------------------------------------------------"
        echo "[MODULE 06] VARIANT CALLING FOR ${SAMPLE_ID}"
        echo "-----------------------------------------------------------------------------"
        echo ""

        #Check requiered inputs for variant calling
        if [[ ! -f "$MARKDUP_BAM" ]]; then
            echo "[ERROR] MarkDuplicates BAM not found for ${SAMPLE_ID}:"
            echo "[ERROR] ${MARKDUP_BAM}"
            exit 1
        fi
        if [[ ! -f "$MARKDUP_BAI" ]]; then
            echo "[ERROR] MarkDuplicates BAM index not found for ${SAMPLE_ID}:"
            echo "[ERROR] ${MARKDUP_BAI}"
            exit 1
        fi 

        VARIANT_SAMPLE="$(basename "$MARKDUP_BAM" .bam)"

        #Clair3
        if [[ "$RUN_CLAIR3" == true ]]; then
            
            conda run -n variant_calling \
                bash "${VARIANT_CALLING_SCRIPTS_DIR}/variant_calling_clair3.sh" -i "$MARKDUP_BAM"
            
            #Filter after clair3
            if [[ "$RUN_VARIANT_FILTERING" == true ]]; then

                CLAIR3_VCF="${CLAIR3_RESULTS_DIR}/${VARIANT_SAMPLE}/${VARIANT_SAMPLE}_clair3.vcf.gz"
                
                conda run -n variant_calling \
                    bash "${VARIANT_CALLING_SCRIPTS_DIR}/variant_filtering.sh" -i "$CLAIR3_VCF" -c clair3
            fi

        else
            echo "[SKIP] Skipping Clair3 variant calling for ${SAMPLE_ID}"
        fi

        #DeepVariant
        if [[ "$RUN_DEEPVARIANT" == true ]]; then
            
            conda run -n variant_calling \
                bash "${VARIANT_CALLING_SCRIPTS_DIR}/variant_calling_deepvariant.sh" -i "$MARKDUP_BAM"

            #Filter after deepvariant
            if [[ "$RUN_VARIANT_FILTERING" == true ]]; then
                DEEPVARIANT_VCF="${DEEPVARIANT_RESULTS_DIR}/${VARIANT_SAMPLE}/${VARIANT_SAMPLE}_deepvariant.vcf.gz"
                
                conda run -n variant_calling \
                    bash "${VARIANT_CALLING_SCRIPTS_DIR}/variant_filtering.sh" -i "$DEEPVARIANT_VCF" -c deepvariant
            fi

        else
            echo "[SKIP] Skipping DeepVariant variant calling for ${SAMPLE_ID}"
        fi

    else
        echo "[SKIP] Skipping module 06: variant calling for ${SAMPLE_ID}"
    fi
    
    #===============MODULE 07: VARIANT PHASING===============

    if [[ "$RUN_MODULE_07_VARIANT_PHASING" == true ]]; then
        echo ""
        echo "-----------------------------------------------------------------------------"
        echo "[MODULE 07] VARIANT PHASING FOR ${SAMPLE_ID}"
        echo "-----------------------------------------------------------------------------"
        echo ""

        #Define variant sample name
        VARIANT_SAMPLE="$(basename "$MARKDUP_BAM" .bam)"

        #Check requiered inputs for variant phasing
        if [[ ! -f "$MARKDUP_BAM" ]]; then
            echo "[ERROR] MarkDuplicates BAM not found for ${SAMPLE_ID}:"
            echo "[ERROR] ${MARKDUP_BAM}"
            exit 1
        fi
        if [[ ! -f "$MARKDUP_BAI" ]]; then
            echo "[ERROR] MarkDuplicates BAM index not found for ${SAMPLE_ID}:"
            echo "[ERROR] ${MARKDUP_BAI}"
            exit 1
        fi 

        #Clair 3 phasing and haplotagging
        if [[ "$RUN_CLAIR3" == true ]]; then

            #Define and check Clair3 VCF and index paths
            CLAIR3_PASS_VCF="${VARIANT_FILTERING_RESULTS_DIR}/clair3/${VARIANT_SAMPLE}/${VARIANT_SAMPLE}_clair3_pass.vcf.gz"
            CLAIR3_PASS_VCF_TBI="${CLAIR3_PASS_VCF}.tbi"   

            if [[ ! -f "$CLAIR3_PASS_VCF" || ! -f "$CLAIR3_PASS_VCF_TBI" ]]; then
                echo "[ERROR] Clair3 VCF or index not found for ${SAMPLE_ID}:"
                echo "[ERROR] ${CLAIR3_PASS_VCF}"
                echo "[ERROR] ${CLAIR3_PASS_VCF_TBI}"
                exit 1
            fi

            #Run variant phasing
            conda run -n variant_phasing \
                bash "${VARIANT_PHASING_SCRIPTS_DIR}/variant_phasing_whatshap.sh" \
                    -i "$MARKDUP_BAM" \
                    -v "$CLAIR3_PASS_VCF" \
                    -c clair3

            #Define phased VCF and index paths
            CLAIR3_PHASED_VCF="${PHASED_RESULTS_DIR}/clair3/${VARIANT_SAMPLE}/${VARIANT_SAMPLE}_clair3_phased.vcf.gz"

            #Run haplotagging
            conda run -n variant_phasing \
                bash "${VARIANT_PHASING_SCRIPTS_DIR}/variant_haplotag_whatshap.sh" \
                    -i "$MARKDUP_BAM" \
                    -v "$CLAIR3_PHASED_VCF" \
                    -c clair3   

        else
            echo "[SKIP] Skipping variant phasing and haplotagging for ${SAMPLE_ID}_clair3"
        fi

        #DeepVariant phasing and haplotagging
        if [[ "$RUN_DEEPVARIANT" == true ]]; then

            #Define and check DeepVariant VCF and index paths
            DEEPVARIANT_PASS_VCF="${VARIANT_FILTERING_RESULTS_DIR}/deepvariant/${VARIANT_SAMPLE}/${VARIANT_SAMPLE}_deepvariant_pass.vcf.gz"
            DEEPVARIANT_PASS_VCF_TBI="${DEEPVARIANT_PASS_VCF}.tbi"

            if [[ ! -f "$DEEPVARIANT_PASS_VCF" || ! -f "$DEEPVARIANT_PASS_VCF_TBI" ]]; then
                echo "[ERROR] DeepVariant VCF or index not found for ${SAMPLE_ID}:"
                echo "[ERROR] ${DEEPVARIANT_PASS_VCF}"
                echo "[ERROR] ${DEEPVARIANT_PASS_VCF_TBI}"
                exit 1
            fi

            #Run variant phasing
            conda run -n variant_phasing \
                bash "${VARIANT_PHASING_SCRIPTS_DIR}/variant_phasing_whatshap.sh" \
                    -i "$MARKDUP_BAM" \
                    -v "$DEEPVARIANT_PASS_VCF" \
                    -c deepvariant
        
            #Define and check phased VCF and index paths
            DEEPVARIANT_PHASED_VCF="${PHASED_RESULTS_DIR}/deepvariant/${VARIANT_SAMPLE}/${VARIANT_SAMPLE}_deepvariant_phased.vcf.gz"
            
            #Run haplotagging
            conda run -n variant_phasing \
                bash "${VARIANT_PHASING_SCRIPTS_DIR}/variant_haplotag_whatshap.sh" \
                    -i "$MARKDUP_BAM" \
                    -v "$DEEPVARIANT_PHASED_VCF" \
                    -c deepvariant
        else
            echo "[SKIP] Skipping  variant phasing and haplotagging for ${SAMPLE_ID}_deepvariant"
        fi

    else
        echo "[SKIP] Skipping module 07: variant phasing for ${SAMPLE_ID}"
    fi

done

#Final messages
echo ""
echo "============================================================================="
echo "                             PIPELINE FINISHED"
echo "============================================================================="
echo ""
echo "[INFO] Pipeline execution finished for all samples in:"
echo "[INFO] ${MANIFEST}"
echo "[INFO] Modules were executed according to:"
echo "[INFO] ${CONFIG}"
echo ""