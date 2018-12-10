#!/usr/bin/env bash
#
# Script to extract data from Kaiko zip files
#
# Author: Christophe Bisière
# This project is licensed under the MIT License
# Last revised 2018-12-05
#
# Documentation is available at 

readonly SCRIPT_NAME="${0##*/}"
readonly USAGE="${SCRIPT_NAME} [-h] [-i directory] [-o directory] [-t type]\ 
 [-e exchanges] [-p pairs] [-c] [-z] [-m] [-v] [-d]

where:
    -h, --help           show this help text
    -i, --input-dir      directory where kaiko data are stored 
                         (defaults to '.')
    -o, --output-dir     directory where extracted data will be stored 
                         (defaults to '.')
    -t, --type           type of data: 'trades', 'book'
                         (defaults to 'trade')
    -e, --exchange       comma-separated list of exchange names 
                         (e.g. 'Quoine,Yobit', default to '*')
    -p, --pairs          comma-separated list of currency pairs 
                         (e.g. 'ETHUSD,ETHEUR', default to '*')
    -c, --concat-by-pair store data for the same exchange / currency-pair 
                         in a single file
    -z, --zip            zip these exchange / currency-pair files
    -m, --manifest       create a manifest file for each exchange / currency 
                         pair, containing the name of all the input files
    -v, --verbose        print feedback about what the script is doing
    -d, --debug          print debug information"

# options with default values
# these variables will be set as readonly later on

OPT_INPUT_DIR='.'     # kaiko zip file repo
OPT_OUTPUT_DIR='.'    # output dir
OPT_TYPE='trades'     # type of data
OPT_TARGET_XCHGS='*'  # exchanges
OPT_TARGET_PAIRS='*'  # currency pairs
OPT_CONCAT=0          # produce a single file for each exchange-pair?
OPT_COMPRESS=0        # compress each exchange-pair csv files?
OPT_MANIFEST=0        # generate per-exchange-pair manifest files?
OPT_VERBOSE=0         # print feedbacks
OPT_DEBUG=0           # print debug info


# print usage
usage(){
  echo "Usage: ${USAGE}" 1>&2
}

# die with an error message
die(){
  local message="$1"

  echo "Error: ${message}. Aborting." 1>&2
  exit 1
}

# check a command is available
check_program(){
  local command="$1"

  command -v "${command}" > /dev/null 2>&1 || {
    die "${command} not installed. Please install ${command}"
  } 
}

# check getopt is available and is GNU getopt
check_getopt(){
  check_program getopt

  # gnu "getopt -T" returns an exit code 4 and no output
  local output
  output=$(getopt -T)
  if (( $? != 4 )) && [[ -n $output ]]; then
    die "non-gnu getopt"
  fi
}


# get and check options 
# side effect: this function sets opt_* global variables
get_and_check_options(){

  local options
  local lo
  local so

  lo="input-dir:,output-dir:,type:,exchange:,pair:,concat-by-pair,zip,\
    manifest,help,verbose,debug"
  so="i:o:t:e:p:czmhvd"

  options=$(getopt --name "${SCRIPT_NAME}" \
    --longoptions  "$lo"\
    --options  "$so" -- "$@")

  [[ $? -eq 0 ]] || {
    usage
    die "invalid option"
  }

  eval set -- "${options}"


  # extract options and their arguments
  while true; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -i|--input-dir)
        OPT_INPUT_DIR=$2
        shift 2 
        ;;
      -o|--output-dir)
        OPT_OUTPUT_DIR=$2
        shift 2
        ;;
      -t|--type)
        OPT_TYPE=$2
        shift 2
        ;;
      -e|--exchange)
        OPT_TARGET_XCHGS=$2
        shift 2
        ;;
      -p|--pair)
        OPT_TARGET_PAIRS=$2
        shift 2
        ;;
      -c|--concat-by-pair)
        OPT_CONCAT=1
        shift
        ;;
      -z|--zip)
        OPT_COMPRESS=1
        shift
        ;;
      -m|--manifest)
        OPT_MANIFEST=1
        shift
        ;;
      -v|--verbose)
        OPT_VERBOSE=1
        shift
        ;;
      -d|--debug)
        OPT_DEBUG=1
        shift
        ;;
      --) 
        shift
        break
        ;;
      *) 
        die "unknown option: $1" ;;
    esac
  done

  # gzip is required if compression is requested
  [[ "${OPT_COMPRESS}" == 1 ]] && {
    check_program gzip
  }


  # check arguments
  [[ -d "${OPT_INPUT_DIR}" ]] || {
    die "invalid option: input directory '${OPT_INPUT_DIR}' does not exist"
  }

  [[ -d "${OPT_OUTPUT_DIR}" ]] || {
    die "invalid option: output directory '${OPT_OUTPUT_DIR}' does not exist"
  }

  [[ "${OPT_TYPE}" == "trades" || "${OPT_TYPE}" == "book" ]] || {
    die "invalid option: unknown data type: '${OPT_TYPE}'"
  }

  local xchg_re='^[a-zA-Z][a-zA-Z0-9-]*(,[a-zA-Z][a-zA-Z0-9-]*)*$'
  [[ "${OPT_TARGET_XCHGS}" == "*" || "${OPT_TARGET_XCHGS}" =~ ${xchg_re} ]] || {
    die "invalid option: invalid exchange name in '${OPT_TARGET_XCHGS}'"
  }

  local pair_re='^[a-zA-Z]+(,[a-zA-Z]+)*$'
  [[ "${OPT_TARGET_PAIRS}" == "*" || "${OPT_TARGET_PAIRS}" =~ ${pair_re} ]] || {
    die "invalid option: invalid currency pair in '${OPT_TARGET_PAIRS}'"
  }
}


