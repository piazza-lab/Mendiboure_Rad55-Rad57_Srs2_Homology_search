#!/bin/sh
#provide input and output directory paths
input_dir="/mnt/e/cool/"
output_dir="/mnt/f/output_dir/"

#Provide the full name of the cooler files
#Matrices must be in a fragment-level cooler format or binned at 1kb
sample=("AD572_S288c_DSB_LY_Capture_artificial_v12_cutsite_q20_v312_1kb_PCRfree"
"AD576_S288c_DSB_LY_Capture_artificial_v12_cutsite_q20_v312_1kb_PCRfree")

for SAMP in "${sample[@]}" ; do
  echo "$SAMP starts"
  hicstuff view -b 2kb -m -4.5 -M -1.5 -T log10 -c YlOrBr -n -r chr5 -N 10 -o $output_dir$SAMP"_chr5_2kb_log_N10_m4.5M1.5.pdf" $input_dir$SAMP".cool"
  hicstuff view -b 15kb -m -4.5 -M -1.5 -T log10 -c YlOrBr -n -N 10 -o $output_dir$SAMP"_WG_15kb_log_N10_m4.5M1.5.pdf" $input_dir$SAMP".cool";
done
