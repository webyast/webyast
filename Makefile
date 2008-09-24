all:
	cd polKit; \
	ruby extconf.rb; \
	make; \
	sudo make install; \
	cd ..; \
	cd rpam/ext/Rpam; \
	ruby extconf.rb; \
	make; \
	sudo make install; \
	cd ../../..; \
	rm -rf package; \
        rm webservice/log/development.log; \
        find . -name "*.bak" -exec rm {} \; ;\
	mkdir package; \
	cp dist/* package; \
	tar cvfj package/webservice.tar.bz2 webservice