main(){
  # some programs are always required 
  check_getopt
  check_program unzip
  check_program gunzip

  # set opt_* global variables
  get_and_check_options "$@"

  readonly OPT_INPUT_DIR
  readonly OPT_OUTPUT_DIR
  readonly OPT_TYPE
  readonly OPT_TARGET_XCHGS
  readonly OPT_TARGET_PAIRS
  readonly OPT_CONCAT
  readonly OPT_COMPRESS
  readonly OPT_MANIFEST
  readonly OPT_VERBOSE
  readonly OPT_DEBUG

  [[ "${OPT_DEBUG}" == 1 ]] && {
    echo "Parameters:"
    echo "  --input-dir       : ${OPT_INPUT_DIR}"
    echo "  --output-dir      : ${OPT_OUTPUT_DIR}"
    echo "  --type            : ${OPT_TYPE}"
    echo "  --exchange        : ${OPT_TARGET_XCHGS}"
    echo "  --pairs           : ${OPT_TARGET_PAIRS}"
    echo "  --concat-by-pair  : ${OPT_CONCAT}"
    echo "  --zip             : ${OPT_COMPRESS}"
    echo "  --manifest        : ${OPT_MANIFEST}"
    echo "  --verbose         : ${OPT_VERBOSE}"
    echo "  --debug           : ${OPT_DEBUG}"
  }


  local TMP_DIR
  local TMP_CSV_FILE
  local TMP_LS_FILE

  # temp dir where to unzip archive files
  TMP_DIR=$(mktemp -d)
  [[ "$?" -ne 0 ]] && {
    die "unable to create temporary directory"
  }

  # temp file for csv data
  TMP_CSV_FILE=$(mktemp)
  [[ "$?" -ne 0 ]] && {
    die "unable to create temporary csv file"
  }

  # temp file for list of files
  TMP_LS_FILE=$(mktemp)
  [[ "$?" -ne 0 ]] && {
    die "unable to create temporary file list"
  }

  readonly TMP_DIR
  readonly TMP_CSV_FILE
  readonly TMP_LS_FILE

  # cleanups on exit
  function finish {
    [[ -d "${TMP_DIR}" ]] && {
      rm -rf "${TMP_DIR:?}"
    }
    [[ -s "${TMP_CSV_FILE}" ]] && {
      rm -f "${TMP_CSV_FILE:?}"
    }
    [[ -s "${TMP_LS_FILE}" ]] && {
      rm -f "${TMP_LS_FILE:?}"
    }
  }
  trap finish EXIT

  # this keeps "for...in" from returning the pattern itself when 
  #   no files match
  shopt -s nullglob


  local data_file_prefix
  local target_xchgs_re
  local target_pair_re
  local file_counter
  local zipfile
  local fname
  local xchg
  local base_name
  local manifest_file
  local one_csv_file
  local csv_file

  # data file prefix
  if [[ "${OPT_TYPE}" == "trades" ]]; then
    data_file_prefix="trades"
  else
    data_file_prefix="ob_10"
  fi

  # regex for exchanges e.g. ^(BTC38|Btcbox)$
  if [[ "${OPT_TARGET_XCHGS}" == "*" ]]; then
    target_xchgs_re="."
  else
    target_xchgs_re="^(${OPT_TARGET_XCHGS//,/|})$"
  fi

  # regex for currency pairs, e.g. ^(YBCCNY|LTCCNY)$
  if [[ "${OPT_TARGET_PAIRS}" == "*" ]]; then
    target_pair_re="."
  else
    target_pair_re="^(${OPT_TARGET_PAIRS//,/|})$"
  fi

  [[ "${OPT_DEBUG}" == 1 ]] && {
    echo "Regular expressions:"
    echo "  for exchanges: ${target_xchgs_re}"
    echo "  for currency pairs: ${target_pair_re}"
  }

  # number of data files processed so far
  file_counter=0

  # for each zip file in the input directory, extract the data requested
  for zipfile in "${OPT_INPUT_DIR}/${data_file_prefix}"_*.zip; do

    # extract exchange name from zip file name
    fname=$(basename "${zipfile}" .zip)
    xchg=${fname#"${data_file_prefix}"_}


    if [[ "${xchg}" =~ ${target_xchgs_re} ]]; then

      [[ "${OPT_DEBUG}" == 1 ]] && {
        echo "Looking into zipfile '${zipfile}'"
        echo "Exchange is '${xchg}'"
      }

      file_counter=$((file_counter+1))

      unzip -d "${TMP_DIR}" -q "${zipfile}"
      [[ "$?" -ne 0 ]] && {
        die "unable to unzip '${zipfile}'"
      }

      # quick fix for MtGox trade data zip file (extra root folder)
      [[ "${OPT_TYPE}" == "trades" && "${xchg}" == 'mtgox' ]] && {
        mv "${TMP_DIR}/trades_mtgox/mtgox" "${TMP_DIR}/"
        rmdir "${TMP_DIR}/trades_mtgox"
      }

      # directory structure is, e.g., Gatecoin/ETHEUR
      for ticker in $(find "${TMP_DIR}/$xchg" -mindepth 1 -maxdepth 1 \
          -type d -exec basename {} \;) ; do
        if [[ "${ticker}" =~ $target_pair_re ]]; then

          [[ "${OPT_VERBOSE}" == 1 ]] && {
            echo "Extracting ${ticker} from ${xchg}..."
          }

          # sorted list of full filenames to process
          find "${TMP_DIR}/${xchg}/${ticker}" -mindepth 1 -type f -name "*.gz" \
            -print \
            | sort > "${TMP_LS_FILE}"

          # ticker folder exists, but has no gz files in it
          if [[ ! -s "${TMP_LS_FILE}" ]]; then
            continue
          fi

          # base name used for manifest and csv output files
          base_name="${xchg}_${ticker}_${data_file_prefix}"

          # when requested, create a manifest file containing a list 
          #   of all the data files found  for each exchange-pair
          [[ "${OPT_MANIFEST}" == 1 ]] && {
            manifest_file="${OPT_OUTPUT_DIR}/${base_name}.manifest"
            sed 's!.*/!!' "${TMP_LS_FILE}" | sort > "${manifest_file}"
          }
          

          if [[ "${OPT_CONCAT}" == 1 ]]; then

            csv_file="${OPT_OUTPUT_DIR}/${base_name}.csv"
            rm -f "${csv_file}"

            # extract a header from one of the gz daily files
            one_csv_file=$(find "${TMP_DIR}/${xchg}/${ticker}" -mindepth 1 \
              -type f -name "*.gz"  \
              | head -1)

            gunzip -c "${one_csv_file}" | head -1 > "${csv_file}"
            [[ -s "${csv_file}" ]] || {
              die "unable to get header line from '${one_csv_file##*/}'"
            }
        
            # append the contents to the csv files, sorted by unix 
            #   timestamp (fourth column), using stable (-s) sort 
            #   to keep lines with equal timestamp in original 
            #   record order
            # grep -v excludes the header line of each input file 
            #   ("date" is a field that exists in both trade and 
            #   book files)
            find "${TMP_DIR}/${xchg}/${ticker}" -mindepth 1 -type f \
              -name "*.gz" -exec cat {} \; \
              | gunzip -c \
              | grep -v "date," \
              | sort -t',' -s -n -k4 >> "${csv_file}"

              [[ "${PIPESTATUS[0]}" -ne 0 \
                || "${PIPESTATUS[1]}" -ne 0 \
                || "${PIPESTATUS[2]}" -ne 0 \
                || "${PIPESTATUS[3]}" -ne 0 ]] && {
                die "unable to create '${csv_file}'"
              }

            # compress if requested
            [[ "${OPT_COMPRESS}" == 1 ]] && {
              gzip -f "${csv_file}"
              [[ "$?" -ne 0 ]] && {
                die "unable to zip '${csv_file}'"
              }
            }
          else
            # just copy the data files
            find "${TMP_DIR}/${xchg}/${ticker}" -mindepth 1 -type f \
              -name "*.gz" -exec cp -a "{}" "${OPT_OUTPUT_DIR}/" \; 
            [[ "$?" -ne 0 ]] && {
              die "copy of data files failed'"
            }
          fi
        fi
      done

      # delete all tmp files for the current exchange to avoid running 
      #   out of disk space
      [[ -d "${TMP_DIR}/${xchg}" ]] && {
        rm -rf "${TMP_DIR:?}/${xchg:?}"
      }
    fi
  done

  [[ "${file_counter}" == 0 ]] && {
    echo "Nothing to do"
  }

  [[ "${file_counter}" -gt 0 && "${OPT_VERBOSE}" == 1 ]] && {
    echo "${file_counter} zip files processed"
  }
}

main "$@"
exit 0
