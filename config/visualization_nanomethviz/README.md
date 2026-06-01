# NanoMethViz visualization configuration

This directory contains configuration files used by the NanoMethViz visualization workflow.

Files:

- `samples.tsv`: sample metadata table used by NanoMethViz. It defines sample name, group, caller and path to the haplotagged BAM file.
- `nanomethviz_targets.tsv`: target table used to define genes and genomic regions to visualize.

These files are specific to the methylation visualization module and are used by scripts in:

`scripts/10_methylation_visualization/nanomethviz_plots/`