#!/bin/sh

##Script to go from paired ends reads to HiC matrices in GRAAL and cooler formats

genome_dir="/mnt/e/Genomes/" #Directory that contains a folder with the reference genome
genome="S288c_DSB" #reference genome. Must be provided in a folder with the same name as the fasta and index files
thread=8
mode="parasplit"			#fastq file processing prior to alignment. Fixed to parasplit. For change, remove the "parasplit" command in the loop,  edit the -m argument of hicstuff, and modify the input fastq files in the hicstuff command.
quality=20 					#mapping quality
hicstuffversion="v324"
fastqdir='/mnt/e/Reads/'	#directory containing the end1 and end2.fastq.gz
digestdir='/mnt/e/Reads/Digested_parasplit/' #Directory in which the digested reads will be stored

#Provide the name of the samples. Reads must be in the form eg AD232.end1.fastq.gz and AD232.end2.fastq.gz in the fastq directory
SAMP=("AD231" "AD232")

for sample in "${SAMP[@]}" ; do
	output=$sample'_'$genome'_'$mode'_borderless_q'$quality'_'$hicstuffversion
	dir=$sample

	#run in silico reads digestion by DpnII/HinfI with parasplit. Remove the ligated restriction sites from the digestion product (--borderless mode)
	parasplit -sf $fastqdir$sample'.end1.fastq.gz' -sr $fastqdir$sample'.end2.fastq.gz' -of $digestdir$sample'_parasplit_borderless_digest_for.fq.gz' -or $digestdir$sample'_parasplit_borderless_digest_rev.fq.gz' -le DpnII,HinfI -nt $thread -m all --borderless
	

	mkdir $sample;
	#align reads on ref genome and generate fragment-level sparse matrices in Graal format.
	#Bin the fragment-level matrix at 1kb
	hicstuff pipeline -m normal -M graal -t $thread -e DpnII,HinfI -q $quality -g $genome_dir$genome'/'$genome -n -p -o $sample -d -f -F -D $digestdir$sample'_parasplit_borderless_digest_for.fq.gz' $digestdir$sample'_parasplit_borderless_digest_rev.fq.gz'
	hicstuff rebin -b 1kb -f $sample'/fragments_list.txt' -c $sample'/info_contigs.txt' $sample'/abs_fragments_contacts_weighted.txt' $sample'/'$output'_1kb'


	#Convert the fragment-level and binned matrices to Cooler format
	mkdir $sample'/Cool';
	#make a cool file binned at 1kb
	hicstuff convert -f $sample'/fragments_list.txt' -c $sample'/info_contigs.txt' $sample'/abs_fragments_contacts_weighted.txt' $sample'/Cool/'$output
	hicstuff convert -f $sample'/'$output'_1kb.frags.tsv' -c $sample'/'$output'_1kb.chr.tsv' $sample'/'$output'_1kb.mat.tsv' $sample'/Cool/'$output'_1kb'

	#Sort bam files and compute coverage in bedgraph format for manual inspection on IGV. 
	mkdir $sample'/Coverage'
	samtools sort -l 5 -o $sample'/tmp/for_sorted.bam' -@ $thread $sample'/tmp/for.bam'
	samtools sort -l 5 -o $sample'/tmp/rev_sorted.bam' -@ $thread $sample'/tmp/rev.bam'
	samtools merge -@ $thread $sample'/tmp/pairs_sorted.bam' $sample'/tmp/for_sorted.bam' $sample'/tmp/rev_sorted.bam'
	samtools index -b $sample'/tmp/pairs_sorted.bam'
	tinycov covplot -r 500 -s 500 -n $output'_coverage_r500_s500' -t $sample'/Coverage/'$output'_coverage_r500_s500.bedgraph' -o $sample'/Coverage/'$output'_coverage_r500_s500.png' -p 0 $sample'/tmp/pairs_sorted.bam'

done
