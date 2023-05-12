# Extract reads with Seqkit and TaxonKit

### Install

The bash script uses `TaxonKit` to produce a list of taxons to filter, `Seqkit` to extract the reads, and `csvtk` for data wrangling. Written for my own purposes.

Use conda to install these:
```
conda install -c bioconda seqkit taxonkit csvtk
```

### Usage
```
Usage: extract_reads.sh -f sample.r1.fastq.gz -r sample.r2.fastq.gz -t 10240 -k sample.kraken.txt

  -f | --forward_fastq            : R1 fastq.gz file
  -r | --reverse_fastq            : R2 fastq.gz file
  -k | --kraken                   : Kraken output of classified reads
  -t | --taxon                    : NCBI taxon ID
  -j | --threads                  : Number of threads to use
  -h | --help                     : This message
  ```

`Taxonkit` is used to produce a subtree of given TaxIds. For example, given taxonid `10244`, this script will extract all reads with the following taxon IDs:

```
% taxonkit list --ids 10245 --indent '' | tr '\n' ' '

10245 10246 10247 10248 10249 10250 10251 10252 10253 10254 
31531 32605 32606 45417 124313 126794 130665 130666 201444 
262397 301352 332193 350831 350832 397342 467144 502057 691321 
696871 1651169
```

### Why

`extract_kraken_reads.py` is commonly used to extract reads classified by kraken. Unfortunately for large libraries it can be slow. 

This script is designed with speed in mind and not as feature rich as `extract_kraken_reads.py`.

### Planned improvements:

- [ ] Allow user to provide a list of taxons, skipping the need for `taxonkit`
- [ ] Allow user to specify flags `--children` or `--ancestor` 
