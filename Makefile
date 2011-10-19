install:
	zypper in rubygem-rake rubygem-rails-2_3 rubygem-rcov; \
        rake deploy_local; \
        echo "Finished";
