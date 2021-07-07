#!/bin/bash

template=$1
library=$2
staging=$3

final="${template##*/}"
final="${final%.*}.mp4"

declare -a PARAMS
declare -a VIDEOS

parse_template() {
    template=$1
    count=0
    steps=()
    durations=()
    while IFS=, read -r t d; do                
        [[ $count != 0 ]] && steps+=($t) && durations+=($d)
        ((++count))
    done < $template
    
    # count=0
    # for step in ${steps[*]}; do
    #     STEP=()
    #     d=${durations[$count]}
    #     nxt=${steps[$count+1]}
    #     if [ $step == "rest" ]
    #     then
    #         STEP=($step "$staging/${step}-${d}-${nxt}.ts" $d)
    #     else
    #         STEP=($step "$staging/${step}-${d}.ts" $d)
    #     fi
    #     PARAMS+=(${STEP[*]})
    #     ((++count))
    # done

    # echo "${PARAMS[@]}"
    
}

create_step_video(){
    # TODO - read video meta data

    path=$1
    duration=$2
    input=$3

    if [ $duration != "X" ]
    then
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
    else
        ffmpeg -hide_banner -stream_loop -1 -i $input \
        -ss 00:00:00 -t $duration \
        -vf "\
        scale=1280:720:force_original_aspect_ratio=decrease,setdar=1280/720,setsar=1/1,fps=fps=30, \        
        format=yuv420p" \
        -af "loudnorm=i=-24:tp=-2:lra=7" \
        -pix_fmt yuv420p -color_range 2 -movflags +write_colr \
        -c:a aac -c:v h264_videotoolbox -b:v 1M \
        -y "$path"
    fi
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
    input=""
    count=0
    for video in ${VIDEOS[*]}; do
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

main() {
    parse_template $template

    for step in "${PARAMS[@]}"; do
        echo $step
        # check if file "{name}.ts" exists
        # is type == rest
            # call rest-video
        # else
            # call step-video

        # append file name to concat list

    done

    concatenate
}

# create_rest_video "$staging/rest-3-barbell-squats.ts" 3 "Barbell Squats"
# create_step_video "$staging/barbell-squats-3-deep.ts" 5 "$library/barbell-squats/deep.mp4"
# parse_template $template
#VIDEOS=("$staging/rest-3-barbell-squats.ts" "$staging/barbell-squats-3-deep.ts")
# concatenate
main

# Nested Arrays copied from https://stackoverflow.com/a/67549770/356580

# Convert an array to a string that can be used to reform 
# the array as a new variable. This allows functions to
# return arrays as strings. Works for arrays and associative
# arrays. Spaces and odd characters are all handled by bash 
# declare.
# Usage: stringify variableName
#     variableName - Name of the array variable e.g. "myArray",
#          NOT the array contents.
# Returns (prints) the stringified version of the array.
# Examples. Use declare to make an array:
#     declare -a myArray=( "O'Neal, Dan" "Kim, Mary Ann" )
# (Or to make a local variable replace declare with local.)
# Stringify myArray:
#     stringifiedArray="$(stringify myArray)"
# Reform the array with any name like reformedArray:
#     eval "$(unstringify reformedArray "$stringifiedArray")"
# To stringify an argument list "$@", first create the array
# with a name:     declare -a myArgs=( "$@" )
stringify() {
    declare -p $1
}

# Reform an array from a stringified array. Actually this prints
# the declare command to form the new array. You need to call 
# eval with the result to make the array.
# Usage: eval "$(unstringify newArrayName stringifiedArray [local])"
#     Adding the optional "local" will create a local variable 
#     (uses local instead of declare).
# Example to make array variable named reformedArray from 
# stringifiedArray:
#     eval "$(unstringify reformedArray "$stringifiedArray")"
unstringify() {
    local cmd="declare"
    [ -n "$3" ] && cmd="$3"
    # This RE pattern extracts 2 things:
    #     1: the array type, should be "-a" or "-A"
    #     2: stringified contents of the array 
    # and skips "declare" and the original variable name.
    local declareRE='^declare ([^ ]+) [^=]+=(.*)$'
    if [[ "$2" =~ $declareRE ]]
    then
        printf '%s %s %s=%s\n' "$cmd" "${BASH_REMATCH[1]}" "$1" "${BASH_REMATCH[2]}"
    else
        echo "*** unstringify failed, invalid stringified array:" 1>&2
        printf '%s\n' "$2" 1>&2
        return 1
    fi
}
