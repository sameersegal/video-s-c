#!/bin/bash

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