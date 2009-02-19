all:
	(cd webservice; rake db:migrate)

distclean: 
	rm -rf package; \
        find . -name "*.bak" -exec rm {} \; ;\

dist: distclean
	mkdir package; \
	cp dist/* package; \
        cp -R webservice www; \
        cp webservice/public/doc*.html www; \
        find www -name "*.auto" -exec rm {} \;; \
        find www -name ".gitignore" -exec rm {} \;; \
        rm www/db/*.sqlite3; \
        rm www/log/development.log; \
	tar cvfj package/www.tar.bz2 www; \
        chmod 644 package/www.tar.bz2; \
        rm -rf www