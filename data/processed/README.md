# Processed genus-level count matrix

`merged_genus_table.tsv.gz` is a gzip-compressed tab-separated table containing genus-level read counts for 57,215 sequencing records and 3,795 taxonomic features. Rows are SILVA-style full taxonomic labels and columns are sequencing-record identifiers. The matrix is the processed input used for downstream analyses; it is not raw FASTQ sequencing data or an ASV-level matrix. Sample identifiers correspond to the study metadata.

For a direct import in R, open the gzip file with a tab-separated parser, treating the first column as the taxonomic identifier. Depending on the operation, the matrix may require substantial memory.

SHA-256 of the uncompressed TSV: `0142d00c6d64af00e830d88e48b600bcea3ec11dd65924d1f4620a7e1b9d57be`.
