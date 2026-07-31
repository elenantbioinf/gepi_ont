# Configuration

This directory contains configuration files used to parameterize the analysis.

## Configuration files

Paths to large input files and external resources are environment-specific. Before running the pipeline on another system, review the user-editable section of the selected configuration file and update:

```text
WORKDIR
RAW_BAM_DIR
RESOURCES_DIR
REFERENCE_GENOME
```

You can also configure other settings, such as which modules to execute, BAM filtering parameters, or coverage-gap thresholds.

### `project_config.sh`

Example of configuration file for the Gepi-ONT pipeline.

It defines:

- Pipeline and working directories
- Input BAM directory
- Resources directory
- Module execution switches
- BAM filtering parameters
- Coverage-gap thresholds
- Internal paths for scripts, results, logs, and processed data

### `project_config_giab_chr22.sh`

Configuration profile used to validate modules 01 to 05 with the GIAB chr22 dataset.

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

Each `sample_id` must match the corresponding BAM filename without the .bam extension.

### `manifest.tsv`

Example of a sample manifest used for standard pipeline executions.

### `manifest_giab_chr22.tsv`

Sample manifest used for the GIAB chr22 validation.

Input BAMs are stored outside the repository and are configured using absolute paths.