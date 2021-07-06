#!/bin/bash

template=$1
library=$2
staging=$3

cat $template

#keywords - rest

#parse template
    # return [names & parameters]

#create step-video - staging location to create
    # read video meta data
    # create ffmpeg command

#create rest-video
create_rest_video() {
    path=$1
    duration=$2
    label=$3

    ffmpeg -f lavfi \
    -i color=c=black:s=240x96 \
    -ss 00:00:00 -t $duration \
    -vf "drawtext=fontfile=/System/Library/Fonts/Monaco.dfont:text='%{pts\:gmtime\:0\:%M\\\\\:%S}':fontcolor=white:fontsize=64:x=(w-tw)/2:y=(h-th)/2:box=1:boxcolor=green@0.5:boxborderw=10,format=yuv420p" \
    -y "$path"
}

#main loop
    # parse template

    # loop through names
        # check if file "{name}.ts" exists
        # is type == rest
            # call rest-video
        # else
            # call step-video

        # append file name to concat list

    # concat files

create_rest_video "$staging/rest-3-barbell-squats.ts" 3 "Barbell Squats"