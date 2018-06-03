###############################################################################
#
# 	Makefile for zhbook
#
# 	Copyright (C) 2013-2015 Haixing Hu,
#   Department of Computer Science and Technology, Nanjing University.
#
#	Home Page of the Project: http://haixing-hu.github.io/nju-thesis/
#
###############################################################################

PACKAGE=zhbook
BST_FILE=gbt7714-2005.bst
BST_URL=https://raw.githubusercontent.com/Haixing-Hu/GBT7714-2005-BibTeX-Style/master/gbt7714-2005.bst
SOURCES=$(PACKAGE).dtx $(PACKAGE).ins
CLS=$(PACKAGE).cls $(PACKAGE).cfg dtx-style.sty
#SAMPLE=sample
SAMPLE=sosbook
SAMPLECONTENTS=$(SAMPLE).tex
SAMPLEBIB=$(SAMPLE).bib
TEXMFLOCAL=$(shell get_texmf_dir.sh)

.PHONY: all clean cls doc sample sosbook

#all: bst cls doc sample
all: bst cls doc sosbook

###### update bst file
bst:  $(BST_FILE)

$(BST_FILE):
	curl $(BST_URL) -o $(BST_FILE)

###### generate cls/cfg
cls:  $(CLS)

$(CLS): $(SOURCES)
	latex $(PACKAGE).ins

###### generate doc

doc: $(PACKAGE).pdf

$(PACKAGE).pdf: $(CLS)
	xelatex $(PACKAGE).dtx
	makeindex -s gind.ist -o $(PACKAGE).ind $(PACKAGE).idx
	xelatex $(PACKAGE).dtx
	xelatex $(PACKAGE).dtx

###### for sample
sosbook:	 $(SAMPLE).pdf
#sample:	 $(SAMPLE).pdf

$(SAMPLE).pdf: $(CLS) $(BST_FILE) $(SAMPLE).tex $(SAMPLEBIB)
	xelatex $(SAMPLE).tex
	bibtex $(SAMPLE)
	xelatex $(SAMPLE).tex
	xelatex $(SAMPLE).tex

###### install

install: $(SOURCE) $(CLS) $(BST_FILE) $(PACKAGE).pdf $(SAMPLE).pdf
	mkdir -p $(TEXMFLOCAL)/tex/latex/zhbook
	cp -rvf $(SOURCES) $(CLS) $(TEXMFLOCAL)/tex/latex/zhbook/
	mkdir -p $(TEXMFLOCAL)/doc/latex/zhbook
	cp -rvf $(PACKAGE).pdf $(SAMPLE).pdf $(TEXMFLOCAL)/doc/latex/zhbook/
	mkdir -p $(TEXMFLOCAL)/bibtex/bst
	cp -rvf $(BST_FILE) $(TEXMFLOCAL)/bibtex/bst/
	texhash

###### clean

clean:
	-@rm -f \
		*.aux \
		*.bak \
		*.bbl \
		*.blg \
		*.dvi \
		*.glo \
		*.gls \
		*.idx \
		*.ilg \
		*.ind \
		*.ist \
		*.log \
		*.out \
		*.ps \
		*.thm \
		*.toc \
		*.lof \
		*.lot \
		*.loe \
		*.sty \
		*.cfg \
		*.cls \
		*.sty \
		*.hd \
		*.synctex.gz \
		sample.pdf zhbook.pdf sosbook.pdf
