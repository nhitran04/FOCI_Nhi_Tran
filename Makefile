TARGET := paper

TEX_ALL := $(shell search=$(TARGET).tex; all=; \
				while [ -n "$$search" ] ; do \
					all="$$all $$search"; \
					search=`egrep "^[^%]*\\input" $$search | \
						sed -En 's/.*input[^\{]*\{(.+)\}/\1.tex/p'`; \
				done; \
				echo "$$all")

FIGURES := $(shell for t in $(TEX_ALL); do \
				cat $$t | \
				egrep '^[^%]*\\includegraphics' | \
				sed -En 's/.*includegraphics(\[.+\])?\{([^\{]*)\}.*/\2/p'; \
				done)

all: $(TARGET).pdf

figs/%.eps: plots/%.plot
	gnuplot $< > $@

$(TARGET).pdf: $(addsuffix .eps, $(FIGURES))  $(TEX_ALL)
	pdflatex $(TARGET).tex
	bibtex $(TARGET)
	pdflatex $(TARGET).tex
	pdflatex $(TARGET).tex
	@nn=`grep "Warning: Citation" $(TARGET).log | sort | uniq | wc -l | awk '{print $$1;}'`; if [[ $$nn -gt 0 ]] ; then echo "\033[1;33m################################\n$$nn missing citations:"; grep "Warning: Citation" $(TARGET).log | awk '{print "\033[0;31m   ", $$4;}' | sed "s/[\`']//g" | sort | uniq; echo "\033[1;33m################################\033[0m"; else echo "\033[0;34mZero missing citations! 👏🎉\033[0m"; fi

nobib:: $(addsuffix .eps, $(FIGURES)) $(TARGET).aux
	dvips $(TARGET).dvi -Ppdf -Pcmz -Pamz -t letter -D 600 -G0 -o $(TARGET).ps
	ps2pdf ${PS2PDF_FLAGS} $(TARGET).ps

view:: $(TARGET).pdf
	open $(TARGET).pdf

see:: $(TARGET).dvi
	xdvi $(TARGET)

%.eps: plots/%.plot
	gnuplot $< > figs/$@

%.eps: figs/%.fig
	fig2dev -L eps -p dummy $< $*.eps

spell::
	ispell *.tex

clean::
	rm -fv *.dvi *.aux *.log *~ *.bbl *.blg *.toc *.out *.ps *.pdf *.ent parsetab.py
	rm -fv $(addsuffix -eps-converted-to.pdf, $(FIGURES))

fresh::
	rm -fv *.dvi *.aux *.log *~ *.bbl *.blg *.toc *.ps *.pdf

distclean:: clean
	rm $(TARGET).ps

.PHONY: clean all view see spell fresh distclean nobib
