#!/usr/bin/env python3

#This script compares QC metrics between different BAM files

# Use: python compare_qc.py <sample_name> <results_dir> <output_dir>


###########################
####### PREPARATION #######
###########################

#Import necessary libraries
import sys
import os

#Define input arguments
sample_name = sys.argv[1]
results_dir = sys.argv[2]
output_dir = sys.argv[3]

#Define samples names and QC directories
filtered_sample_name = f"{sample_name}_filtered"

raw_qc_dir = f"{results_dir}/01_initial_qc/{sample_name}"
post_filtering_qc_dir = f"{results_dir}/02_post_filtering_qc/{filtered_sample_name}"

#Create output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

#Info message of starting QC comparison
print(f"[INFO] Starting QC comparison for sample: {sample_name}")
print(f"[INFO] Raw QC directory: {raw_qc_dir}")
print(f"[INFO] Post-filtering QC directory: {post_filtering_qc_dir}")
print(f"[INFO] Output directory: {output_dir}")

###########################
### FLAGSTAT COMPARISON ###
###########################

#Define paths to flagstat files and output flagstat TSV file
raw_flagstat = f"{raw_qc_dir}/samtools/{sample_name}_flagstat.txt"
filtered_flagstat = f"{post_filtering_qc_dir}/samtools/{filtered_sample_name}_flagstat.txt"

flagstat_output_tsv = f"{output_dir}/{sample_name}_flagstat_comparison.tsv"

#Define a function to extract relevant metrics from flagstat output
def extract_flagstat_metrics(flagstat_file):
    metrics = {
        "total": "",
        "mapped": "",
        "primary": "",
        "secondary": "",
        "supplementary": ""
    }
    with open(flagstat_file, 'r') as f:
        for line in f:
            line = line.strip()
            if 'in total' in line:
                metrics['total'] = int(line.split()[0])
            elif 'mapped (' in line and 'primary' not in line:
                metrics['mapped'] = int(line.split()[0])
            elif line.endswith(" primary"):
                metrics['primary'] = int(line.split()[0])
            elif line.endswith(" secondary"):
                metrics['secondary'] = int(line.split()[0])
            elif line.endswith(" supplementary"):
                metrics['supplementary'] = int(line.split()[0])
    return metrics

#Extract metrics from both flagstat files
raw_metrics = extract_flagstat_metrics(raw_flagstat)
filtered_metrics = extract_flagstat_metrics(filtered_flagstat)

#Create a table to compare the flagstat metrics and save to a TSV file
with open(flagstat_output_tsv, "w") as out:
    out.write("sample\tstate\ttotal\tmapped\tprimary\tsecondary\tsupplementary\n")
    out.write(
        f"{sample_name}\traw\t{raw_metrics['total']}\t{raw_metrics['mapped']}\t{raw_metrics['primary']}\t{raw_metrics['secondary']}\t{raw_metrics['supplementary']}\n"
    )
    out.write(
        f"{sample_name}\tfiltered\t{filtered_metrics['total']}\t{filtered_metrics['mapped']}\t{filtered_metrics['primary']}\t{filtered_metrics['secondary']}\t{filtered_metrics['supplementary']}\n"
    )

#Info message of finished flagstat comparison
print("Flagstat comparison completed.")
print(f"Flagstat comparison file: {flagstat_output_tsv}")


###########################
#### STATS COMPARISON ####
###########################

#Define paths to stats files and output stats TSV file
raw_stats = f"{raw_qc_dir}/samtools/{sample_name}_stats.txt"
filtered_stats = f"{post_filtering_qc_dir}/samtools/{filtered_sample_name}_stats.txt"

stats_output_tsv = f"{output_dir}/{sample_name}_stats_comparison.tsv"

