#!/bin/bash
# DESCRIPTION
#    longread_umi ssUMI_std (standard mode) script. 
#    
# IMPLEMENTATION
#    author   Xuan Lin (xuan.lin@ubc.ca)
#             Ryan Ziels (ziels@mail.ubc.ca)
#    license  GNU General Public License
#

### Description ----------------------------------------------------------------

USAGE="
-- longread_umi ssumi_std: Generate UMI consensus sequences of full-length 16S rRNA from Q20+ Nanopore data in standard mode
   
usage: $(basename "$0" .sh) [-h] [-w string] (-d file -v value -o dir -s value) 
(-e value -m value -M value -f string -F string -r string -R string )
( -c value -p value -n value -u dir -t value -T value ) 

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
    -E  Maximum expected error rate for raw read filtering. (0.0 - 1.0; Default = 0.03)
    -f  Forward adaptor sequence. 
    -F  Forward primer sequence.
    -r  Reverse adaptor sequence.
    -R  Reverse primer sequence.
    -c  Number of iterative rounds of consensus calling with Racon.
    -p  Number of iterative rounds of consensus calling with Medaka
    -q  Medaka model used for polishing. r104_e81_sup_g610 r1041_e82_400bps_sup_v4.2.0 etc.
    -n  Process n number of bins. If not defined all bins are processed.
        Pratical for testing large datasets.
    -u  Directory with UMI binned reads.
    -t  Number of threads to use.
    -T  Number of medaka jobs to start. Threads pr. job is threads/jobs.
        [Default = 1].
"


### Terminal Arguments ---------------------------------------------------------

# Import user arguments
while getopts ':hzd:v:o:s:e:m:M:f:F:r:R:c:p:q:w:n:u:t:T:E:' OPTION; do
  case $OPTION in
    h) echo "$USAGE"; exit 1;;
    d) INPUT_READS=$OPTARG;;
    v) UMI_COVERAGE_MIN=$OPTARG;;
    o) OUT_DIR=$OPTARG;;
    s) START_READ_CHECK=$OPTARG;;
    e) END_READ_CHECK=$OPTARG;;
    E) MAX_EE=$OPTARG;;
    m) MIN_LENGTH=$OPTARG;;
    M) MAX_LENGTH=$OPTARG;;
    f) FW1=$OPTARG;;
    F) FW2=$OPTARG;;
    r) RV1=$OPTARG;;
    R) RV2=$OPTARG;;  
    c) CON_N=$OPTARG;;
    p) POL_N=$OPTARG;;
    q) MEDAKA_MODEL=$OPTARG;;
    w) WORKFLOW=$OPTARG;;
    n) UMI_SUBSET_N=$OPTARG;;
    u) UMI_DIR=$OPTARG;;
    t) THREADS=$OPTARG;;
    T) MEDAKA_JOBS=$OPTARG;;
    :) printf "missing argument for -$OPTARG\n" >&2; exit 1;;
    \?) printf "invalid option for -$OPTARG\n" >&2; exit 1;;
  esac
done

# Check missing arguments
MISSING="is missing but required. Exiting."
if [ -z ${INPUT_READS+x} ]; then echo "-d $MISSING"; echo "$USAGE"; exit 1; fi; 
if [ -z ${UMI_COVERAGE_MIN+x} ]; then echo "-v $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${OUT_DIR+x} ]; then echo "-o $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${START_READ_CHECK+x} ]; then echo "-s $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${END_READ_CHECK+x} ]; then echo "-e $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${MIN_LENGTH+x} ]; then echo "-m $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${MAX_LENGTH+x} ]; then echo "-M $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${FW1+x} ]; then echo "-f $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${FW2+x} ]; then echo "-F $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${RV1+x} ]; then echo "-r $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${RV2+x} ]; then echo "-R $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${CON_N+x} ]; then echo "-c $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${POL_N+x} ]; then echo "-p $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${MEDAKA_MODEL+x} ]; then echo "-q $MISSING"; echo "$USAGE"; exit 1; fi;
if [ -z ${MAX_EE+x} ]; then echo "-E is missing. Defaulting to 3%."; MAX_EE=0.03; fi;
if [ -z ${THREADS+x} ]; then echo "-t is missing. Defaulting to 1 thread."; THREADS=1; fi;
if [ -z ${MEDAKA_JOBS+x} ]; then echo "-T is missing. Medaka jobs set to 1."; MEDAKA_JOBS=1; fi;

