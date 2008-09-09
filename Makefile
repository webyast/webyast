all:
	rm -rf package; \
        rm webservice/log/development.log; \
        find . -name "*.bak" -exec rm {} \; ;\
	mkdir package; \
	cp dist/* package; \
	tar cvfj package/webservice.tar.bz2 webservice