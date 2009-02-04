#
# Makefile for rpam
#

all:
	(cd ext/Rpam; ruby extconf.rb; make)

install: all
	(cd ext/Rpam; make install)
	mkdir -p $(DESTDIR)/etc/pam.d
	install -c -m 0755 rpam.pam $(DESTDIR)/etc/pam.d/rpam
