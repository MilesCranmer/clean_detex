# clean_detex
## A cleaned-up version of detex, to ease the use of grammar checkers on LaTeX.

Workflow:
- Run `clean_detex.sh` on your TeX files
- Copy the plaintext versions into your favorite grammar/spell checker
- Manually edit the original TeX files with the suggestions

If you've ever used detex in an attempt to convert your LaTeX to a text file that you can use with a grammar checker, you know that the vast majority of the grammatical mistakes are because detex has removed things like equations and citations, which in compiled LaTeX take the place of words in a sentence.

This bash script does some simple text manipulations to convert your LaTeX into a more readable .txt file. It also cleans up whitespace and rescues the figure captions.

## Install

To use, first install [detex](https://ctan.org/pkg/detex?lang=en) (you might already have it installed with your LaTeX - try running `detex` on the command line).

Next, put "clean_detex.sh" and "vims" into your LaTeX folder (the second part is unnecessary if you have [vim-stream](https://github.com/MilesCranmer/vim-stream) installed). Run with:

```
./clean_detex.sh main.tex -o main.txt
```

This will output a file called main.txt that is a text version of your LaTeX code. You can then copy that text into MS Word or Grammarly.

Note that if you use `\input{}` statements, you will need to run `clean_detex` on each individual file with the `-r` option (easier) or
use [latexpand](https://gitlab.com/latexpand/latexpand) to copy them all into the same file (messier).


## Options


```
./clean_detex.sh chapter1.tex -r -o output.txt
```

- The `-r` means raw TeX: it will treat the .tex file as pure LaTeX --- it doesn't need  a `\begin{document}`
- The `-o output.tex` sets the output file, useful if you are batching over many chapters and want different names


