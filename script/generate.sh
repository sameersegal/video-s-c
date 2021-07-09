#!/bin/bash

mode=$1
template=$2
library=$3
staging=$4

final="${template##*/}"
final="${final%.*}.mp4"

declare -a PARAMS
declare -a VIDEOS

. ./script/nested-arrays.sh

parse_template() {
    template=$1
    count=-1
    declare -a steps
    while IFS=, read -r t d; do                
        if [ $count != -1 ]
        then
            declare -a step=( $t $d )
            steps[$count]="$(stringify step)"
        fi
        ((++count))
    done < $template
    
    count=0
    for step in "${steps[@]}"; do
        eval "$(unstringify row "$step")"
        
        t=${row[0]}
        d=${row[1]}        
        n=$(($count+1))  
        eval "$(unstringify nxt "${steps[$count+1]}")"
        # echo "$count-$n: $t ${steps[2]}"
        declare -a s
        if [ $t == "rest" ]
        then
            # label="Foo"
            label=`cat library/${nxt[0]}/metadata.txt | head -n1`
            s=($t "$staging/${t}-${d}-${nxt[0]}.ts" $d "$label")
        else
            # TODO - make this random
            i=`find $library/$t -type f -name *.mp4 | head -n 1`
            # From metadata, get whether we need to include a timer or not
            f=`basename $i`
            timer=`cat library/$t/metadata.txt | grep $f | cut -d ',' -f 2`
            s=($t "$staging/${t}-${d}.ts" $d $i $timer)
        fi
        PARAMS[$count]="$(stringify s)"
        ((++count))
    done
}

create_step_video(){

    path=$1
    duration=$2
    input=$3
    timer=$4

    declare -a args
    args+=("ffmpeg -hide_banner ")

    if [ $duration != "X" ]
    then      
        args+=(" -stream_loop -1 -i $input ")
        args+=(" -ss 00:00:00 -t $duration ")
    else
        args+=(" -i $input ")
    fi

    if [ $timer != "No" ]
    then    
        args+=(" -vf \"scale=1280:720:force_original_aspect_ratio=decrease,setdar=1280/720,setsar=1/1,fps=fps=30,drawtext=fontfile=/System/Library/Fonts/Monaco.dfont:text='%{eif\:$duration-t\:d}':fontcolor=white:fontsize=192:x=(w-tw-50):y=(h-th-50):box=1:boxcolor=black@0.75:boxborderw=10,format=yuv420p\" ")
    else  
        args+=(" -vf \"scale=1280:720:force_original_aspect_ratio=decrease,setdar=1280/720,setsar=1/1,fps=fps=30,format=yuv420p\" ")      
    fi

    args+=(" -af \"loudnorm=i=-24:tp=-2:lra=7\" ")
    args+=(" -pix_fmt yuv420p -color_range 2 -movflags +write_colr ")
    args+=(" -c:a aac -c:v h264_videotoolbox -b:v 1M ")
    args+=(" -y $path")

    echo "${args[@]}"
    
    eval ${args[@]}
}

create_rest_video() {
    path=$1
    duration=$2
    label=$3

    # TODO - add voice over & metronome 

    echo "REST - $label"

    ffmpeg -hide_banner -f lavfi \
    -i color=c=red:s=1280x720 \
    -stream_loop -1 -i $library/timer/metronome.mp3 \
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
        eval "$(unstringify row "$step")"
        type=${row[0]}
        path=${row[1]}
        duration=${row[2]}
        arg1=${row[3]}        

        if [ -f $path ]
        then
            echo "$path exists already. skipping creation"
        else                
            if [ $type = "rest" ]
            then
                create_rest_video "$path" $duration "$arg1"
            else
                arg2=${row[4]}
                create_step_video "$path" $duration "$arg1" "$arg2"
            fi        
        fi
        
        VIDEOS+=($path)

    done

    concatenate
}


if [ $mode = "create" ]
then
    main
elif [ $mode = "parse_template" ]
then
    parse_template $template
    echo "${PARAMS[@]}"
elif [ $mode = "create_rest_video" ]
then
    create_rest_video "$staging/rest-3-barbell-squats.ts" 3 "Barbell Squats"
elif [ $mode = "create_step_video" ]
then
    create_step_video "$staging/barbell-squats-3-deep.ts" 5 "$library/barbell-squats/deep.mp4" "Yes"
elif [ $mode = "concatenate" ]
then
    VIDEOS=("$staging/rest-3-barbell-squats.ts" "$staging/barbell-squats-3-deep.ts")
    concatenate
fi