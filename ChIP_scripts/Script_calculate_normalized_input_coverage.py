import os
import pyBigWig
import numpy as np
import gzip
import pysam
from concurrent.futures import ThreadPoolExecutor, as_completed

# ======== CONFIGURABLE PARAMETERS ========
input_dir = "/mnt/f/Nextcloud/DR07_UMR5239_Experiments/ChIP/_tinymapper/_Input_tracks/to-process/"
bin_size = 200  # Change this value to adjust bin size
output_suffix = str("_normalized_over_median_bin" + str(bin_size) + "bp")
num_threads = 6
# ========================================

def process_bigwig(filename):
    input_path = os.path.join(input_dir, filename)
    base_name = filename.replace(".bw", "")
    output_bw_path = os.path.join(input_dir, f"{base_name}{output_suffix}.bw")
    output_bedgraph_path = os.path.join(input_dir, f"{base_name}{output_suffix}.bedGraph.gz")

    print(f"Processing {filename}")

    bw = pyBigWig.open(input_path)

    # Step 1: Median Calculation
    all_values = []
    for chrom in bw.chroms():
        intervals = bw.intervals(chrom)
        if intervals:
            all_values.extend([v for _, _, v in intervals])
    median_val = np.median(all_values)

    # Step 2: Output BigWig
    bw_out = pyBigWig.open(output_bw_path, "w")
    chroms = [(chrom, bw.chroms()[chrom]) for chrom in bw.chroms()]
    bw_out.addHeader(chroms)

    # Step 3: Output compressed BedGraph
    with gzip.open(output_bedgraph_path, "wt") as bedgraph_out:
        for chrom, chrom_len in bw.chroms().items():
            for start in range(0, chrom_len, bin_size):
                end = min(start + bin_size, chrom_len)
                values = bw.values(chrom, start, end, numpy=True)
                values = values[np.isfinite(values)]

                avg_val = np.mean(values) if len(values) > 0 else 0
                norm_val = avg_val / median_val if median_val != 0 else 0

                bw_out.addEntries([chrom], [start], ends=[end], values=[norm_val])
                bedgraph_out.write(f"{chrom}\t{start}\t{end}\t{norm_val:.6f}\n")

    bw.close()
    bw_out.close()

    # Step 4: Index the compressed BedGraph
    try:
        pysam.tabix_index(output_bedgraph_path, preset="bed", force=True)
        print(f"Finished: {filename} → {output_bw_path}, {output_bedgraph_path} (.tbi created)")
    except Exception as e:
        print(f"Tabix indexing failed for {output_bedgraph_path}: {e}")


# === MULTI-THREADING START ===
if __name__ == "__main__":
    bw_files = [
        f for f in os.listdir(input_dir)
        if f.endswith(".bw") and output_suffix not in f
    ]

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = [executor.submit(process_bigwig, bw) for bw in bw_files]
        for future in as_completed(futures):
            future.result()  # to catch exceptions
