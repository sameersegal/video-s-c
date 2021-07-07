#!/bin/bash

template=$1
library=$2
staging=$3

final="${template##*/}"
final="${final%.*}.mp4"

#keywords - rest

parse_template() {
    template=$1
    count=0
    steps=()
    while IFS=, read -r type duration; do
        # echo "$type-$duration"
        step=($type $duration)
        [[ $count != 0 ]] && steps+=($step)
        ((++count))
    done < $template
    
    for step in ${steps[*]}; do
        echo ${step[*]}
    done

}

create_step_video(){
    # TODO - read video meta data

    path=$1
    duration=$2
    input=$3

    ffmpeg -hide_banner -stream_loop -1 -i $input \
    -ss 00:00:00 -t $duration \
    -vf "\
    scale=1280:720:force_original_aspect_ratio=decrease,setdar=1280/720,setsar=1/1,fps=fps=30, \
    drawtext=fontfile=/System/Library/Fonts/Monaco.dfont:text='%{eif\:$duration-t\:d}':fontcolor=white:fontsize=192:x=(w-tw-50):y=(h-th-50):box=1:boxcolor=black@0.75:boxborderw=10,\
    format=yuv420p" \
    -af "loudnorm=i=-24:tp=-2:lra=7" \
    -pix_fmt yuv420p -color_range 2 -movflags +write_colr \
    -c:a aac -c:v h264_videotoolbox -b:v 1M \
    -y "$path"
}

create_rest_video() {
    path=$1
    duration=$2
    label=$3

    # TODO - add voice over & metronome 

    ffmpeg -hide_banner -f lavfi \
    -i color=c=red:s=1280x720 \
    -ss 00:00:00 -t $duration \
    -vf "\
    setdar=1280/720,setsar=1/1,fps=fps=30, \
    drawtext=fontfile=/System/Library/Fonts/Monaco.dfont:text='Rest':fontcolor=white:fontsize=256:x=(w-tw)/2:y=(h-th*2)/2,\
    drawtext=fontfile=/System/Library/Fonts/Monaco.dfont:text='Next\: $label':fontcolor=white:fontsize=64:x=(w-tw)/2:y=(h/2+100),\
    drawtext=fontfile=/System/Library/Fonts/Monaco.dfont:text='%{eif\:$duration-t\:d}':fontcolor=white:fontsize=64:x=(w-tw)/2:y=(h-150),\
    format=yuv420p" \
    -pix_fmt yuv420p -color_range 2 -movflags +write_colr \
    -c:a aac -c:v h264_videotoolbox -b:v 1M \
    -y "$path"
}

concatenate() {
    videos=("$staging/rest-3-barbell-squats.ts" "$staging/barbell-squats-3-deep.ts")
    input=""
    count=0
    for video in ${videos[*]}; do
        [[ $count == 0 ]] && input="concat:$video"
        [[ $count != 0 ]] && input="$input|$video"
        ((++count))
    done
    ffmpeg -hide_banner -y -i "$input" \
    -c:a aac -c:v h264_videotoolbox -b:v 1M -vsync 2 \
    -pix_fmt yuv420p -color_range 2 -movflags +write_colr \
    "$staging/$final"
    # ffplay -hide_banner -i "$input"
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
create_step_video "$staging/barbell-squats-3-deep.ts" 5 "$library/barbell-squats/deep.mp4"
# parse_template $template
concatenate