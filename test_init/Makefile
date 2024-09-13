
.PHONY: install all

all: test_init

test_init: test_init.o

install: test_init
	install -D $^ $(DESTDIR)$(bindir)/$^
