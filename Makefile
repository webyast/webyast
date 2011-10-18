install:
	zypper in rubygem-rake, rubygem-rails-2_3; \
        echo "NOTE:"; \
        echo "NOTE: Please take care that all needed packages with the correct version are installed !"; \
        echo "NOTE: Have a look to the requirements defined in webservice/package/yast2-webservice.spec."; \
        echo "NOTE:"; \
        echo "NOTE: You can start the server with root privileges by calling start.sh in webservice directory." ; \
        echo "NOTE:";
