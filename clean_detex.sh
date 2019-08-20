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
OUTPUTFILENAME="$1_detex.txt"

shift

while (($# > 0)); do
    case "$1" in
        -r|--raw) RAWTEX="1";;
        -o|--output) OUTPUTFILENAME="$2" && shift;;
        *) echo "Invalid command" && exit 1;;
    esac
    shift
done

echo "Backing up"
cp $FILENAME /tmp/.$OUTPUTFILENAME.detex.tex
echo "Converting inline tokens to X"

if [ "$RAWTEX" -eq "0" ]; then
    cat /tmp/.$OUTPUTFILENAME.detex.tex | $VIMS '1,/\\begin{document}/d' > /tmp/.$OUTPUTFILENAME.detex1.5.tex
else
    cp /tmp/.$OUTPUTFILENAME.detex.tex /tmp/.$OUTPUTFILENAME.detex1.5.tex
fi

cat /tmp/.$OUTPUTFILENAME.detex1.5.tex | $VIMS '%s/\\begin{abstract}//g'  '%s/\\end{abstract}//g' '%s/\\\[.\{-}\\\]/X/g' '%s/\$.\{-}\$/X/g' | $VIMS '%s/\\cite{.\{-}}/X/g' '%s/\\citealt{.\{-}}/X/g' '%s/\\ref{.\{-}}/X/g' '%s/\\cref{.\{-}}/X/g' '%s/\\url{.\{-}}/X/g' | $VIMS '%s/\\label{.\{-}}//g' '%g/\\begin{align}/,/\\end{align}/d' '%g/\\begin{align\*}/,/\\end{align\*}/d' '%g/\\begin{equation}/,/\\end{equation}/d' '%g/\\begin{equation\*}/,/\\end{equation\*}/d' > /tmp/.$OUTPUTFILENAME.detex2.tex



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
