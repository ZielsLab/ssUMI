# ssUMI

A workflow for utilizing unique molecular identifiers (UMIs) for error-correction of small subunit (SSU) rRNA (e.g. 16S rRNA) gene amplicons on the Nanopore platform. This workflow is a branch of the [`longread_umi` pipeline](https://github.com/SorenKarst/longread_umi), and has been taylored for newer Nanopore sequencing chemistry (<= R.10.4).

**Table of contents**
- [Installation](#installation)
- [Quick start](#quick-start)
- [Usage](#usage)

**Citations**  
[bioRxiv paper]

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
    mv path/to/ssUMI/scripts path/to/longread_umi/
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
 
 
 ## Usage
Give ssUMI commands

