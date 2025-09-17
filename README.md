

#  README

## 1. Data sources

This task is based on on publicly available sequencing data from the study "Contaminant-degrading bacteria are super carriers of antibiotic resistance genes in municipal landfills: A metagenomics-based study" which focused on exploring the antibiotic resistome, antibiotic-resistant bacteria and contaminant-degrading bacteria from waste samples collected in 22 municipal landfills. In this study, the available metagenomic datasets targeting municipal landfills in China were downloaded from the EMBL-EBI website (https://wwwdev.ebi.ac.uk/). For the purpose of this analysis only one sample was selected.

---

## 2. How to download

The data for the sample is available as raw reads are available on SRA with the SRA accession SRR11702759.
### Code for downloading

```bash
SRRS=("SRR11702759")

for SRR in "${SRRS[@]}"; do
    echo "Downloading $SRR ..."
    prefetch "$SRR"
    fastq-dump --gzip --split-files "$SRR"
done
```


---

## 3. Pre-processing 

From the GEO where the raw data fastq files are, we selected 1 samples (forward and reverse read) and downloaded using their SRR accessions as per above script (Code for Downloaded)

1. **STEP 1** ...

Example:

```bash
CODE TO SUBSAMPLE
```


---

## 4. How the workflow works
The workflow files is stored in workflow/ and it is divided into different steps:
The workflow files are stored in `workflow/`.

---

### Step 1 – Quality Check

**Purpose:** The workflow takes each FASTQ.qz file (raw reads), assess the quality of the reads and give the scores and overall stats on the quality of reads.
**Tools:** `fastqc`
**Inputs:** Raw reads FASTQ files (from `data/`)
**Outputs:** quality matrix (html)
**Command:**

```bash
module load fastqc-0.11.7
fastqc *.fastq                                         

```

---

### Step 2 - Assembly

**Purpose:** Assembly the reads into contigs
**Tools:** 'Megahit'
**Inputs:** fastq files
**Outputs:** fasta/fa file
**Command:**

```bash
module load megahit

wkd="/nlustre/users/ptebele/Research/"
cd ${wkd}

megahit -1 /nlustre/users/ptebele/Research/SRR11702759_1.fastq -2 /nlustre/users/ptebele/Research/SRR11702759_2.fastq -t 12

```
---

### Step 3 – Generating bins

**Purpose:** the pipeline generates contig bins
**Tools:** 'Maxbin'
**Inputs:** fastq
**Outputs:** contigs.fa
**Command:**
```bash
module load maxbin-2.2.6

wkd="/nlustre/users/ptebele/Research"

cd ${wkd}

run_MaxBin.pl -contig final.contigs.fa -reads SRR11702759_1.fastq -reads2 SRR11702759_2.fastq -out final.bins

```
### Step 4 - Assembly quality

**Purpose:** This part of the workflow assess the quality of the assembly
**Tools:** 'Quast'
**Inputs:** .fasta
**Outputs:** html, txt file
**Command:**

```bash
quast.py Research/*.fasta
quast.py /nlustre/users/ptebele/Research/final.contigs.fa -o /nlustre/users/ptebele/Research/final.contigs


```
---

### Step 5 - Contig Filtering

**Purpose:** This part of the workflow filteres contigs that are less than 5000
**Tools:** 'bbmap'
**Inputs:** contigs.fa
**Outputs:** filtered.contigs
**Command:**

```bash
module load bbmap
reformat.sh in=final.contigs.fa out=filtered.contigs minlength=5000
```
---
### Step 6 - Functional Annotation

**Purpose:** This part of the workflow takes the assemblied genome/contigs and peform functional annotation
**Tools:** 'Prodigal'
**Inputs:** contigs.fasta
**Outputs:** genes.fa and proteins.fa file
**Command:**

```bash
module load prodigal-2.6.3

wkd="/nlustre/users/ptebele/Research/"
cd ${wkd}
prodigal -i /nlustre/users/ptebele/Research/final.contigs.fa -o final.genes.gbk -a final.proteins.faa -d final.genes.fna -p meta -c

```
---

### Step 7 - Contigs filtering

**Purpose:** This part of the workflow improves the quality of the assembly through contigs filtering 
**Tools:** 'ARGs'
**Inputs:** .fasta
**Outputs:** filtered.fasta
**Command:**

```bash
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


```
---
