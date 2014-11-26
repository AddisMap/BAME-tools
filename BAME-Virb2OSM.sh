#!/bin/bash

# Copyright (c) 2014 by Bandira AddisMap Entertainment P.L.C., Addis Ababa, Ethiopia
# Portions Copyright (c) by OSM Wiki User Didier2020 http://wiki.openstreetmap.org/w/index.php?title=Video_mapping&oldid=993177
# License: Creative Commons Attribution-ShareAlike 2.0



# README
#
# Please adapt the following constants before the first use
# The script is meant to be used by draging the GPX file on it (or supplying it as first parameter)
# Please make sure you use the newest firmware

### constants to be adapted ###


# Target dir for geocoded pictures
# a subdirectory according to the gpx timestamp is automatically added
TARGETDIR="/home/me/output/goes/here"

# set framerate (important)
# for 30fps (NTSC) set to 1 - so every one second a frame is extracted
# for timelapse - once per second, please set to 30 so every frame is extracted

#RATE=""     # time lapse
RATE="-r 1"  # 30 fps


gpxfile=$1

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

echo Extracting frames at $RATE Hz rate
#-ss 1
ffmpeg -i $videofile $RATE -ss 1 -y -an -q:v 0 -f image2 "$target/pic%05d.jpg"
# Get video date/time from exif info
echo Initially set time/date for all files at the beginning of the video file
exiftool -overwrite_original -CreateDate="`exiftool -TrackCreateDate -S $videofile | sed 's/.*: //' `" "$target"/pic*.jpg
# Adjust time of each jpeg
num=0 #num of seconds to add

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
# we might use
exiftool -overwrite_original -geosync=-$offset -geotag "$gpxfile" "-geotime<CreateDate" -P "$target"/pic*.jpg


cp "$gpxfile" "$target"/"$base".gpx

echo "done"