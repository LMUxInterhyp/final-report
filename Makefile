.PHONY: pdf watch check clean

pdf:
	latexmk -pdf main.tex

watch:
	latexmk -pdf -pvc main.tex

check:
	chktex -q -n 1 -n 8 -n 13 -n 24 main.tex

clean:
	latexmk -C main.tex
