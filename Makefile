all:
	(cd webservice; rake db:migrate)

install_test:
	grep webyast_guest /etc/passwd || yast2 users add username=webyast_guest password=test no-home; 
	cp webservice/package/org.opensuse.yast.permissions.policy /usr/share/PolicyKit/policy/ ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.freedesktop.packagekit.system-update ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.freedesktop.policykit.read ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.read ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.write ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.execute ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.dir ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.registeragent ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.unregisteragent ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.unmountagent ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.error ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.unregisterallagents ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.scr.registernewagents ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.system.status ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.module-manager.import ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.modules.yapi.time.read ; \
        /usr/bin/polkit-auth --user webyast_guest --grant org.opensuse.yast.modules.yapi.time.write ; \
        ruby webservice/package/policyKit-rights.rb --user webyast_guest --action grant ; \
        echo "NOTE:"; \
        echo "NOTE: Please take care that all needed packages with the correct version are installed !"; \
        echo "NOTE: Have a look to the requirements defined in webservice/package/yast2-webservice.spec."; \
        echo "NOTE:"; \
        echo "NOTE: You can start the server with root privileges by calling start.sh in webservice directory." ; \
        echo "NOTE:";

install:
	cp webservice/package/yast_user_roles /etc ; \
	cp webservice/package/org.opensuse.yast.permissions.policy /usr/share/PolicyKit/policy/ ; \
        /usr/bin/polkit-auth --user root --grant org.freedesktop.packagekit.system-update ; \
        /usr/bin/polkit-auth --user root --grant org.freedesktop.policykit.read ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.read ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.write ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.execute ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.dir ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.registeragent ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.unregisteragent ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.unmountagent ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.error ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.unregisterallagents ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.scr.registernewagents ; \
	/usr/bin/polkit-auth --user root --grant org.opensuse.yast.module-manager.import ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.modules.yapi.time.read ; \
        /usr/bin/polkit-auth --user root --grant org.opensuse.yast.modules.yapi.time.write ; \
        ruby webservice/package/policyKit-rights.rb --user root --action grant ; \
        echo "NOTE:"; \
        echo "NOTE: Please take care that all needed packages with the correct version are installed !"; \
        echo "NOTE: Have a look to the requirements defined in webservice/package/yast2-webservice.spec."; \
        echo "NOTE:"; \
        echo "NOTE: You can start the server with root privileges by calling start.sh in webservice directory." ; \
        echo "NOTE:";

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
        (for i in `ls www/vendor/plugins`; do if test -L www/vendor/plugins/$$i; then rm www/vendor/plugins/$$i; fi; done); \
	tar cvfj package/www.tar.bz2 www; \
        chmod 644 package/www.tar.bz2; \
	rm -rf www