### Source commands and subscripts -------------------------------------
. $LONGREAD_UMI_PATH/scripts/dependencies.sh # Path to dependencies script

if [ -d $OUT_DIR ]; then
  echo ""
  echo "$OUT_DIR exists. Remove existing directory or rename desired output directory."
  echo "Analysis aborted ..."
  echo ""
  exit 1 
else
  mkdir $OUT_DIR
fi

### Pipeline -----------------------------------------------------------
# Logging
LOG_DIR=$OUT_DIR/logs
mkdir $LOG_DIR

LOG_NAME="$LOG_DIR/longread_ssumi_nanopore_pipeline_log_$(date +"%Y-%m-%d-%T").txt"
echo "longread_ssumi nanopore_pipeline log" >> $LOG_NAME
longread_umi_version_dump $LOG_NAME
exec &> >(tee -a "$LOG_NAME")
exec 2>&1
echo ""
echo "### Settings:"
echo "Input reads: $INPUT_READS"
echo "Output directory: $OUT_DIR"
echo "Check start of read: $START_READ_CHECK"
echo "Check end of read: $END_READ_CHECK"
echo "Minimum read length: $MIN_LENGTH"
echo "Maximum read length: $MAX_LENGTH"
echo "Maximum expected eror rate in raw reads: $MAX_EE"
echo "Forward adaptor sequence: $FW1"
echo "Forward primer sequence: $FW2"
echo "Reverse adaptor sequence: $RV1"
echo "Reverse adaptor primer: $RV2" 
echo "Minimum UMI coverage: $UMI_COVERAGE_MIN"
echo "UMI subsampling: $UMI_SUBSET_N"
echo "Racon consensus rounds: $CON_N"
echo "Medaka consensus rounds: $POL_N"
echo "Medaka model: $MEDAKA_MODEL"
echo "Preset workflow: $WORKFLOW"
echo "Bin size cutoff: $UMI_COVERAGE_MIN"
echo "UMI binning dir: $UMI_DIR"
echo "Threads: $THREADS"
echo "Medaka jobs: $MEDAKA_JOBS"
echo ""

# Read filtering and UMI binning
if [ -z ${UMI_DIR+x} ]; then
  UMI_DIR=$OUT_DIR/umi_binning
  longread_umi umi_binning  \
    -d $INPUT_READS      `# Raw nanopore data in fastq format`\
    -o $UMI_DIR          `# Output folder`\
    -m $MIN_LENGTH       `# Min read length`\
    -M $MAX_LENGTH       `# Max read length` \
    -E $MAX_EE		 `# Max EE rate` \
    -s $START_READ_CHECK `# Start of read to check` \
    -e $END_READ_CHECK   `# End of read to check` \
    -f $FW1              `# Forward adaptor sequence` \
    -F $FW2              `# Forward primer sequence` \
    -r $RV1              `# Reverse adaptor sequence` \
    -R $RV2              `# Reverse primer sequence` \
    -u 2.0               `# UMI match error filter` \
    -U 2                `# UMI match error SD filter` \
    -O 0.20              `# Min read orientation fraction` \
    -N 10000             `# Maximum number of reads +/-` \
    -t $THREADS          `# Number of threads` \
    -S 3		`# Max bin cluster ratio` \
    -v $UMI_COVERAGE_MIN `# Minimum UMI coverage`
fi

# Sample UMI bins for testing
if [ ! -z ${UMI_SUBSET_N+x} ]; then
  find  $UMI_DIR/read_binning/bins \
    -name 'umi*bins.fastq' | sed -e 's|^.*/||' -e 's|\..*||' |\
    head -n $UMI_SUBSET_N > $OUT_DIR/sample$UMI_SUBSET_N.txt
fi

