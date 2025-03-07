#!/bin/bash

output_name=delphes.root

show_help() {
	echo "Setup staging area and run pythia/delphes in isolation."
	echo "Usage: $0 [options] input_file"
	echo "  -o OUTPUT_PATH    The destination path for output file. (Default: same path as input file)"
	echo "  -n OUTPUT_NAME    The output filename. (Default: $output_name)"
}

while getopts ":h?o:n:" opt; do
    case "$opt" in
    h) show_help
       exit 0
       ;;
    o) output_path=$OPTARG
       ;;
    n) output_name=$OPTARG
       ;;
   \?) echo "Invalid option: -$OPTARG" >&2
       show_help
       exit 1
       ;;
    :) echo "Option: -$OPTARG requires argument." >&2
       show_help
       exit 1
       ;;
    esac
done

shift $((OPTIND-1))
input_file=$1

if [ $# -lt 1 ]; then
	echo "No input file provided! Abort." >&2
	show_help
	exit 1
fi

if [ ! -e "$input_file" ]; then
	echo "Cannot find input file. Abort." >&2
	exit 1
fi

if [ -z "$output_path" ]; then
	output_path=/gdata/atlas/$(whoami)
	echo "No output path provided, using $output_path"
fi

if [ ! -z "$SLURM_JOB_ID" ]; then
	echo "Slurm environment detected! Running on $(hostname)."
	echo "Will use local scratch."
	stage_path=/scratch/$(whoami)/delphes_${SLURM_JOB_ID}
	mkdir -p $stage_path
else
	stage_path=$(mktemp -d)
fi

if [ ! -d "$stage_path" ]; then
	echo "Error creating staging path in $stage_path! Abort." >&2
	exit 1
fi

output_file=$output_path/$output_name

# source the configuration environment
if [ -e config.sh ]; then
	source config.sh
fi

if [ -z "$PYTHIA_DIR" ]; then
	echo "PYTHIA_DIR variable not defined!" >&2
	exit 1
fi

if [ -z "$DELPHES_DIR" ]; then
	echo "DELPHES_DIR variable not defined!" >&2
	exit 1
fi

clean_stage() {
	echo "Removing staging area at $stage_path"
	rm -rf $stage_path
}

# setup the working directory for pythia and delphes to run in
echo "Staging in $stage_path"
./scripts/stage.sh $input_file $stage_path

if [ $? -ne 0 ]; then
	echo "Staging failed!" >&2
	clean_stage
	exit 1
fi

# move to the stage and run the processing scripts
echo "Running scripts..."
pushd $stage_path/run

./process_lhef.sh
process_code=$?

popd

if [ $process_code -ne 0 ]; then
	echo "Processing failed! Code=$process_code" >&2
	clean_stage
	exit $process_code
fi

echo "Copying output file..."
echo "cp $stage_path/run/delphes.root $output_file"
cp $stage_path/run/delphes.root $output_file

if [ $? -ne 0 ]; then
	echo "Failed to copy delphes file!" >&2
	clean_stage
	exit 1
fi

clean_stage
