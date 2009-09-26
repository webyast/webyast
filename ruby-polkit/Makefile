#
# Makefile for ruby-polkit
#

VERSION=0.0.3

all: src/Makefile
	(cd src; make)

src/Makefile: src/extconf.rb
	(cd src; ruby -rvendor-specific extconf.rb)

install: all
	(cd src; make install)

uninstall:
	rm -f $(shell ruby -r rbconfig -e "print Config::CONFIG['vendorarchdir']")/polkit.so

doc: src/Makefile
	(cd src; rdoc --all --line-numbers --charset=UTF-8 --fmt=html -p --inline-source --op=rdoc)

# autotools style
check: test
# rake style
test: all
	(cd test; make)

clean:
	(cd src; make clean || exit 0)
	(cd test; make clean || exit 0)
	
distclean: clean
	rm -f *~
	rm -f src/*~
	rm -f src/*o
	rm -rf src/rdoc
	rm -f src/Makefile
	rm -rf package/*bz2
	
dist: distclean
	(cd ..; tar -cj --exclude=ruby-polkit/package -f ruby-polkit/package/ruby-polkit-$(VERSION).tar.bz2 ruby-polkit)
