# Configuration

This directory contains configuration files used to parameterize the analysis.

## Configuration files

Paths to large input files and external resources are environment-specific. Before running the pipeline on another system, review the user-editable section of the selected configuration file and update:

`WORKDIR`: In this directory will be stored the results, logs and data/processed when the pipeline be executed.
`RAW_BAM_DIR`: Directory containing the original BAM files. They will not be modified during execution.
`RESOURCES_DIR`: Directory containing the resources required by the pipeline. By default, it will be located inside `PIPELINE_DIR`. 
`REFERENCE_GENOME`: Path to thereference genome FASTA file. By default, it will be located inside `RESOURCES_DIR`.

You can also configure other settings, such as which modules to execute, BAM filtering parameters, or coverage-gap thresholds.

Modules can be enabled or skipped independently with boolean values:

```bash
RUN_MODULE_01_INITIAL_QC=true
RUN_MODULE_02_FILTERING_AND_QC=true
RUN_MODULE_03_BAM_COMPARISON=true
RUN_MODULE_04_COVERAGE_GAP=true
RUN_MODULE_05_MARK_DUPLICATES=true
RUN_MODULE_06_VARIANT_CALLING=true
RUN_MODULE_07_VARIANT_PHASING=true
```

Variant callers and PASS filtering are controlled separately:

```bash
RUN_CLAIR3=true
RUN_DEEPVARIANT=true
RUN_VARIANT_FILTERING=true
```

### `project_config.sh`

Example of configuration file for the Gepi-ONT pipeline (current version: Modules 01 to 07; 2026-08-12)

It defines:

- Pipeline and working directories
- Input BAM directory
- Resources directory
- Module execution switches
- BAM filtering parameters
- Coverage-gap thresholds
- Internal paths for scripts, results, logs, and processed data

### `project_config_giab_chr22.sh`

Configuration profile used to validate modules 01 to 07 with the GIAB chr22 dataset.

The validation uses:

- Six GIAB samples: `HG002`, `HG003`, `HG004`, `HG005`, `HG006`, and `HG007`
- Merged BAM files containing chromosome 22
- Two ONT flowcells merged per sample
- A dedicated working directory in the user's home directory
- The exact GRCh38 reference associated with the GIAB BAM files:
    `GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta`

Input BAMs and the reference genome are stored outside the repository and are configured using absolute paths.

## Manifest files

The manifest contains two tab-separated columns:

```text
sample_id	bam_path
```

Each `sample_id` must match the corresponding BAM filename without the `.bam` extension.

### `manifest.tsv`

Example of a sample manifest used for standard pipeline executions.

### `manifest_giab_chr22.tsv`

Sample manifest used for the GIAB chr22 validation.

Input BAMs are stored outside the repository and are configured using absolute paths.