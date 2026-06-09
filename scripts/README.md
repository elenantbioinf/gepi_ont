# Scripts

This directory contains all analysis scripts used in the project.

Scripts are organized by pipeline module:

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
└── runner_pipeline_01_04.sh
```

## Configuration

Scripts load the project configuration using: 

```bash
source "${MET_ONT_CONFIG:-config/project_config.sh}"
```

This allows scripts to use the config path exported by the runner, while keeping `config/project_config.sh` as the default for individual script execution.

## Execution 

The recommended execution mode is from the project root directory.

```bash
cd path/to/met_ont/
```

If the runner is launched from outside the project root, absolute paths should be used when calling the runner, manifest and config file, and also inside the manifest for input BAM files. Internal config variables derived from `WORKDIR`, `RAW_BAM_DIR` and `RESOURCES_DIR` should not be manually edited.

## Current runner

The current runner executes modules 01 to 03 using a manifest file and a config file:

```bash
bash scripts/runner_pipeline_01_04.sh config/manifest.tsv config/project_config.sh
```

The manifest must be tab-separated and `sample_id` must match the BAM filename without .bam.

```text
sample_id	bam_path
muestra1	data/raw/muestra1.bam
muestra2	data/raw/muestra2.bam
```


