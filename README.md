# ssUMI

A workflow for utilizing unique molecular identifiers (UMIs) for error-correction of small subunit (SSU) rRNA (e.g. 16S rRNA) gene amplicons on the Nanopore platform. This workflow is a branch of the [`longread_umi` pipeline](https://github.com/SorenKarst/longread_umi), and has been taylored for 16S rRNA gene sequencing with newer Nanopore sequencing chemistry (<= R.10.4).

**Table of contents**
- [Installation](#installation)
- [Quick start](#quick-start)
- [Usage](#usage)

**Citations**  
Lin, Xuan, Kate Waring, John Tyson, Ryan M. Ziels. (2023) High-accuracy meets high-throughput for microbiome profiling with near full-length 16S rRNA amplicon sequencing on the Nanopore platform. bioRxiv. 


Karst, Søren M., Ryan M. Ziels, Rasmus H. Kirkegaard, Emil A. Sørensen, Daniel McDonald, Qiyun Zhu, Rob Knight, and Mads Albertsen. (2021) High-accuracy long-read amplicon sequences using unique molecular identifiers with Nanopore or PacBio sequencing. Nat Methods 18, 165–169 (2021). https://doi.org/10.1038/s41592-020-01041-y

## Installation
1. Install the [`longread_umi` package](https://github.com/SorenKarst/longread_umi)

2. Determine the location of the package contents. For instance, if `longread_umi` was installed via conda, type: 
   ```
   conda activate longread_umi
   echo "$CONDA_PREFIX/longread_umi"
   conda deactivate
   ``` 

2. Download the `ssUMI` scripts: 

`git clone https://github.com/ZielsLab/ssUMI.git`

4. Replace the `longread_umi` scripts folder with the new (`ssUMI`) scripts folder
    ```
    mv path/to/longread_umi/scripts path/to/longread_umi/scripts_old
    mv path/to/ssUMI/scripts path/to/longread_umi/longread_umi
    ```
5. Download [`VSEARCH`](https://github.com/torognes/vsearch)


7. Install [`medaka`](https://github.com/nanoporetech/medaka) via a virtual environment:
(see https://github.com/nanoporetech/medaka for details) 

   ```
   cd /path/to/medaka
   
   virtualenv medaka --python=python3 
   sourde medaka/bin/activate
   pip install --upgrade pip
   pip install medaka
   ```
   
8. Edit the file `scripts/dependencies.sh`
   
   Replace part of this line:
   ```
   export VSEARCH="/path/to/vsearch"
   ```
   with your file path to your `VSEARCH` installation.

   
   Then, replace part of this line:
   ```
   export USEARCH="/path/to/usearch"
   ```
   with the path to your `USEARCH` environment (installed as part of `longread_umi`)
   
   
   Finally, replace part of this line:
   ```
   export MEDAKA_ENV_START="source /path/to/medaka/bin/activate"
   ```
   with the paths to your `medaka` virtual environment (e.g. leave the `source activate` part).
   
    ### Test data
    It is highly recommended that users test their installation and `ssUMI` scripts using the test data found in the `test_data` folder within the cloned `ssUMI` repository. Code for running the `ssUMI` pipeline on `test_data.fastq` is given below in [Usage](#usage). The expected output is a fasta file containing 4 UMI-based consensus sequences. 
    
 
 ## Usage

`-- longread_umi ssumi_rapid`: run the ssUMI pipeline for consensus polishing of UMI-tagged 16S rRNA gene amplicons in 'rapid' mode, with just (-c) rounds of Racon polishing (recommended number of rounds = 3).

`-- longread_umi ssumi_std`: run the ssUMI pipeline for consensus polishing of UMI-tagged 16S rRNA gene amplicons in 'standard' mode, with just (-c) rounds of Racon polishing (recommended value = 3), then (-p) rounds of Medaka (recommended value = 2), followed by a final round of Racon polishing.
</code>
```   
usage: 
ssumi_std [-h]  (-d file -v value -o dir -s value) 
(-e value -m value -M value -f string -F string -r string -R string )
( -c value -p value -n value -u dir -t value -T value ) 

ssumi_rapid [-h] (-d file -v value -o dir -s value) 
(-e value -m value -M value -f string -F string -r string -R string )
( -c value -n value -u dir -t value )

where:
    -h  Show this help text.
    -d  Single file containing raw Nanopore data in fastq format.
    -v  Minimum read coverage for using UMI consensus sequences for 
        variant calling.
    -o  Output directory.
    -s  Check start of read up to s bp for UMIs.
    -e  Check end of read up to f bp for UMIs.
    -m  Minimum read length.
    -M  Maximum read length.
    -f  Forward adaptor sequence. 
    -F  Forward primer sequence.
    -r  Reverse adaptor sequence.
    -R  Reverse primer sequence.
    -c  Number of iterative rounds of consensus calling with Racon.
    -p  Number of iterative rounds of consensus calling with Medaka.
    -q  Medaka model used for polishing. r941_min_high, r10_min_high etc.
    -u  Directory with UMI binned reads.
    -t  Number of threads to use.
    -T  Number of medaka jobs to start. Threads pr. job is threads/jobs.
        [Default = 1].
```
### Example Usage
Below is an example usage for V1-V9 16S rRNA gene amplicons generated with UMI-tagged 8F / 1391R UMI primers and an ONT R.10.4 flowcell and basecalled with `guppy v6.3.8`. The raw ONT reads would be given by `INFILE` (e.g. `INFILE="path/to/raw/reads"`), the desired output folder specified by `OUTDIR` (e.g. `OUTDIR="path/to/output"`), and the number of threads by `THREADS` (e.g. `THREADS=16`). 

```
longread_umi ssumi_std \
  -d ${INFILE} \
  -v 3 \
  -o ${OUTDIR} \
  -s 200 \
  -e 200 \
  -E 0.1 \
  -m 1200 \
  -M 2000 \
  -f GTATCGTGTAGAGACTGCGTAGG \
  -F AGRGTTYGATYMTGGCTCAG \
  -r AGTGATCGAGTCAGTGCGAGTG \
  -R GACGGGCGGTGWGTRCA \
  -c 3 \
  -p 2 \
  -q r104_e81_sup_g610 \
  -t ${THREADS} \
  -T ${THREADS}
```


