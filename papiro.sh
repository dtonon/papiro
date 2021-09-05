#!/bin/bash

# Idea from https://www.grant-trebbin.com/2015/05/encode-and-decode-file-backed-up-as.html

function show_help {      
    echo -e "\nPapiro encodes and decodes a file to/from qrcodes, to store it phisically."
    echo -e "The qrcodes are saved in a single pdf, ready to print; the rebuild process is done on a group of acquired photos."
    echo -e "\nUsage:\n"
    echo -e "\033[1mEncode a file in qrcodes\033[0m:\n./papiro.sh -c source_file [-a] [-o file.pdf]\n"
    echo -e "\033[1mRebuild file from photos\033[0m:\n./papiro.sh -r source_directory [-o rebuild_file]\n"
    echo -e "\033[1mCreate an encrypted txt\033[0m:\n./papiro.sh -x [-o rebuild_file]\n"
    echo -e "\nOptions:"
    echo -e "\033[1m-a\033[0m\tAnonymous mode, don't annotate the original filename for increased privacy"
    echo -e "\033[1m-o\033[0m\tSpecify the output filename"
    echo -e "\033[1m-d\033[0m\tDebug mode, create a debug/ dir with the temp images"
    echo -e "\033[1m-h\033[0m\tGet this help"
    echo -e "\nExamples:"
    echo "Encode a file to qrcodes: ./papiro.sh -c myfile.jpg"
    echo "Decode a group of images to rebuild a file: ./papiro.sh -r photos/ -o myfile.jpg"
}

# Create a tmp dir
work_dir=`mktemp -d`
if [[ ! "$work_dir" || ! -d "$work_dir" ]]; then echo "Could not create the temp dir"; exit 1; fi

# The temp dir will be cleared automatically on the exit
trap "rm -rf "$work_dir"" EXIT

# Parse the flags
while getopts "c:axr:o:dh" flag
do
    case "${flag}" in
        c) encode_file=${OPTARG};;
        a) anonymous="ON";;
        x) new_secret="ON";;
        r) decode_dir=${OPTARG};;
        o) decode_output=${OPTARG};;
        d) debug="ON";;
        h) help="ON";;
    esac
done

# If invoked with the debug (-d) flag create a temp directory or empty if it alredy exists
if [ -n "$debug" ]; then echo "DEBUG active"; mkdir $PWD/debug; rm $PWD/debug/*; fi

date_human=$(date "+%Y-%m-%d %H:%M")
date_file=$(date "+%Y%m%d-%H%M%S")

# If invoked with the -x flag, create a new encrypted vim file, then use it for the encoding
if [ -n "$new_secret" ]; then
    encode_file="secret-$date_file"
    vim -xn $encode_file
fi

# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
#
# ENCONDE
# If invoked with the -c flag process the file to create the qrcodes-papiro pdf
#
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

if [ -n "$encode_file" ]; then
    if ! [[ -f "$encode_file" ]]; then echo -e "\nError: file not found"; show_help; exit 2; fi
    echo "Encoding $encode_file..."

    # If invoked with the anonymous flag (-a) set the label_file and pdf_file accor accordingly to avoid to store the filename
    if [ -n "$anonymous" ]; then
        echo "Anonymous mode"
        output_file="xxxxxxxxxxxxxxxx"
        label_file="***************"
    else
        output_file=$(basename -- $encode_file)
        label_file=$output_file
        
    fi

    if [ -n "$decode_output" ]; then
        pdf_file=$decode_output
    elif [ -n "$anonymous" ]; then
        pdf_file="qrcodes-$date_file.pdf"
    else
        pdf_file=$PWD/qrcodes-$label_file.pdf
    fi

    # Calculate the checksum, it is included in the pdf for a future integrity check
    checksum=$(shasum -a 256 $encode_file | cut -f 1 -d ' ')
    echo "SHA256 signature: $checksum"

    work_file="$work_dir/$output_file"
    cp $encode_file $work_file

    # Split the file in chunks of 1273 bytes. This is the max size for a qrcode v40 (177x177) with hight (H) error correction code level (ECC)
    # Check https://www.qrcode.com/en/about/version.html for more details
    split -b 1273 $work_file $work_file.split

    # Encode the files in a qrcode 177x177, hight correction mode
    for file in $work_file.split*; do qrencode --8bit -v 40 -l H -o $file.png -r $file; done

    # Get the qrcodes count
    total_files=`ls $work_file.split*.png | wc -l | sed "s/ *//g"`

    # Add a label to every qrcode
    counter=1; for file in $work_file.split*.png; do convert -comment "$label_file\n$date_human    |    $counter of $total_files parts" $file $file; counter=$((counter+1)); done
    if [ -n "$debug" ]; then cp $work_dir/*.png $PWD/debug/; fi

    # Create a multipage pdf and optimize its size
    montage -pointsize 20 -label '%c' $work_dir/*.png -title "\n$label_file | $date_human\nsha256: $checksum" -geometry "1x1<" -tile 3x4 $pdf_file
    convert $pdf_file -border 40 -type bilevel -compress fax $pdf_file

    echo "Your Papiro is ready to print: $pdf_file"


# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
#
# DECODE
# If invoked with the -r flag process the photos' dir to rebuild the original file
#
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

elif [ -n "$decode_dir" ]; then
    if ! [[ -d "$decode_dir" ]]; then echo -e "\nError: directory not found"; show_help; exit 2; fi
    echo "Decoding $decode_dir..."
    if [ -n "$decode_output" ]; then OUTPUT=$decode_output; else OUTPUT="decoded_file"; fi

    # Optimize the scanned images
    mkdir $work_dir/pics
    for file in $decode_dir/*; do convert $file -quiet -morphology open square:1 -threshold 50% $work_dir/pics/$(basename -- $file).png; done
    if [ -n "$debug" ]; then cp $work_dir/pics/* $PWD/debug/; fi

    # Scan optimized qrcodes and concatenate data to a unique file
    counter=1; for file in $work_dir/pics/*
    do
        zbar_output=$( (zbarimg --raw --oneshot -Sbinary -Sdisable -Sqr.enable $file >> $work_dir/restore) 2>&1 > /dev/null)
        if [[ $zbar_output == *"not detected"* ]]; then echo "Error: no content found in the qrcode #$counter, check the image quality"; exit 1; fi
        counter=$((counter+1))
    done
    cp $work_dir/restore $OUTPUT

    echo "File rebuild from papiro: $OUTPUT"
    echo "SHA256 signature: $(shasum -a 256 $OUTPUT | cut -f 1 -d ' ')"

else

    show_help

fi