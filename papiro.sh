#!/bin/bash

# Project: https://github.com/dtonon/papiro

# Idea from https://www.grant-trebbin.com/2015/05/encode-and-decode-file-backed-up-as.html

function show_help {      
    echo -e "Papiro encodes and decodes file(s) to/from QR Codes, to print and store them phisically."
    echo -e "You can encode a single file or a full directory, in this latter case the data are zipped before the encoding."
    echo -e "The qrcodes are saved in a single pdf, ready to print; the rebuild process is done on a group of acquired photos."
    echo -e "\nUsage"
    echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n";
    echo -e "\033[1mEncode a file in qrcodes\033[0m\n./papiro.sh -c file|directory [-za] [-l L|M|Q|H] [-o file.pdf]\n"
    echo -e "\033[1mRebuild file from photos\033[0m\n./papiro.sh -r source_directory [-o rebuild_file]\n"
    echo -e "\033[1mCreate an encrypted txt\033[0m\n./papiro.sh -x [-o rebuild_file]\n"
    echo -e "Options"
    echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n";
    echo -e "\033[1m-z\033[0m\tZip the file(s) to reduce the number of QR Codes"
    echo -e "\033[1m-l\033[0m\tSet the QR Codes error correction level (L|M|Q|H); default is L(ow)"
    echo -e "\033[1m-o\033[0m\tSet the output filename"
    echo -e "\033[1m-a\033[0m\tAnonymous mode, don't annotate the original filename"
    echo -e "\033[1m-s\033[0m\tCreate a papiro of the script itself, useful for archiving with the encoded data"
    echo -e "\033[1m-h\033[0m\tShow this help"
    echo -e "\033[1m-d\033[0m\tDebug mode"
    echo -e "\nExamples"
    echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n";
    echo "Encode a file to qrcodes: ./papiro.sh -c myfile.jpg"
    echo "Zip and encode a file to qrcodes: ./papiro.sh -c divina-commedia.txt -z"
    echo "Encode a file with the best error correction: ./papiro.sh -c important-data.xml -lH "
    echo "Encode a directory to qrcodes (using a zip file): ./papiro.sh -c mydata/"
    echo "Decode a group of images to rebuild a file: ./papiro.sh -r photos/ -o myfile.jpg"
}

function show_help_hint {      
    echo -e "Try ./papiro -h to see the help and some examples"
}

# Create a tmp dir
work_dir=`mktemp -d`
if [[ ! "$work_dir" || ! -d "$work_dir" ]]; then echo "Could not create the temp dir"; exit 1; fi

echo "" # Blank line for readibility

# Parse the flags
while getopts "c:azl:xr:o:sdh" flag
do
    case "${flag}" in
        c) encode_source=${OPTARG};;
        a) anonymous="ON";;
        z) zip="ON";;
        l) error_correction_level=${OPTARG};;
        x) new_secret="ON";;
        r) decode_dir=${OPTARG};;
        o) decode_output=${OPTARG};;
        s) encode_myself="ON";;
        d) debug="ON";;
        h) help="ON";;
    esac
done

