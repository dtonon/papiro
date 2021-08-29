#!/bin/bash

# Idea from https://www.grant-trebbin.com/2015/05/encode-and-decode-file-backed-up-as.html

function show_help {      
    echo -e "\nPapiro encodes and decodes a file to/from qrcodes."
    echo -e "The qrcodes are saved in a single pdf, ready to print; the rebuild process is done on a group of photos."
    echo -e "\nUsage:"
    echo -e "\033[1mCreate qrcodes\033[0m:\tpapiro.sh [-c] source_file [-a] [-o file.pdf]"
    echo -e "\033[1mRebuild file\033[0m:\tpapiro.sh [-r] source_directory [-o rebuild_file]"
    echo -e "\nOptions:"
    echo -e "\033[1m-a\033[0m\tAnonymous mode, don't annotate the original filename to increase the privacy"
    echo -e "\033[1m-o\033[0m\tSpecify the output filename"
    echo -e "\033[1m-z\033[0m\tDebug mode, create a debug/ dir with the temp images"
    echo -e "\nExamples:"
    echo "Encode a file to qrcodes: ./papiro.sh -c myfile.jpg"
    echo "Decode a group of images to rebuild a file: ./papiro.sh -r photos/ -o myfile.jpg"
}

# Create a tmp dir
WORK_DIR=`mktemp -d`
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then echo "Could not create the temp dir"; exit 1; fi

while getopts "c:ar:o:dh" flag
do
    case "${flag}" in
        c) encode_file=${OPTARG};;
        a) anonymous="ON";;
        r) decode_dir=${OPTARG};;
        o) decode_output=${OPTARG};;
        d) debug="ON";;
        h) help="ON";;
    esac
done

# Create the debug directory or empty if it alredy exists
if [ -n "$debug" ]; then echo "DEBUG active"; mkdir $PWD/debug; rm $PWD/debug/*; fi

if [ -n "$encode_file" ]; then
    if ! [[ -f "$encode_file" ]]; then echo -e "\nError: file not found"; show_help; exit 2; fi
    date=$(date "+%Y-%m-%d %H:%M")
    date_file=$(date "+%Y%m%d-%H%M")
    if [ -n "$anonymous" ]; then label_file="xxxxxxx-$date_file"; echo "Anonymous mode ON";  else label_file=$encode_file; fi
    if [ -n "$decode_output" ]; then pdf_file=$decode_output; else pdf_file=$PWD/print-$label_file.pdf; fi
    echo "Encoding $encode_file..."
    checksum=$(shasum $encode_file | cut -f 1 -d ' ')
    echo "SHA1 signature: $checksum"

    WORK_FILE="$WORK_DIR/$label_file"
    base64 $encode_file > $WORK_FILE.base64
    split -b 1273 $WORK_FILE.base64 $WORK_FILE.split
    for file in $WORK_FILE.split*; do qrencode --8bit -v 40 --margin=10 -l H -o $file.png < $file; done
    total_files=`ls $WORK_FILE.split*.png | wc -l`
    total_files=`echo $total_files | sed 's/ *$//g'`
    counter=1
    for file in $WORK_FILE.split*.png; do convert -comment "$label_file    |    $date    |    $counter of $total_files parts\nsha1: $checksum\n" $file $file; counter=$((counter+1)); done
    if [ -n "$debug" ]; then cp $WORK_DIR/*.png $PWD/debug/; fi
    montage -label '%c' $WORK_DIR/*.png -geometry "1x1<" -tile 3x4 $pdf_file
    echo "File ready to print: $pdf_file"

elif [ -n "$decode_dir" ]; then
    if ! [[ -d "$decode_dir" ]]; then echo -e "\nError: directory not found"; show_help; exit 2; fi
    echo "Decoding $decode_dir..."
    if [ -n "$decode_output" ]; then OUTPUT=$decode_output; else OUTPUT="decoded_file"; fi

    mkdir $WORK_DIR/pics
    for file in $decode_dir/*; do convert $file -quiet -morphology open square:1 -threshold 50% $WORK_DIR/pics/$(basename -- $file).png; done
    if [ -n "$debug" ]; then cp $WORK_DIR/pics/* $PWD/debug/; fi

    counter=1; for file in $WORK_DIR/pics/*
    do
        STRING=`zbarimg --raw -q $file`
        if ! [ -n "$STRING" ]; then echo "Error: no content found in the qrcode #$counter, check the image quality"; exit 1; fi
        echo $STRING >> $WORK_DIR/restore.base64
        counter=$((counter+1))
    done

    base64 -d $WORK_DIR/restore.base64 > $OUTPUT
    echo "File rebuild from paper: $OUTPUT"
    echo "SHA1 signature: $(shasum $OUTPUT | cut -f 1 -d ' ')"

else
    show_help

fi

# deletes the temp directory
function cleanup {      
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT