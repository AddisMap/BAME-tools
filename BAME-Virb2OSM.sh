#!/bin/bash

# Copyright (c) 2014 by Bandira AddisMap Entertainment P.L.C., Addis Ababa, Ethiopia
# Portions Copyright (c) by OSM Wiki User Didier2020 http://wiki.openstreetmap.org/w/index.php?title=Video_mapping&oldid=993177
# License: Creative Commons Attribution-ShareAlike 2.0




# README
#
# Please adapt the following constants before the first use
# The script is meant to be used by draging the GPX file on it (or supplying it as first parameter)
# Please make sure you use the newest firmware
#
# Please add a file ".BAME-Virb2OSM.conf" based on the file delivered
#
# Requirements
#
# imagmagick
# ffpmpeg
# exiftool
#
# for ffpmpeg
#
# sudo apt-add-repository ppa:jon-severinsson/ffmpeg
# apt-get install ffmpeg
source ~/.BAME-Virb2OSM.conf

while [ $# -ne 0 ]
    do

    gpxfile=$1

    echo "############### Processing $1 ############## "
    videofilerelative=`grep -Po '</name><link href="\K[^\"]*' "$1" | tr "\\\\" "\/"`
    offset=`grep -Po '<gpxtrkoffx:StartOffsetSecs>(\K[^<]*)' "$1"`

    # go three folders back
    dn2=`dirname "$gpxfile"`

    if [ "$dn2" == "." ]; then
        dn='../..'
    else
        dn1=`dirname "$dn2"`
        if [ "$dn1" == "." ]; then
            dn='..'
        else
            dn=`dirname "$dn1"`
        fi
    fi

    videofile=$dn$videofilerelative
    base=`basename "$gpxfile" | sed "s/ /-/" | sed "s/_//" | sed "s/Track//" | sed "s/.gpx//"`
    echo "Video file: $videofile"
    echo "Offset: $offset"

    target="$TARGETDIR"/$base
    mkdir -p $target
    echo "Target: $target"

    echo Extracting frames with rate $RATE
    #-ss 1
    ffmpeg -v error -stats -i $videofile $RATE -ss 1 -y -an -q:v 0 -f image2 "$target/pic%05d.jpg"
    # Get video date/time from exif info
    echo Initially set time/date for all files at the beginning of the video file
    exiftool -overwrite_original -CreateDate="`exiftool -TrackCreateDate -S $videofile | sed 's/.*: //' `" "$target"/pic*.jpg
    # Adjust time of each jpeg
    num=0 #num of seconds to add

    find "$target" -name "pic*.jpg" -exec mogrify -quality 50 {} \;

    echo "Setting time +1 second for each"
    for file in "$target"/pic*.jpg
    do
     exiftool -overwrite_original -CreateDate+=0:00:$num $file > /dev/null # adjust file 1 +1s, file2 +2s, ..
     num=$(( $num + 1 ))
     echo -n "."
     if [ $(( $num % 25 )) -eq 0 ]; then
       echo $num;
     fi
    done

    echo ""

    echo "Geotagging"
    # offset: -$offset + 2 videotime - gpxname
    exiftool -overwrite_original -geosync=-1 -geotag "$gpxfile" "-geotime<CreateDate" -P "$target"/pic*.jpg


    cp "$gpxfile" "$target"/"$base".gpx

    echo "done"

    shift
done
