#!/usr/bin/env python3

#This script plots DNA methylation across one chromosome using bedMethyl files

#This is useful for whole-genome data, plotting one chromosome at time

#Use: python plot_methylation_across_genome.py <input_bedmethyl> <chr> <mod_code>


###########################
####### PREPARATION #######
###########################

#Import necessary libraries

import os 
import sys
import pandas as pd
import matplotlib.pyplot as plt

#Define input arguments
input_bedmethyl = sys.argv[1]
chrom_plot = sys.argv[2]
mod_code = sys.argv[3]

#Check modified base code
if mod_code not in ["m", "h"]:
    raise ValueError("mod_code must be 'm' for 5mC or 'h' for 5hmC")

#Define modification label for plots
if mod_code == "m":
    mod_label = "5mC"
elif mod_code == "h":
    mod_label = "5hmC"

#Define parametres
window_size = 100000

# Extract sample name from input file
sample_name = os.path.basename(input_bedmethyl)
sample_name = sample_name.replace(".bed.gz", "")

#Define output dir and output file
output_dir = f"results/10_methylation_visualization/genome_wide_methylation/{sample_name}"
os.makedirs(output_dir, exist_ok=True)


###########################
### READ BEDMETHYL FILE ###
###########################

#Read bedMethyl file
bedmethyl = pd.read_csv(
    input_bedmethyl,
    sep="\t",
    header=None,
    compression="infer"
)

#Assign names only to the columns needed
bedmethyl = bedmethyl.rename(
    columns={
        0: "chrom",
        1: "start",
        3: "mod_code",
        9: "coverage",
        10: "percent_methylation"
    }
)

###########################
####### FILTER DATA #######
###########################

#Keep only the selected chromosome
bedmethyl = bedmethyl[bedmethyl["chrom"] == chrom_plot]

#Keep only the selected modification calls
bedmethyl = bedmethyl[bedmethyl["mod_code"] == mod_code]

#Stop if there are no data for the selected chromosome
if bedmethyl.empty:
    raise ValueError(f"No {mod_label} methylation data found for {chrom_plot}")


###########################
#### CREATE WINDOWS #######
###########################

#Assign each methylation position to a genomic window
bedmethyl["window_start"] = (bedmethyl["start"] // window_size) * window_size
bedmethyl["window_end"] = bedmethyl["window_start"] + window_size
bedmethyl["window_midpoint"] = bedmethyl["window_start"] + (window_size / 2)


###########################
### SUMMARIZE WINDOWS #####
###########################

#Group methylation positions by genomic window
grouped_windows = bedmethyl.groupby("window_start")

#Calculate mean methylation for each window
windows = grouped_windows["percent_methylation"].mean().reset_index()

#Rename methylation column
windows = windows.rename(columns={"percent_methylation": "mean_methylation"})

#Calculate number of methylation sites per window
windows["n_sites"] = grouped_windows["percent_methylation"].count().values

#Calculate mean coverage per window
windows["mean_coverage"] = grouped_windows["coverage"].mean().values

#Add window end and midpoint
windows["window_end"] = windows["window_start"] + window_size
windows["window_midpoint"] = windows["window_start"] + (window_size / 2)

#Add sample, chromosome and window size
windows["sample"] = sample_name
windows["chrom"] = chrom_plot
windows["window_size"] = window_size

#Reorder columns
windows = windows[
    [
        "sample",
        "chrom",
        "window_start",
        "window_end",
        "window_midpoint",
        "window_size",
        "n_sites",
        "mean_coverage",
        "mean_methylation"
    ]
]

###########################
###### SAVE OUTPUTS #######
###########################

#Define output files
window_label = f"{int(window_size / 1000)}kb"

output_prefix = (
    f"{sample_name}_{chrom_plot}_"
    f"{mod_code}_methylation_across_genome_{window_label}"
)

output_tsv = os.path.join(output_dir, f"{output_prefix}.tsv")
output_pdf = os.path.join(output_dir, f"{output_prefix}.pdf")

#Save table
windows.to_csv(output_tsv, sep="\t", index=False)


###########################
########### PLOT ##########
###########################

#Convert genomic position to Mb
x_mb = windows["window_midpoint"] / 1000000

#Create figure and first axis
fig, ax1 = plt.subplots(figsize=(14, 5))

#Plot mean methylation
line1, = ax1.plot(
    x_mb,
    windows["mean_methylation"],
    color="blue",
    linewidth=1.5,
    label="Mean methylation"
)

ax1.set_xlabel(f"Position on {chrom_plot} (Mb)")
ax1.set_ylabel("Mean methylation (%)")
ax1.set_ylim(0, 100)

#Create second axis for coverage
ax2 = ax1.twinx()

line2, = ax2.plot(
    x_mb,
    windows["mean_coverage"],
    color="orange",
    linewidth=1.5,
    linestyle="-",
    label="Mean coverage"
)

ax2.set_ylabel("Mean coverage")

#Title
plt.title(
    f"{sample_name} - {mod_label} methylation across {chrom_plot}\n"
    f"Window size: {window_size} bp"
)

#Grid
ax1.grid(True, linewidth=0.3, alpha=0.5)

#Single combined legend outside the plot
lines = [line1, line2]
labels = [line.get_label() for line in lines]

fig.legend(
    lines,
    labels,
    loc="center left",
    bbox_to_anchor=(0.88, 0.5),
    frameon=True
)

#Adjust layout to leave space for legend
fig.tight_layout(rect=[0, 0, 0.85, 1])

#Save plot
plt.savefig(output_pdf, bbox_inches="tight")

#Info messages
print(f"[INFO] Input bedMethyl: {input_bedmethyl}")
print(f"[INFO] Chromosome: {chrom_plot}")
print(f"[INFO] Output table: {output_tsv}")
print(f"[INFO] Output plot: {output_pdf}")
print("---[FINISHED]--- Methylation across genome plot completed.")