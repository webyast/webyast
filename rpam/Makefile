#
# Makefile for rpam
#

all: ext/Rpam/Makefile
	(cd ext/Rpam; make)

ext/Rpam/Makefile: ext/Rpam/extconf.rb
	(cd ext/Rpam; ruby -rvendor-specific extconf.rb)

install: all
	(cd ext/Rpam; make install)
	mkdir -p $(DESTDIR)/etc/pam.d
	install -c -m 0644 rpam.pam $(DESTDIR)/etc/pam.d/rpam

doc: ext/Rpam/Makefile
	(cd ext/Rpam; rdoc --all --line-numbers --charset=UTF-8 --fmt=html -p --inline-source --op=rdoc)

test: all
	(cd test; make)

clean:
	(cd ext/Rpam; make clean || exit 0)
	(cd test; make clean || exit 0)
	
distclean: clean
	rm -f *~
	rm -f ext/Rpam/*~
	rm -f ext/Rpam/*o
	rm -rf ext/Rpam/rdoc
	rm -f ext/Rpam/Makefile
	
dist: distclean
	rm -rf package/*bz2
	(cd ..; tar -cj --exclude=rpam/package -f rpam/package/ruby-rpam-1.0.1.tar.bz2 rpam)
