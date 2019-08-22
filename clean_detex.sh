#!/bin/bash
echo "Generating vim-stream program"
cat > /tmp/vims <<- EOM
#!/bin/bash
# vim-stream
# https://github.com/MilesCranmer/vim-stream

# The argument fixes were supplied by John Kugelman
# https://stackoverflow.com/a/44745698/2689923
vim_cmds=()

PRINT_ALL=1
DISABLE_VIMRC=0
MODE=none

while ((\$# > 0)); do
    case "\$1" in

        -n|--silent|--quiet) PRINT_ALL=0;;

        -d|--disable-vimrc)  DISABLE_VIMRC=1;;

        -e|--exe-mode)         MODE=exe;;
        -r|--inverse-exe-mode) MODE=inverse-exe;;
        -l|--line-exe-mode)    MODE=line-exe;;
        -s|--simple-mode)      MODE=simple;;
        -t|--turn-off-mode)    MODE=none;;

        *)
            case "\$MODE" in

                none)        vim_cmds+=(-c "\$1");;
                simple)      vim_cmds+=(-c ":exe \"norm gg""\$1""\"");;
                line-exe)    vim_cmds+=(-c ":%g/.*/exe \"norm ""\$1""\"");;

                exe)         vim_cmds+=(-c "%g/\$1/exe \"norm \$2\""); shift;;
                inverse-exe) vim_cmds+=(-c "%v/\$1/exe \"norm \$2\""); shift;;

            esac
            ;;

    esac

    shift

done

# Headless vim which exits after printing all lines
# Taken from Csaba Hoch:
# https://groups.google.com/forum/#!msg/vim_use/NfqbCdUkDb4/Ir0faiNaFZwJ
if [ "\$PRINT_ALL" -eq "1" ]; then
    vim_cmds+=(-c ":%p")
fi
if [ "\$DISABLE_VIMRC" -eq "1" ]; then
    vim_cmds=(-u NONE "\${vim_cmds[@]}")
fi

vim - -nes "\${vim_cmds[@]}" -c ':q!' | tail -n +2
EOM
chmod +x /tmp/vims

VIMS="/tmp/vims"

set -e
FILENAME="$1"
RAWTEX="0"
INCLUDE="0"
DEMACRO="0"
OUTPUTFILENAME="$1_detex.txt"
FILTER=()
ADDINGFILTERS="0"

shift

while (($# > 0)); do
    case "$1" in
        -r|--raw) RAWTEX="1" && ADDINGFILTERS="0";;
        -d|--demacro) DEMACRO="1" && ADDINGFILTERS="0";;
        -o|--output) OUTPUTFILENAME="$2" && shift && ADDINGFILTERS="0";;
        -i|--include) INCLUDE="1" && ADDINGFILTERS="0";;
        -f|--filter) ADDINGFILTERS="1";;
        *)
            if [ "$ADDINGFILTERS" -eq "0" ]; then
                echo "Invalid command."
                exit 1
            else
                FILTER+=("$1")
            fi
            ;;
    esac
    shift
done

echo "Backing up."
cp $FILENAME /tmp/.$OUTPUTFILENAME.detex.tex


# Remove or import input statements
if [ "$INCLUDE" -eq "0" ]; then
    echo 'Clearing \input{} statements. Turn on with -i.'
    cat /tmp/.$OUTPUTFILENAME.detex.tex | $VIMS '%s/\\input{.\{-}}//g' > /tmp/.$OUTPUTFILENAME.detex1.3.tex
else
    echo 'Importing \input{} statements.'
    latexpand /tmp/.$OUTPUTFILENAME.detex.tex -o /tmp/.$OUTPUTFILENAME.detex1.3.tex
fi

# Clean based on custom filters
if [ "${#FILTER[@]}" -eq "0" ]; then
    pass="1"
else
    echo "Cleaning custom filters."
    cp /tmp/.$OUTPUTFILENAME.detex1.3.tex  /tmp/.$OUTPUTFILENAME.filtering.detex.tex
    for i in "${FILTER[@]}"
    do
        echo "    Clearing filter $i."
        cat /tmp/.$OUTPUTFILENAME.filtering.detex.tex | $VIMS -e '\\'"$i"'{' '/'"$i"'{\<enter>vf{%d' > /tmp/.$OUTPUTFILENAME.filtering2.detex.tex
        cp /tmp/.$OUTPUTFILENAME.filtering2.detex.tex  /tmp/.$OUTPUTFILENAME.filtering.detex.tex
    done
    cp /tmp/.$OUTPUTFILENAME.filtering.detex.tex /tmp/.$OUTPUTFILENAME.detex1.3.tex
fi


# Remove or import input statements
if [ "$DEMACRO" -eq "0" ]; then
    echo 'Not expanding macros. Turn on with -d option.'
    cp /tmp/.$OUTPUTFILENAME.detex1.3.tex /tmp/.$OUTPUTFILENAME.detex1.4.tex 
else
    echo 'Expanding simple macros.'
    #python /tmp/macro_expand.py /tmp/.$OUTPUTFILENAME.detex1.3.tex /tmp/.$OUTPUTFILENAME.detex1.4.tex 
    cp /tmp/.$OUTPUTFILENAME.detex1.3.tex /tmp/.$OUTPUTFILENAME.detex1.4.tex 
fi


# Remove preamble
if [ "$RAWTEX" -eq "0" ]; then
    echo "Clearing preamble. Turn off with -r."
    cat /tmp/.$OUTPUTFILENAME.detex1.4.tex | $VIMS '1,/\\begin{document}/d' '$,?\\end{document}?d' > /tmp/.$OUTPUTFILENAME.detex1.5.tex
else
    cp /tmp/.$OUTPUTFILENAME.detex1.4.tex /tmp/.$OUTPUTFILENAME.detex1.5.tex
fi


echo "Moving figure captions to end of document."
cat /tmp/.$OUTPUTFILENAME.detex1.5.tex | $VIMS -e '\\caption{' '/caption{\<enter>f{lvi{dGo\<esc>pGo' > /tmp/.$OUTPUTFILENAME.captions.detex.tex

echo "Converting inline tokens to X."
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
