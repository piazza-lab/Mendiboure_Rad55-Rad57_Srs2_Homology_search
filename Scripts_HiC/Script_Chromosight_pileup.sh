#!/bin/bash
subsample=24000000 #indicate the number of contacts to retain in the matrix
thread=8 #specify the number of threads to use
input_dir="./Chromosight_inputs/" #specify the input_directory where Chromosight input and output files are and will be located
cooldir='/mnt/e/cool/' #specify the folder containing the multi-level matrices in mcool format with a 1kb resolution included
centro="_S288c_centro_coordinates.bed2d" #file containing the coordinates of the centromeres in bed2d format
cen2cen="_S288c_centro_chr7_others_coordinates.bed2d" #file containing the intersection of CEN7 with other centromeres in bed2d format
CARs="_CARs_HB44_vs-HB42_genome-S288c_DSB_LY_Capture_artificial_OVHR90_summits_minus-chr5_top500_max50kb.bed2d" #file containing the cohesin peaks determined in Piazza et al. NCB 2021 (Scc1-HA calibrated ChIP-Seq). The chr5 containing the DSB is excluded from the dataset.

sample=("AD231_S288c_DSB_cutsite_q20" "AD232_S288c_DSB_cutsite_q20") #specify the cooler file name. do not include the .mcool suffix
for SAMP in "${sample[@]}" ; do
  chromosight quantify --pattern=borders --win-size=81 --perc-zero=100 --subsample=$subsample --threads=$thread $input_dir$centro $cooldir$SAMP'.mcool::/resolutions/1000' "./"$SAMP'_centro_pileup_win_81kb_subsample_'$subsample;
  chromosight quantify --pattern=centromeres --inter --win-size=81 --perc-zero=100 --subsample=$subsample --threads=$thread $input_dir$cen2cen $cooldir$SAMP'.mcool::/resolutions/1000' "./"$SAMP'_centromere_chr7_win_81kb_subsample_'$subsample;
  chromosight quantify --pattern=loops --win-size=29 --perc-zero=100 --subsample=$subsample --threads=$thread $input_dir$CARs $cooldir$SAMP'.mcool::/resolutions/1000' "./"$SAMP'_CARs_win_auto_subsample_'$subsample

done
