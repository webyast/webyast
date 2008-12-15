all:
	cd ruby-polkit; \
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
        find . -name "*.bak" -exec rm {} \; ;\
	mkdir package; \
	cp dist/* package; \
        cp -R webservice www; \
        cp -R ruby-polkit www; \
        cp -R rpam www; \
        find www -name "*.auto" -exec rm {} \;; \
        find www -name ".gitignore" -exec rm {} \;; \
        rm www/db/*.sqlite3; \
        rm www/log/development.log; \
	tar cvfj package/www.tar.bz2 www; \
        chmod 644 package/www.tar.bz2; \
        rm -rf www