#Define a function to extract relevant metrics from stats output
def extract_stats_metrics(stats_file):
    metrics = {
        "reads_mapped": "",
        "reads_MQ0": "",
        "non_primary_alignments": "",
        "supplementary_alignments": "",
        "bases_mapped_cigar": "",
        "error_rate": "",
        "average_length": "",
        "maximum_length": ""
    }

    with open(stats_file, "r") as f:
        for line in f:
            line = line.strip()

            if not line.startswith("SN"):
                continue

            if "reads mapped:" in line and "paired" not in line:
                metrics["reads_mapped"] = int(line.split("\t")[2])
            elif "reads MQ0:" in line:
                metrics["reads_MQ0"] = int(line.split("\t")[2])
            elif "non-primary alignments:" in line:
                metrics["non_primary_alignments"] = int(line.split("\t")[2])
            elif "supplementary alignments:" in line:
                metrics["supplementary_alignments"] = int(line.split("\t")[2])
            elif "bases mapped (cigar):" in line:
                metrics["bases_mapped_cigar"] = int(line.split("\t")[2])
            elif "error rate:" in line:
                metrics["error_rate"] = float(line.split("\t")[2])
            elif "average length:" in line and "first fragment" not in line and "last fragment" not in line:
                metrics["average_length"] = int(line.split("\t")[2])
            elif "maximum length:" in line and "first fragment" not in line and "last fragment" not in line:
                metrics["maximum_length"] = int(line.split("\t")[2])

    return metrics

#Extract metrics from both stats files
raw_stats_metrics = extract_stats_metrics(raw_stats)
filtered_stats_metrics = extract_stats_metrics(filtered_stats)

#Create a table to compare the stats metrics and save to a TSV file
with open(stats_output_tsv, "w") as out:
    out.write("sample\tstate\treads_mapped\treads_MQ0\tnon_primary_alignments\tsupplementary_alignments\tbases_mapped_cigar\terror_rate\taverage_length\tmaximum_length\n")
    out.write(
        f"{sample_name}\traw\t{raw_stats_metrics['reads_mapped']}\t{raw_stats_metrics['reads_MQ0']}\t{raw_stats_metrics['non_primary_alignments']}\t{raw_stats_metrics['supplementary_alignments']}\t{raw_stats_metrics['bases_mapped_cigar']}\t{raw_stats_metrics['error_rate']}\t{raw_stats_metrics['average_length']}\t{raw_stats_metrics['maximum_length']}\n"
    )
    out.write(
        f"{sample_name}\tfiltered\t{filtered_stats_metrics['reads_mapped']}\t{filtered_stats_metrics['reads_MQ0']}\t{filtered_stats_metrics['non_primary_alignments']}\t{filtered_stats_metrics['supplementary_alignments']}\t{filtered_stats_metrics['bases_mapped_cigar']}\t{filtered_stats_metrics['error_rate']}\t{filtered_stats_metrics['average_length']}\t{filtered_stats_metrics['maximum_length']}\n"
    )

#Info message of finished stats comparison
print("Stats comparison completed.")
print(f"Stats comparison file: {stats_output_tsv}")

###########################
### MOSDEPTH COMPARISON ###
###########################

#Define paths to mosdepth summary files and output mosdepth TSV file
raw_mosdepth_summary = f"{raw_qc_dir}/mosdepth/{sample_name}.mosdepth.summary.txt"
filtered_mosdepth_summary = f"{post_filtering_qc_dir}/mosdepth/{filtered_sample_name}.mosdepth.summary.txt"

mosdepth_output_tsv = f"{output_dir}/{sample_name}_mosdepth_comparison.tsv"

#Define a function to extract relevant metrics from mosdepth summary output
def extract_mosdepth_summary_metrics(mosdepth_file):
    metrics = []

    with open(mosdepth_file, "r") as f:
        for line in f:
            line = line.strip()

            if line.startswith("chrom"):
                continue

            fields = line.split("\t")
            metrics.append({
                "region": fields[0],
                "length": int(fields[1]),
                "bases": int(fields[2]),
                "mean_coverage": float(fields[3]),
                "min_coverage": int(fields[4]),
                "max_coverage": int(fields[5]),
            })

    return metrics

#Extract metrics from both mosdepth summary files
raw_mosdepth_metrics = extract_mosdepth_summary_metrics(raw_mosdepth_summary)
filtered_mosdepth_metrics = extract_mosdepth_summary_metrics(filtered_mosdepth_summary)

#Create a table to compare the mosdepth summary metrics and save to a TSV file
with open(mosdepth_output_tsv, "w") as out:
    out.write("sample\tstate\tregion\tlength\tbases\tmean_coverage\tmin_coverage\tmax_coverage\n")

    for metrics in raw_mosdepth_metrics:
        out.write(
            f"{sample_name}\traw\t{metrics['region']}\t{metrics['length']}\t{metrics['bases']}\t{metrics['mean_coverage']}\t{metrics['min_coverage']}\t{metrics['max_coverage']}\n"
        )

    for metrics in filtered_mosdepth_metrics:
        out.write(
            f"{sample_name}\tfiltered\t{metrics['region']}\t{metrics['length']}\t{metrics['bases']}\t{metrics['mean_coverage']}\t{metrics['min_coverage']}\t{metrics['max_coverage']}\n"
        )

