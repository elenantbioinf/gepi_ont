# gepi_ont
Gepi-ONT is a modular bioinformatics pipeline for reproducible haplotype-resolved genomic and epigenomic analysis of Oxford Nanopore Technologies (ONT) long-read data.

The pipeline is designed to process ONT BAM files and integrate multiple analysis layers, including quality control, BAM filtering, coverage assessment, duplicate marking, variant analysis, phasing, annotation, methylation extraction and methylation visualization.

## Pipeline Structure

The pipeline is organized into independent modules: 

```text
scripts/ 
├── 00_resources/ 
├── 01_initial_qc/ 
├── 02_filtering_and_qc/ 
├── 03_bam_comparison/ 
├── 04_coverage_gap/ 
├── 05_mark_duplicates/ 
├── 06_variant_calling/ 
├── 07_variant_phasing/ 
├── 08_annotation/ 
├── 09_methylation_extraction/ 
├── 10_methylation_visualization/ 
└── runner_pipeline_01_05.sh
```
Currently, the global runner is implemented for modules 01 to 05.

## Current workflow

The current runner executes the following modules: 

```text
- 01_initial_qc: initial quality control of raw BAM files
- 02_filtering_and_qc: BAM filtering and post-filtering quality control
- 03_bam_comparison: comparison of QC metrics before and after filtering
- 04_coverage_gap: coverage gap detection
- 05_mark_duplicates: duplicate marking with Picard MarkDuplicates
```

## Configuration

Project-specific paths and parameters are defined in:

config/project_config.sh

This file contains user-editable settings such as the working directory, raw BAM directory, resources directory, filtering parameters, coverage gap thresholds and module execution switches.

## Execution

The recommended execution mode is from the project root directory: 

```bash
bash scripts/runner_pipeline_01_05.sh -m path/to/manifest.tsv -c path/to/project_config.sh
```

The runner requieres: 
```text
-m  input manifest TSV file
-c  project configuration file
```
You can also see usage with: `-h`

## Configurable module execution

Modules 01 to 05 can be enabled or skipped from `project_config.sh` using boolean switches:

```text
#------------Module execution switches-----------
#Set each variable to true to run the module, or false to skip it.

RUN_MODULE_01_INITIAL_QC=true
RUN_MODULE_02_FILTERING_AND_QC=true
RUN_MODULE_03_BAM_COMPARISON=true
RUN_MODULE_04_COVERAGE_GAP=true
RUN_MODULE_05_MARK_DUPLICATES=true
```

Only exact values `true` and `false` are accepted.

## Output and logs

Pipeline results are written in `results/` directory. 
Module logs are written in `logs/` directory, and the global runner also creates an execution log in `logs/pipeline_executions/` with the date of execution.

## Reproducibility

This pipeline uses a central configuration file, sample manifest, modular scripts and isolated Conda evironments and Apptainer images to improve reproducibility and traceability across local and shared computational environments. 
The main runner executes the pipeline without manual step-by-step execution, improving automation and auditability of the workflow. Uers can select which modules are run through configurable execution switches, preserving user control over the workflow.

