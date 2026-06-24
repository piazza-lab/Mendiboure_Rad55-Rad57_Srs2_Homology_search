#!/bin/sh
#provide input and output directory paths
input_dir="/mnt/e/cool/"
output_dir="/mnt/f/output_dir/"

#provide the reference (denominator) matrix as input1 and the other matrices (numerator) in the list sample2.
#Matrices must be in a fragment-level cooler format or binned at 1kb
input1="AD572_S288c_DSB_LY_Capture_artificial_v12_cutsite_q20_v312_1kb_PCRfree" #denominator
sample2=("AD572_S288c_DSB_LY_Capture_artificial_v12_cutsite_q20_v312_1kb_PCRfree"
"AD407_S288c_DSB_LY_Capture_artificial_v12_cutsite_q20_v312_1kb_PCRfree") #numerators, iterated upon


for input2 in "${sample2[@]}" ; do
	echo $input2 "start" 
	hicstuff view -b 5kb -T log10 -n -r chr5 -c bwr -N 20 -o $nextcloud$input2'_over_'$input1'_chr5_5kb_log_N20.pdf' $dir$input2'.cool' $dir$input1'.cool'
	hicstuff view -b 20kb -T log10 -n -c bwr -N 20 -o $nextcloud$input2'_over_'$input1'_WG_20kb_log_N20.pdf' $dir$input2'.cool' $dir$input1'.cool'
done