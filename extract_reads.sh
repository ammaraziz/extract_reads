#!/bin/bash

#abort on error
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
TIMEFORMAT='%3lR'

function usage
{
    echo "Extract reads from paired fastq.gz files for a given taxon ID using taxonkit/csvtk/seqkit"
    echo "Taxonkit is used to retreive all subtree taxons. Therefore it's assumed taxonkit is properly installed."
    echo ""
    echo "Usage: extract_reads.sh -f sample.r1.fastq.gz -r sample.r2.fastq.gz -t 10240 -k sample.kraken.txt"
    echo "   ";
    echo "  -f | --forward_fastq            : R1 fastq.gz file";
    echo "  -r | --reverse_fastq            : R2 fastq.gz file";
    echo "  -k | --kraken                   : Kraken output of classified reads";
    echo "  -t | --taxon                    : NCBI taxon ID";
    echo "  -j | --threads                  : Number of threads to use";
    echo "  -h | --help                     : This message";
}

function parse_args
{
  # positional args
  args=()

  # named args
  while [ "$1" != "" ]; do
      case "$1" in
          -f | --forward_fastq )               forward_fastq="$2";     shift;;
          -r | --reverse_fastq )               reverse_fastq="$2";     shift;;
          -k | --kraken )                      kraken="$2";            shift;;
          -t | --taxon )                       taxon="$2";             shift;;
          -j | --threads )                     threads="$2";           shift;;
          -c | --children )                    children="$2";          shift;;
          -h | --help )                        usage;                  exit;; # quit and show usage
          * )                           args+=("$1")             # if no match, add it to the positional args
      esac
      shift # move to next kv pair
  done

  # restore positional args
  set -- "${args[@]}"

  # set positionals to vars
  positional_1="${args[0]}"
  positional_2="${args[1]}"

  # validate required args
  if [[ -z $forward_fastq ]]; then
    echo ""
    echo -e "${RED}Missing input argument --forward_fastq ${NC}"
  fi
  if [[ -z $reverse_fastq ]]; then 
    echo -e "${RED}Missing input argument --reverse_fastq ${NC}"
  fi
  if [[ -z $kraken ]]; then
    echo -e "${RED}Missing input argument --kraken ${NC}"
  fi
  if [[ -z $taxon ]]; then
    echo -e "${RED}Missing input argument --taxon ${NC}"
  fi
  if [[ -z $threads ]]; then
    echo -e "${RED}Missing input argument --threads ${NC}"
  fi
  if [[ -z $forward_fastq ]] ||  [[ -z $reverse_fastq ]] || [[ -z $kraken ]] || [[ -z $taxon ]] || [[ -z $threads ]]; then
    echo ""
    usage
    exit;
  else
    echo -ne "${ORANGE}                               Input Checks Done${NC}\r"
  fi
}


function run
{
  parse_args "$@"

  # create output folders
  mkdir -p $PWD/work
  mkdir -p $PWD/filtered

  # get file names
  FORWARDNAME=$(basename -- "$forward_fastq")
  REVERSENAME=$(basename -- "$reverse_fastq")
  KRAKENNAME=$(basename -- "$kraken")

  echo -ne "${ORANGE}                Getting subtree for taxon id $taxon ${NC}\r"
  # get taxon ids
  taxonkit list --ids $taxon --indent '' > $PWD/work/$taxon.txt

  echo -ne "${ORANGE}       Getting read names that match $taxon subtree ${NC}\r"
  # get read names that match ids
  csvtk -t filter2 -H -f '$1=="C"' $kraken | csvtk -t cut -f 3,2 > $PWD/work/$KRAKENNAME.classified
  csvtk join -t -f 1 $PWD/work/$KRAKENNAME.classified $PWD/work/$taxon.txt > $PWD/work/$taxon.kraken
  echo -ne "${ORANGE}                Mutating - this bit takes a while...${NC}\r"
  csvtk mutate2 -t -H -e '$2 + " 1"' $PWD/work/$taxon.kraken | csvtk -t cut -f 3 > $PWD/work/r1.$taxon.headers
  csvtk mutate2 -t -H -e '$2 + " 2"' $PWD/work/$taxon.kraken | csvtk -t cut -f 3 > $PWD/work/r2.$taxon.headers

  # display number of reads so user feels good about themselves
  PATTERNS=$(wc -l < $PWD/work/$taxon.kraken)
  echo -ne "${ORANGE} $PATTERNS reads identified matching taxon id $taxon${NC}\r"

  # filter the fastq files
  echo -ne "${ORANGE}                     Filtering $PATTERNS reads for R1${NC}\r"
  seqkit grep --quiet -n $forward_fastq -f $PWD/work/r1.$taxon.headers -j $threads -o $PWD/filtered/${FORWARDNAME/.$taxon.fastq.gz/}
  echo -ne "${ORANGE}                     Filtering $PATTERNS reads for R2${NC}\r"
  seqkit grep --quiet -n $reverse_fastq -f $PWD/work/r2.$taxon.headers -j $threads -o $PWD/filtered/${REVERSENAME/.$taxon.fastq.gz/}
  echo -ne "${GREEN} Done                                                 ${NC}\r"
  echo -ne "\n"
}

run "$@";
