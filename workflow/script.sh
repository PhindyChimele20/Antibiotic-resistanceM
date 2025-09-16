fastqc *.fastq
module load maxbin-2.2.6
wkd="/nlustre/users/ptebele/Research"
cd ${wkd}
run_MaxBin.pl -contig final.contigs.fa -reads SRR11702759_1.fastq -reads2 SRR11702759_2.fastq -out final.bins

module load megahit

wkd="/nlustre/users/ptebele/Research/"
cd ${wkd}

megahit -1 /nlustre/users/ptebele/Research/SRR11702759_1.fastq -2 /nlustre/users/ptebele/Research/SRR11702759_2.fastq -t 12


# extract(ids) everything before the last underscore, keep only one copy per contig
cut -f1 ARG_annotations.m8 | \
awk -F"_" '{NF--; print $0}' OFS="_" | \
sort | uniq > arg_contig_ids.txt

#extract the sequences(ids with ARGs)
awk 'BEGIN{
  while((getline < "arg_contig_ids.txt") > 0) ids[$1]=1
}
# Check if header line
/^>/ {
  # Remove > symbol and any trailing whitespace
  header=$1
  gsub(">", "", header)
  # Check if header matches one of the IDs
  f=(header in ids)?1:0
}
# Print the line if flagged
f==1 {print}' final.contigs.fa > ARG_contigs.fa

module load bbmap
reformat.sh in=final.contigs.fa out=filtered.contigs minlength=5000

quast.py Research/*.fasta

module load prodigal-2.6.3

wkd="/nlustre/users/ptebele/Research/"
cd ${wkd}
prodigal -i /nlustre/users/ptebele/Research/final.contigs.fa -o final.genes.gbk -a final.proteins.faa -d final.genes.fna -p meta -c