# Consensus
CON_NAME=raconx${CON_N}
CON_DIR=$OUT_DIR/$CON_NAME
longread_umi consensus_racon \
  -d $UMI_DIR/read_binning/           `# Path to UMI bins`\
  -o ${CON_DIR}                           `# Output folder`\
  -p map-ont                              `# Minimap preset`\
  -a "--no-trimming"                      `# Extra args for racon`\
  -r $CON_N                               `# Number of racon polishing times`\
  -t $THREADS                             `# Number of threads`\
  -n $OUT_DIR/sample$UMI_SUBSET_N.txt     `# List of bins to process`

#Tidy up
tar -czvf ${CON_DIR}/mapping.tar.gz ${CON_DIR}/umi*bins --remove-files

## Polishing
CON=${CON_DIR}/consensus_${CON_NAME}.fa
for j in `seq 1 $POL_N`; do
  POLISH_NAME=medakax${j}
  POLISH_DIR=${CON_DIR}_${POLISH_NAME}
  longread_umi polish_medaka \
    -c $CON                              `# Path to consensus data`\
    -m $MEDAKA_MODEL                     `# Path to consensus data`\
    -l $MAX_LENGTH                       `# Sensible chunk size`\
    -d $UMI_DIR/read_binning/bins        `# Path to UMI bins`\
    -o $POLISH_DIR                       `# Output folder`\
    -t $THREADS                          `# Number of threads`\
    -n $OUT_DIR/sample$UMI_SUBSET_N.txt  `# List of bins to process` \
    -T $MEDAKA_JOBS                      `# Uses ALL threads with medaka`
  CON=$POLISH_DIR/consensus_${CON_NAME}_${POLISH_NAME}.fa
done

#Tidy up
tar -czvf ${POLISH_DIR}/mapping.tar.gz ${POLISH_DIR}/mapping --remove-files

## Final racon polishing
CON_N2=1
CON_NAME2=${CON_NAME}_${POLISH_NAME}_raconx${CON_N2}
CON_DIR2=$OUT_DIR/$CON_NAME2
longread_umi polish_racon \
    -c $CON                              `# Path to consensus data`\
    -d $UMI_DIR/read_binning/bins        `# Path to UMI bins`\
    -o $CON_DIR2                          `# Output folder`\
    -t $THREADS                          `# Number of threads`
#Tidy up
tar -czvf ${CON_DIR2}/mapping.tar.gz >${CON_DIR2}/mapping/umi*bins --remove-files

# Trim UMI consensus data
longread_umi trim_amplicon \
  -d $CON_DIR2          `# Path to consensus data`\
  -p '"consensus*fa"'     `# Consensus file pattern. Regex must be flanked by '"..."'`\
  -o $OUT_DIR             `# Output folder`\
  -F $FW2                 `# Forward primer sequence`\
  -R $RV2                 `# Reverse primer sequence`\
  -m $MIN_LENGTH          `# Min read length`\
  -M $MAX_LENGTH          `# Max read length` \
  -t $THREADS             `# Number of threads` \
  -l $LOG_DIR


#Cluster into OTUs
#$USEARCH -fastx_uniques $OUT_DIR/consensus_${CON_NAME2}.fa \
#  -fastaout $OUT_DIR/uniques.fasta \
#  -minuniquesize 2 \
#  -sizeout \
#  -relabel seq
#$USEARCH -unoise3 $OUT_DIR/uniques.fasta \
#  -minsize 10 \
#  -zotus $OUT_DIR/zotus.fasta \
#  -tabbedout $OUT_DIR/unoise3.txt
#$USEARCH -sortbylength $OUT_DIR/zotus.fasta \
#  -fastaout $OUT_DIR/zotus_sorted.fasta
#$USEARCH -cluster_smallmem $OUT_DIR/zotus_sorted.fasta \
#  -id 0.97 -strand both \
#  -centroids $OUT_DIR/otus97.fasta \
#  -uc $OUT_DIR/clusters.uc

#Tidy up
tar -czvf $UMI_DIR/read_binning/bins.tar.gz $UMI_DIR/read_binning/bins --remove-files
