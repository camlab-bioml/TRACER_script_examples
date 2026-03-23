#!/bin/bash

SECONDS=0

# change working directory
cd ../data/tracer/

# make an output directory to store the output aligned files
# OUTDIR="/path/to/out_dir"
# [[ -d ${OUTDIR} ]] || mkdir -p ${OUTDIR}        # If output directory doesn't exist, craete it

appsdir="../../apps"
datadir="221018_A00827_0672_BH7HHFDRX2_McGuigan_Ileana"

sample=$1

laneone="L001"
lanetwo="L002"

forward="R1"
backward="R2"

suffix="001"
ext="fastq.gz"

nameone_forward="${sample}_${laneone}_${forward}_${suffix}"
nameone_backward="${sample}_${laneone}_${backward}_${suffix}"
fileone_forward="${sample}_${laneone}_${forward}_${suffix}.${ext}"
fileone_backward="${sample}_${laneone}_${backward}_${suffix}.${ext}"

nametwo_forward="${sample}_${lanetwo}_${forward}_${suffix}"
nametwo_backward="${sample}_${lanetwo}_${backward}_${suffix}"
filetwo_forward="${sample}_${lanetwo}_${forward}_${suffix}.${ext}"
filetwo_backward="${sample}_${lanetwo}_${backward}_${suffix}.${ext}"


# STEP 1: Run fastqc
#fastqc ${datadir}/${fileone_forward} -o qc/
#fastqc ${datadir}/${fileone_backward} -o qc/
#fastqc ${datadir}/${filetwo_forward} -o qc/
#fastqc ${datadir}/${filetwo_backward} -o qc/


# STEP 2: Run Trimmomatic
# run trimmomatic to trim reads with poor quality
# java -jar ${appsdir}/Trimmomatic-main/dist/jar/trimmomatic-0.40-rc1.jar PE -threads 16 \
# ${datadir}/${fileone_forward} ${datadir}/${fileone_backward} \
# trim/${nameone_forward}_paired.${ext} trim/${nameone_forward}_unpaired.${ext} \
# trim/${nameone_backward}_paired.${ext} trim/${nameone_backward}_unpaired.${ext} \
# ILLUMINACLIP:${appsdir}/Trimmomatic-main/adapters/NexteraPE-PE.fa:2:30:10:8:True \
# LEADING:3 TRAILING:3 MINLEN:36 \
# -phred33

# java -jar ${appsdir}/Trimmomatic-main/dist/jar/trimmomatic-0.40-rc1.jar PE -threads 16 \
# ${datadir}/${filetwo_forward} ${datadir}/${filetwo_backward} \
# trim/${nametwo_forward}_paired.${ext} trim/${nametwo_forward}_unpaired.${ext} \
# trim/${nametwo_backward}_paired.${ext} trim/${nametwo_backward}_unpaired.${ext} \
# ILLUMINACLIP:${appsdir}/Trimmomatic-main/adapters/NexteraPE-PE.fa:2:30:10:8:True \
# LEADING:3 TRAILING:3 MINLEN:36 \
# -phred33

# echo "Trimmomatic finished running!"

# fastqc trim/${nameone_forward}_paired.${ext} -o qc/
# fastqc trim/${nameone_backward}_paired.${ext} -o qc/
# fastqc trim/${nametwo_forward}_paired.${ext} -o qc/
# fastqc trim/${nametwo_backward}_paired.${ext} -o qc/


# STEP 3: Run HISAT2
# mkdir HISAT2
# get the genome indices
# wget https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz

# run alignment
hisat2 \
-q \
-p 20 \
-x ../../hisat2/grch38/genome \
-1 ${datadir}/${fileone_forward} \
-2 ${datadir}/${fileone_backward} \
--summary-file hisat2/${sample}_${laneone}_${suffix}_summary.txt \
| samtools sort -@ 16 -o hisat2/${sample}_${laneone}_${suffix}.bam

echo "HISAT2 finished running for ${laneone}!"

hisat2 \
-q \
-p 20 \
-x ../../hisat2/grch38/genome \
-1 ${datadir}/${filetwo_forward} \
-2 ${datadir}/${filetwo_backward} \
--summary-file hisat2/${sample}_${lanetwo}_${suffix}_summary.txt \
| samtools sort -@ 16 -o hisat2/${sample}_${lanetwo}_${suffix}.bam

echo "HISAT2 finished running for ${lanetwo}!"

# merge different lanes of the same sample
samtools merge -@ 16 -o merged/${sample}.bam \
hisat2/${sample}_${laneone}_${suffix}.bam \
hisat2/${sample}_${lanetwo}_${suffix}.bam

rm hisat2/${sample}_${laneone}_${suffix}.bam
rm hisat2/${sample}_${lanetwo}_${suffix}.bam

echo "BAM files merged!"

rm ${datadir}/${fileone_forward}
rm ${datadir}/${fileone_backward}
rm ${datadir}/${filetwo_forward}
rm ${datadir}/${filetwo_backward}


# STEP 4: Post-alignment QC
# get transcript annotation file
# wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_42/gencode.v42.annotation.gtf.gz

#Sort the output bam file. 
# samtools sort -@ 16 merged/${sample}.bam > merged/${sample}-sorted.bam
# samtools index -@ 16 merged/${sample}-sorted.bam

# samtools flagstat -@ 16 merged/${sample}-sorted.bam > merged/${sample}-sorted.flagstat

#Run qualimap to generate QC reports
# qualimap bamqc -bam merged/${sample}-sorted.bam -gff ../../qualimap/gencode.v42.annotation.gtf -outdir qualimap/${sample}-bamqc-qualimap-report --java-mem-size=16G
# qualimap rnaseq -bam merged/${sample}-sorted.bam -gtf ../../qualimap/gencode.v42.annotation.gtf -outdir qualimap/${sample}-rnaseq-qualimap-report --java-mem-size=16G


# STEP 5: Run featureCounts - Quantification
# get gtf
# wget http://ftp.ensembl.org/pub/release-106/gtf/homo_sapiens/Homo_sapiens.GRCh38.106.gtf.gz
featureCounts \
-p \
--countReadPairs \
-T 20 \
-s 0 \
-g gene_id \
-a ../../featureCounts/hg38/Homo_sapiens.GRCh38.106.gtf.gz \
-o quants/${sample}_featurecounts.txt merged/${sample}.bam

echo "featureCounts finished running!"


duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."