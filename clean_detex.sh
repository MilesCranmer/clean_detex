#!/bin/bash

set -e
echo "Backing up"
cp $1 .detex.tex
echo "Converting inline tokens to X"
cat .detex.tex | ./vims '1,/\\begin{document}/d' '%s/\\\[.\{-}\\\]/X/g' '%s/\$.\{-}\$/X/g' | ./vims '%s/\\cite{.\{-}}/X/g' '%s/\\citealt{.\{-}}/X/g' '%s/\\ref{.\{-}}/X/g' '%s/\\cref{.\{-}}/X/g' '%s/\\url{.\{-}}/X/g' | ./vims '%s/\\label{.\{-}}//g' '%g/\\begin{align}/,/\\end{align}/d' '%g/\\begin{align\*}/,/\\end{align\*}/d' '%g/\\begin{equation}/,/\\end{equation}/d' '%g/\\begin{equation\*}/,/\\end{equation\*}/d' > .detex2.tex
echo "Running detex"
detex .detex2.tex > .detex3.tex
echo "Cleaning detex"
cat .detex3.tex | ./vims ':%g/.*\S.*\n.*\S.*\n/.,/\n\s*\n/j' > .detex4.tex
for num in {1..10};
do
    cat .detex4.tex | ./vims ':%s/\n\s*\n\s*\n/\r\r/g' > .detex5.tex
    cat .detex5.tex | ./vims ':%s/\n\s*\n\s*\n/\r\r/g' > .detex4.tex
done
cp .detex4.tex $1_detex.txt
