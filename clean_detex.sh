#!/bin/bash

VIMS=""

if VIMS=$(command -v vims); then
    pass="1"
else
    VIMS="./vims"
fi

set -e
FILENAME="$1"
RAWTEX="0"
INCLUDE="0"
OUTPUTFILENAME="$1_detex.txt"
FILTER=()
ADDINGFILTERS="0"

shift

while (($# > 0)); do
    case "$1" in
        -r|--raw) RAWTEX="1" && ADDINGFILTERS="0";;
        -o|--output) OUTPUTFILENAME="$2" && shift && ADDINGFILTERS="0";;
        -i|--include) INCLUDE="1" && ADDINGFILTERS="0";;
        -f|--filter) ADDINGFILTERS="1";;
        *)
            if [ "$ADDINGFILTERS" -eq "0" ]; then
                echo "Invalid command"
                exit 1
            else
                FILTER+=("$1")
            fi
            ;;
    esac
    shift
done

echo "Backing up"
cp $FILENAME /tmp/.$OUTPUTFILENAME.detex.tex


# Remove or import input statements
if [ "$INCLUDE" -eq "0" ]; then
    echo 'Clearing \input{} statements'
    cat /tmp/.$OUTPUTFILENAME.detex.tex | $VIMS '%s/\\input{.\{-}}//g' > /tmp/.$OUTPUTFILENAME.detex1.3.tex
else
    echo 'Importing \input{} statements'
    latexpand /tmp/.$OUTPUTFILENAME.detex.tex -o /tmp/.$OUTPUTFILENAME.detex1.3.tex
fi

# Remove preamble
if [ "$RAWTEX" -eq "0" ]; then
    echo "Clearing preamble"
    cat /tmp/.$OUTPUTFILENAME.detex1.3.tex | $VIMS '1,/\\begin{document}/d' '$,?\\end{document}?d' > /tmp/.$OUTPUTFILENAME.detex1.5.tex
else
    cp /tmp/.$OUTPUTFILENAME.detex1.3.tex /tmp/.$OUTPUTFILENAME.detex1.5.tex
fi


# Clean based on custom filters
if [ "${#FILTER[@]}" -eq "0" ]; then
    pass="1"
else
    echo "Cleaning custom filters"
    cp /tmp/.$OUTPUTFILENAME.detex1.5.tex  /tmp/.$OUTPUTFILENAME.filtering.detex.tex
    for i in "${FILTER[@]}"
    do
        cat /tmp/.$OUTPUTFILENAME.filtering.detex.tex | $VIMS -e '\\'"$i"'{' '/'"$i"'{\<enter>vf{%d' > /tmp/.$OUTPUTFILENAME.filtering2.detex.tex
        cp /tmp/.$OUTPUTFILENAME.filtering2.detex.tex  /tmp/.$OUTPUTFILENAME.filtering.detex.tex
    done
    cp /tmp/.$OUTPUTFILENAME.filtering.detex.tex /tmp/.$OUTPUTFILENAME.detex1.5.tex
fi


echo "Moving figure captions to end of document"
cat /tmp/.$OUTPUTFILENAME.detex1.5.tex | $VIMS -e '\\caption{' '/caption{\<enter>f{lvi{dGo\<esc>pGo' > /tmp/.$OUTPUTFILENAME.captions.detex.tex

echo "Converting inline tokens to X"
cat /tmp/.$OUTPUTFILENAME.captions.detex.tex | $VIMS '%s/\\begin{abstract}//g'  '%s/\\end{abstract}//g' '%s/\\\[.\{-}\\\]/X/g' '%s/\$.\{-}\$/X/g' | $VIMS '%s/\\cite{.\{-}}/X/g' '%s/\\citealt{.\{-}}/X/g' '%s/\\ref{.\{-}}/X/g' '%s/\\cref{.\{-}}/X/g' '%s/\\url{.\{-}}/X/g' | $VIMS '%s/\\label{.\{-}}//g' '%g/\\begin{align}/,/\\end{align}/d' '%g/\\begin{align\*}/,/\\end{align\*}/d' '%g/\\begin{equation}/,/\\end{equation}/d' '%g/\\begin{equation\*}/,/\\end{equation\*}/d' > /tmp/.$OUTPUTFILENAME.detex2.tex



echo "Running detex"
detex /tmp/.$OUTPUTFILENAME.detex2.tex > /tmp/.$OUTPUTFILENAME.detex3.tex
echo "Cleaning detex"
cat /tmp/.$OUTPUTFILENAME.detex3.tex | $VIMS ':%g/.*\S.*\n.*\S.*\n/.,/\n\s*\n/j' > /tmp/.$OUTPUTFILENAME.detex4.tex
for num in {1..10};
do
    cat /tmp/.$OUTPUTFILENAME.detex4.tex | $VIMS ':%s/\n\s*\n\s*\n/\r\r/g' > /tmp/.$OUTPUTFILENAME.detex5.tex
    cat /tmp/.$OUTPUTFILENAME.detex5.tex | $VIMS ':%s/\n\s*\n\s*\n/\r\r/g' > /tmp/.$OUTPUTFILENAME.detex4.tex
done
cp /tmp/.$OUTPUTFILENAME.detex4.tex $OUTPUTFILENAME
