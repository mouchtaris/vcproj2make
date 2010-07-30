DC = ./dc
DCFLAGS =

NAMES   = proj2make vcproj2proj util
SOURCES = $(addsuffix .dsc,$(NAMES))
DBINS   = $(SOURCES:.dsc=.dbc)

all: main

.PHONY: main clean
main: $(DBINS)
	$(DC) --dsc=main
clean:
	rm -vf $(DBINS) main.dbc

proj2make.dbc: util.dbc
vcproj2proj.dbc: util.dbc

%.dbc: %.dsc
	$(DC) --dsc=$*
