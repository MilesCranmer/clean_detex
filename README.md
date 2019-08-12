# clean_detex
## A cleaned-up version of detex, to ease the use of grammar checkers on LaTeX.

If you've ever used detex in an attempt to convert your LaTeX to a text file that you can use with a grammar checker, you know that the vast majority of the grammatical mistakes are because detex has removed things like equations and citations, which in compiled LaTeX take the place of words in a sentence.

This bash script does some very simple text manipulations to convert your LaTeX into a more readable .txt file. 


To use, first install [detex](https://ctan.org/pkg/detex?lang=en).

Next, put "clean_detex.sh" and "vims" into your LaTeX folder. Run with:

```
./clean_detex.sh main.tex
```

This will output a file called main.tex_detex.txt that is a text version of your LaTeX code. You can then copy that text into Microsoft Word or Grammarly.
