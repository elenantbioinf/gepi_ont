#!/usr/bin/env python3

#This script plots global DNA methylation distribution by haplotype using bedMethyl files

#It compares HP1 and HP2 methylation distributions across one sample

#Use: python plot_haplotype_methylation_distribution.py <hp1_bedmethyl> <hp2_bedmethyl> <chrom_plot> <mod_code>

###########################
####### PREPARATION #######
###########################

#Import necessary libraries
import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

#Define input arguments
haplotype_1 = sys.argv[1]
haplotype_2 = sys.argv[2]
chrom_plot = sys.argv[3]
mod_code = sys.argv[4]

#Check modified base code
if mod_code not in ["m", "h"]:
    raise ValueError("mod_code must be 'm' for 5mC or 'h' for 5hmC")

#Define modification label for plots
if mod_code == "m":
    mod_label = "5mC"
elif mod_code == "h":
    mod_label = "5hmC"

#Extract sample name from HP1 file
sample_name = os.path.basename(haplotype_1)
sample_name = sample_name.replace(".bed.gz", "")
sample_name = sample_name.replace("_hp1_cov5", "")

#Define output directory
output_dir = f"results/10_methylation_visualization/haplotype_methylation_distribution/{sample_name}"
os.makedirs(output_dir, exist_ok=True)


###########################
### READ BEDMETHYL FILE ###
###########################

#Create a function to read the bedmethyl files
#A function is needed because the user will give two arguments to the script

def read_hp_bedmethyl(input_bedmethyl, haplotype, chrom_plot, mod_code):
    
    #Read bedmethyl file
    bedmethyl = pd.read_csv(
        input_bedmethyl,
        sep="\t",
        header=None,
        compression="infer"
    )

    ##Assign names only to the columns needed
    bedmethyl = bedmethyl.rename(
        columns={
            0: "chrom",
            1: "start",
            3: "mod_code",
            9: "coverage",
            10: "percent_methylation"
        }
    )

    #Keep only the selected chromosome
    bedmethyl = bedmethyl[bedmethyl["chrom"] == chrom_plot]

    #Keep only the selected modification calls
    bedmethyl = bedmethyl[bedmethyl["mod_code"] == mod_code]

    #Stop if there are no data
    if bedmethyl.empty:
        raise ValueError(
            f"No {mod_label} methylation data found for {haplotype} in {chrom_plot}"
                         )
    
    #Keep only the relevant columns
    bedmethyl = bedmethyl[
        [
            "chrom",
            "start",
            "coverage",
            "percent_methylation"
        ]
    ].copy()

    #Add sample and haplotype information
    bedmethyl["sample"] = sample_name
    bedmethyl["haplotype"] = haplotype

    return bedmethyl

###########################
####### COMBINE DATA ######
###########################

#Read HP1 bedMethyl file
hp1_data = read_hp_bedmethyl(
    input_bedmethyl=haplotype_1,
    haplotype="HP1",
    chrom_plot=chrom_plot,
    mod_code=mod_code
)

#Read HP2 bedMethyl file
hp2_data = read_hp_bedmethyl(
    input_bedmethyl=haplotype_2,
    haplotype="HP2",
    chrom_plot=chrom_plot,
    mod_code=mod_code
)

#Combine both haplotypes in one table
combined_data = pd.concat(
    [
        hp1_data,
        hp2_data
    ],
    ignore_index=True
)


###########################
###### SAVE OUTPUTS #######
###########################

#Define output files
output_prefix = f"{sample_name}_{chrom_plot}_{mod_code}_haplotype_methylation_distribution"

output_tsv = os.path.join(output_dir, f"{output_prefix}.tsv")
output_pdf = os.path.join(output_dir, f"{output_prefix}.pdf")

#Save combined table
combined_data.to_csv(output_tsv, sep="\t", index=False)


###########################
########### PLOT ##########
###########################

#Extract methylation values for each haplotype
hp1_values = combined_data[
    combined_data["haplotype"] == "HP1"
]["percent_methylation"]

hp2_values = combined_data[
    combined_data["haplotype"] == "HP2"
]["percent_methylation"]

#Create plot
plt.figure(figsize=(6, 5))

violin_parts = plt.violinplot(
    [
        hp1_values,
        hp2_values
    ],
    showmeans=False,
    showmedians=True,
    showextrema=False
)

#Set x-axis labels
plt.xticks(
    [1, 2],
    ["HP1", "HP2"]
)

plt.ylabel("Methylation (%)")

plt.title(
    f"{sample_name} - {mod_label} methylation distribution by haplotype\n"
    f"{chrom_plot}"
)

plt.ylim(0, 100)
plt.grid(axis="y", linewidth=0.3, alpha=0.5)
plt.tight_layout()

#Save plot
plt.savefig(output_pdf)
plt.close()

###########################
########## REPORT #########
###########################

print(f"[INFO] Sample: {sample_name}")
print(f"[INFO] Chromosome: {chrom_plot}")
print(f"[INFO] Modification: {mod_label}")
print(f"[INFO] HP1 records: {len(hp1_data)}")
print(f"[INFO] HP2 records: {len(hp2_data)}")
print(f"[INFO] Output table: {output_tsv}")
print(f"[INFO] Output plot: {output_pdf}")
print("[FINISHED] Haplotype methylation distribution plot completed.")