# If invoked with the debug (-d) flag create a temp directory or empty if it alredy exists
if [ -n "$debug" ]; then
    debug_dir="papiro-debug"
    echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -";
    echo "=> Debug mode is active";
    mkdir -p $PWD/$debug_dir;
    rm -rf $PWD/$debug_dir/*;
    echo -e "  Work_dir: $work_dir\n  \033[1mRemember to clear it manually\033[0m"
    echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n";
else
    # The work temp dir will be cleared automatically on the exit
    trap "rm -rf "$work_dir"" EXIT
fi

date_human=$(date "+%Y-%m-%d %H:%M")
date_file=$(date "+%Y%m%d-%H%M%S")

# If invoked with the -x flag, create a new encrypted vim file, then use it for the encoding
if [ -n "$encode_myself" ]; then
    echo -e "=> Papiro self mode: I'm going to generate a papiro of myself!"
    encode_source=`basename $0`

    # Disable the zip in self mode
    if [ -n "$zip" ]; then
        echo -e "=> \033[1mWarning\033[0m: using the self mode with Zip is technically possibile but not very useful, because it is hard to rebuild a binary file. Let's go on with a plain txt :)"
        unset zip
    fi

fi

# If invoked with the -x flag, create a new encrypted vim file, then use it for the encoding
if [ -n "$new_secret" ]; then
    encode_source="secret-$date_file"
    vim -xn $encode_source
fi

# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
#
# ENCONDE
# If invoked with the -c flag process the file to create the qrcodes-papiro pdf
#
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

if [ -n "$encode_source" ]; then
    if ! [[ -f "$encode_source" || -d "$encode_source" ]]; then echo -e "Error: file not found"; show_help_hint; exit 2; fi

    # If the source is a directory automatically activate the zip mode
    if [ -d "$encode_source" ]; then echo "=> Directory detected: automatically activate the Zip mode"; zip="ON"; fi

    # If invoked with the anonymous flag (-a) set the label_file and pdf_file accor accordingly to avoid to store the filename
    if [ -n "$anonymous" ]; then
        echo "=> Anonymous mode"
        output_file="xxxxxxxxxxxxxxxx"
        label_file="***************"
    else
        output_file=$(basename -- $encode_source)
        label_file=$output_file
        
    fi

    # Set the split chunk size according to the error correction, default is L(ow)
    case $error_correction_level in
    "L" | "")
        error_correction_level="L"
        split_chunk=2953;;
    "M")
        split_chunk=2331;;
    "Q")
        split_chunk=1663;;
    "H")
        split_chunk=1273;;
    *)
        echo "Error: bad correction level code, valid values are L, M, Q, and H"; show_help_hint;
        exit 2
        ;;
    esac

    echo "=> Error correction level: $error_correction_level"

    if [ -n "$decode_output" ]; then
        pdf_file=$decode_output
    elif [ -n "$anonymous" ]; then
        pdf_file="qrcodes-$date_file.pdf"
    else
        pdf_file=$PWD/qrcodes-$label_file.pdf
    fi

    work_file="$work_dir/$output_file"
    cp -R $encode_source $work_file

    if [ -n "$zip" ]; then
        echo "=> Zip mode"
        # Cannot use the split (-s -sp) option because 64k is the minimum split size
        # TODO add -q optin for suppress output
        current_position=$PWD
        cd $work_dir
        zip -r -9 "$(basename -- $work_file.zip)" "$(basename -- $work_file)"
        work_file=$work_file.zip
        encode_source=$work_file
        cd "$current_position"
    fi

    # Calculate the checksum, it is included in the pdf for a future integrity check
    checksum=$(shasum -a 256 $encode_source | cut -f 1 -d ' ')
    echo "=> SHA256 signature: $checksum"

    echo "=> Encoding $encode_source to qrcodes"

    # Split the file in chunks of 1273 bytes. This is the max size for a qrcode v40 (177x177) with hight (H) error correction code level (ECC)
    # Check https://www.qrcode.com/en/about/version.html for more details
    split -b $split_chunk $work_file $work_file.split

    # Encode the files in a qrcode 177x177, hight correction mode
    for file in $work_file.split*; do qrencode --8bit -v 40 -l $error_correction_level -o $file.png -r $file; done

    # Get the qrcodes count
    total_files=`ls $work_file.split*.png | wc -l | sed "s/ *//g"`

    # Add a label to every qrcode
    counter=1; for file in $work_file.split*.png; do convert -comment "$label_file\n$date_human    |    $counter of $total_files parts" $file $file; counter=$((counter+1)); done
    if [ -n "$debug" ]; then cp $work_dir/*.png $PWD/$debug_dir/; fi

    # Create a multipage pdf and optimize its size
    title="\n\n$label_file | $date_human\nsha256: $checksum"
    if [ -n "$encode_myself" ]; then title="$title\nScan the qrcodes and merge the content in a unique text file, rename it to papiro.sh, run it"; fi
    montage -pointsize 20 -label '%c' $work_dir/*.png -title "$title" -geometry "1x1<" -tile 3x4 $pdf_file
    convert $pdf_file -border 40 -type bilevel -compress fax $pdf_file

    echo -e "\nYour Papiro is ready to print: $pdf_file"


# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
#
# DECODE
# If invoked with the -r flag process the photos' dir to rebuild the original file
#
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

elif [ -n "$decode_dir" ]; then
    if ! [[ -d "$decode_dir" ]]; then echo -e "Error: directory not found"; show_help_hint; exit 2; fi
    echo "Decoding $decode_dir/*"
    if [ -n "$decode_output" ]; then decode_output=$decode_output; else decode_output="decoded_file"; fi

    # Optimize the scanned images
    mkdir $work_dir/pics
    for file in $decode_dir/*; do convert "$file" -quiet -morphology open square:1 -threshold 50% "$work_dir/pics/$(basename -- $file).png"; done
    if [ -n "$debug" ]; then cp $work_dir/pics/* $PWD/$debug_dir/; fi

    # Scan optimized qrcodes and concatenate data to a unique file
    counter=1; for file in $work_dir/pics/*
    do
        zbar_output=$( (zbarimg --raw --oneshot -Sbinary -Sdisable -Sqr.enable "$file" >> $work_dir/restore) 2>&1 > /dev/null)
        if [[ $zbar_output == *"not detected"* ]]; then echo "Error: no content found in the qrcode #$counter, check the image quality"; exit 1; fi
        counter=$((counter+1))
    done
    cp "$work_dir/restore" "$decode_output"

    # Add zip extension automatically
    file_type=`file -b $decode_output`
    if [[ $file_type == *"Zip"* ]] && [[ ! $decode_output == *"zip" ]]; then
        echo "=> Detected a Zip file: add the extension"
        mv "$decode_output" "$decode_output.zip"
        decode_output="$decode_output.zip"
    fi

    echo -e "\n=> File rebuild from papiro: $decode_output"
    echo -e "=> SHA256 signature: $(shasum -a 256 $decode_output | cut -f 1 -d ' ')"

else

    show_help

fi