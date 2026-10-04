PREFIX  = /usr/local

all: updkernel

updkernel:
	odin build . -out=updkernel -o:size

clean:
	rm updkernel

install: updkernel
	mkdir -p $(PREFIX)/bin
	rm -f $(PREFIX)/bin/updkernel
	cp -f updkernel $(PREFIX)/bin

uninstall:
	rm -f $(PREFIX)/bin/updkernel
