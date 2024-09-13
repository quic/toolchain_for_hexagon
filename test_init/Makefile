
.PHONY: install all

CFLAGS=-mcpu=hexagonv68
LDFLAGS=-static -mcpu=hexagonv68

all: test_init

test_init: test_init.o

install: test_init
	install -D $^ $(DESTDIR)/bin/$^