#Info message of finished mosdepth comparison
print("Mosdepth comparison completed.")
print(f"Mosdepth comparison file: {mosdepth_output_tsv}")


###########################
### NANOPLOT COMPARISON ###
###########################

#Define paths to NanoStats files and output NanoPlot TSV file
raw_nanoplot_stats = f"{raw_qc_dir}/nanoplot/{sample_name}NanoStats.txt"
filtered_nanoplot_stats = f"{post_filtering_qc_dir}/nanoplot/{filtered_sample_name}NanoStats.txt"

nanoplot_output_tsv = f"{output_dir}/{sample_name}_nanoplot_comparison.tsv"

#Define a function to extract relevant metrics from NanoStats output
def extract_nanostats_metrics(nanostats_file):
    metrics = {
        "average_percent_identity": "",
        "fraction_bases_aligned": "",
        "mean_read_length": "",
        "mean_read_quality": "",
        "median_percent_identity": "",
        "median_read_length": "",
        "median_read_quality": "",
        "number_of_reads": "",
        "read_length_n50": "",
        "stdev_read_length": "",
        "total_bases": "",
        "total_bases_aligned": "",
    }

    with open(nanostats_file, "r") as f:
        for line in f:
            line = line.strip()

            if line.startswith("Average percent identity:"):
                metrics["average_percent_identity"] = float(line.split()[-1])

            elif line.startswith("Fraction of bases aligned:"):
                metrics["fraction_bases_aligned"] = float(line.split()[-1])

            elif line.startswith("Mean read length:"):
                metrics["mean_read_length"] = float(line.split()[-1].replace(",", ""))

            elif line.startswith("Mean read quality:"):
                metrics["mean_read_quality"] = float(line.split()[-1])

            elif line.startswith("Median percent identity:"):
                metrics["median_percent_identity"] = float(line.split()[-1])

            elif line.startswith("Median read length:"):
                metrics["median_read_length"] = float(line.split()[-1].replace(",", ""))

            elif line.startswith("Median read quality:"):
                metrics["median_read_quality"] = float(line.split()[-1])

            elif line.startswith("Number of reads:"):
                metrics["number_of_reads"] = float(line.split()[-1].replace(",", ""))

            elif line.startswith("Read length N50:"):
                metrics["read_length_n50"] = float(line.split()[-1].replace(",", ""))

            elif line.startswith("STDEV read length:"):
                metrics["stdev_read_length"] = float(line.split()[-1].replace(",", ""))

            elif line.startswith("Total bases:"):
                metrics["total_bases"] = float(line.split()[-1].replace(",", ""))

            elif line.startswith("Total bases aligned:"):
                metrics["total_bases_aligned"] = float(line.split()[-1].replace(",", ""))

    return metrics

#Extract metrics from both NanoStats files
raw_nanostats_metrics = extract_nanostats_metrics(raw_nanoplot_stats)
filtered_nanostats_metrics = extract_nanostats_metrics(filtered_nanoplot_stats) 

#Define the order of rows for the output TSV
nanostats_rows = [
    "average_percent_identity",
    "fraction_bases_aligned",
    "mean_read_length",
    "mean_read_quality",
    "median_percent_identity",
    "median_read_length",
    "median_read_quality",
    "number_of_reads",
    "read_length_n50",
    "stdev_read_length",
    "total_bases",
    "total_bases_aligned",
]

#Create a table to compare the NanoStats metrics and save to a TSV file
with open(nanoplot_output_tsv, "w") as out:
    out.write("sample\tmetric\traw\tfiltered\n")

    for metric in nanostats_rows:
        out.write(
            f"{sample_name}\t{metric}\t{raw_nanostats_metrics[metric]}\t{filtered_nanostats_metrics[metric]}\n"
        )

#Info message of finished NanoPlot comparison
print("NanoPlot comparison completed.")
print(f"NanoPlot comparison file: {nanoplot_output_tsv}")
print("[FINISHED] All QC comparisons completed successfully.")