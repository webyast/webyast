all:
	(cd src; rake )

install:
	mkdir -p ../webservice/vendor/plugins; \
	( cd ../webservice/vendor/plugins; ln -s ../../../users-plugin/src/ users ); \
	cp org.opensuse.yast.users.policy /usr/share/PolicyKit/policy/ ; \
	ruby ../dist/policyKit-rights.rb --user root --action grant

distclean: 
	rm -rf package; \
	rm src/src; \
	find . -name "*.bak" -exec rm {} \; ;\

dist: distclean
	mkdir package; \
	cp org.opensuse.yast.users.policy package; \
	cp yast2-webservice-users.* package; \
        cp -R src www; \
        find www -name "*.auto" -exec rm {} \;; \
        find www -name ".gitignore" -exec rm {} \;; \
	tar cvfj package/www.tar.bz2 www; \
        chmod 644 package/www.tar.bz2; \
        rm -rf www