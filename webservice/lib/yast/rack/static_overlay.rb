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
        puts resource
        # go over all overlays
        @roots.each do |directory|
          resource_path = File.join(directory, resource)
          if File.exist?(resource_path) and File.file?(resource_path)
            return @servers[directory].call(env)
          end
        end
        # if the asset was nowhere, forward
        return @app.call(env)
      end
      
    end
    
  end
end
