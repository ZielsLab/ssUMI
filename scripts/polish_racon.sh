#!/bin/bash
# DESCRIPTION
#    Consensus sequence polishing using medaka.
#    This script is a part of the longread-UMI-pipeline.
#    
# IMPLEMENTATION
#    author   Søren Karst (sorenkarst@gmail.com)
#             Ryan Ziels (ziels@mail.ubc.ca)
#    license  GNU General Public License
# TODO
#

### Description ----------------------------------------------------------------

USAGE="
-- longread_umi polish_racon: Nanopore UMI consensus polishing with racon
   
usage: $(basename "$0" .sh) [-h] [-l value T value] 
(-c file -m string -d dir -o dir -t value -n file -T value)

where:
    -h  Show this help text.
    -c  File containing consensus sequences.
    -d  Directory containing UMI read bins in the format
        'umi*bins.fastq'. Recursive search.
    -o  Output directory.
    -t  Number of threads to use.
    -n  Process n number of bins. If not defined all bins
        are processed.
    -t  Number of threads [Default = 1].
"

### Terminal Arguments ---------------------------------------------------------

# Import user arguments
while getopts ':hzc:m:l:d:o:t:n:T:' OPTION; do
  case $OPTION in
    h) echo "$USAGE"; exit 1;;
    c) CONSENSUS_FILE=$OPTARG;;
    d) BINNING_DIR=$OPTARG;;
    o) OUT_DIR=$OPTARG;;
    t) THREADS=$OPTARG;;
    n) SAMPLE=$OPTARG;;
    :) printf "missing argument for -$OPTARG\n" >&2; exit 1;;
    \?) printf "invalid option for -$OPTARG\n" >&2; exit 1;;
  esac
done

# Check missing arguments
MISSING="is missing but required. Exiting."
if [ -z ${CONSENSUS_FILE+x} ]; then echo "-c $MISSING"; echo "$USAGE"; exit 1; fi; 
if [ -z ${BINNING_DIR+x} ]; then echo "-d $MISSING"; echo "$USAGE"; exit 1; fi; 
if [ -z ${OUT_DIR+x} ]; then echo "-o $MISSING"; echo "$USAGE"; exit 1; fi; 
if [ -z ${THREADS+x} ]; then echo "-t $MISSING"; echo "$USAGE"; exit 1; fi; 

### Source commands and subscripts -------------------------------------
. $LONGREAD_UMI_PATH/scripts/dependencies.sh # Path to dependencies script

### Medaka polishing assembly -------------------------------------------------

# Format names
OUT_NAME=${OUT_DIR##*/}

# Prepare output folders
if [ -d "$OUT_DIR" ]; then
  echo "Output folder exists. Exiting..."
  exit 0
fi
mkdir $OUT_DIR


# Individual mapping of UMI bins to consensus

mkdir $OUT_DIR/mapping 

racon_polish() {
  # Input
  local IN=$(cat)
  local BINNING_DIR=$1
  local OUT_DIR=$2

  # Name format
  local UMI_NAME=$(echo "$IN" | grep -o "umi.*bins")
  local UMI_BIN=$(find $BINNING_DIR -name ${UMI_NAME}.fastq)

  # Setup working directory
  mkdir $OUT_DIR/$UMI_NAME
  echo "$IN" > $OUT_DIR/$UMI_NAME/$UMI_NAME.fa

  # Map UMI reads to consensus

    $MINIMAP2 \
      -t 1 \
      -x map-ont \
      $OUT_DIR/$UMI_NAME/$UMI_NAME.fa \
      $UMI_BIN > $OUT_DIR/$UMI_NAME/ovlp.paf

    $RACON \
      -t 1 \
      -m 8 \
      -x -6 \
      -g -8 \
      -w 500 \
      -e 0.04 \
      $RACON_ARG \
      $UMI_BIN \
      $OUT_DIR/$UMI_NAME/ovlp.paf \
      $OUT_DIR/$UMI_NAME/$UMI_NAME.fa > $OUT_DIR/$UMI_NAME/${UMI_NAME}_sr.fa
}

export -f racon_polish

cat $CONSENSUS_FILE |\
  $SEQTK seq -l0 - |\
  ( [[ -f "${SAMPLE}" ]] && grep -A1 -Ff $SAMPLE | sed '/^--$/d' || cat ) |\
  $GNUPARALLEL \
    --env racon_polish \
    --progress  \
    -j $THREADS \
    --recstart ">" \
    -N 1 \
    --pipe \
    "racon_polish \
       $BINNING_DIR \
       $OUT_DIR/mapping
    "

#Collect polished racon consensus sequences

find $OUT_DIR/ \
  -mindepth 3 \
  -maxdepth 3 \
  -name "*_sr*.fa" \
  -exec cat {} \; \
  > $OUT_DIR/consensus_${OUT_NAME}.fa


