#!/bin/bash

# Idea from https://www.grant-trebbin.com/2015/05/encode-and-decode-file-backed-up-as.html

# Create a tmp dir
WORK_DIR=`mktemp -d`
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then echo "Could not create the temp dir"; exit 1; fi

while getopts "e:d:o:z" flag
do
    case "${flag}" in
        e) encode_file=${OPTARG};;
        d) decode_dir=${OPTARG};;
        o) decode_output=${OPTARG};;
        z) debug="ON";;
    esac
done

# Create the debug directory or empty if it alredy exists
if [ -n "$debug" ]; then echo "DEBUG active"; mkdir $PWD/debug; rm $PWD/debug/*; fi

if [ -n "$encode_file" ]; then
    if ! [[ -f "$encode_file" ]]; then echo "Error: file not found"; exit 2; fi
    echo "Encoding $encode_file..."
    checksum=$(shasum $encode_file | cut -f 1 -d ' ')
    echo "SHA1 signature: $checksum"

    WORK_FILE="$WORK_DIR/$encode_file"
    base64 $encode_file > $WORK_FILE.base64
    split -b 1273 $WORK_FILE.base64 $WORK_FILE.split
    for file in $WORK_FILE.split*; do qrencode --8bit -v 40 --margin=10 -l H -o $file.png < $file; done
    total_files=`ls $WORK_FILE.split*.png | wc -l`
    total_files=`echo $total_files | sed 's/ *$//g'`
    counter=1
    date=$(date "+%Y-%m-%d %H:%M")
    for file in $WORK_FILE.split*.png; do convert -comment "$encode_file    |    $date    |    $counter of $total_files parts\nsha1: $checksum\n" $file $file; counter=$((counter+1)); done
    if [ -n "$debug" ]; then cp $WORK_DIR/*.png $PWD/debug/; fi
    montage -label '%c' $WORK_DIR/*.png -geometry "1x1<" -tile 3x4 $PWD/print-$encode_file.pdf
    echo "File ready to print: $PWD/print-$encode_file.pdf"

elif [ -n "$decode_dir" ]; then
    if ! [[ -d "$decode_dir" ]]; then echo "Error: directory not found"; exit 2; fi
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
    echo "Papiro: encode/decode a file to/from qrcodes"
    echo "---"
    echo "Encode a file: papiro -e myfile.pdf"
    echo "Decode a group of images: papiro -d photos/ -o myfile.pdf"
    echo "Options:"
    echo "-z Debug: create a debug/ dir with the intermediate images"

fi

# deletes the temp directory
function cleanup {      
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT