require 'uri'

module YaST

  module Rack

    # class that looks for a static request in a list
    # of directories. If the file can't be served from any
    # of the overlays
    # then the request is forwarded to the application
    class StaticOverlay

      # initialize the middleware
      # known options:
      # :roots => [ dir, ... ]
      def initialize(app, options={})
        @app = app
        @servers = {}
        @roots = options[:roots] || []
        @roots.each do |root|
          @servers[root] = ::Rack::File.new(root)
        end
      end

      def call(env)
        req = ::Rack::Request.new(env)
        resource = URI.parse(req.url).path

	# this is a workaround for lighttpd server
	# where all requests go through FastCGI dispatcher
	if resource == '/dispatch.fcgi'
	    # get the real request path
	    resource = env['REQUEST_URI']
	    # Rack expects the path in PATH_INFO which is not set by lighttpd
	    env['PATH_INFO'] = env['REQUEST_URI']
	end

        # go over all overlays
        @roots.each do |directory|
          resource_path = File.join(directory, resource)
          if File.exist?(resource_path) and File.file?(resource_path)
	    Rails.logger.info "Using static overlay for #{resource_path}"
            return @servers[directory].call(env)
          end
        end
        # if the asset was nowhere, forward
        return @app.call(env)
      end
      
    end
    
  end
end
