#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Hmm, don't know if this is the right place for this
# but http://groups.google.com/group/sdruby/browse_thread/thread/5239824b058ac936 doesn't know any better
#
# Apparently, webrick sets it, while "rake test" doesn't.
#
RAILS_ENV = ENV['RAILS_ENV'] unless defined? RAILS_ENV

STDERR.puts "\n\n\t***RAILS_ENV environment variable isn't set !\n\n" unless RAILS_ENV

# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

init = Rails::Initializer.run do |config|
  #just for test
  #ENV['DISABLE_INITIALIZER_FROM_RAKE'] = 'false'
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  #config.load_paths += %W( #{RAILS_ROOT}/vendor/plugins/systemtime )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :key => '_yast-api_session',
    # It is overwritten during install time (bnc#550635), do not change key # RORSCAN_INL
    :secret      => '9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # reload all plugins, changes in *.rb files take effect immediately
  # it's here because of https://rails.lighthouseapp.com/projects/8994/tickets/2324-configreload_plugins-true-only-works-in-environmentrb
  config.reload_plugins = true if ENV['RAILS_ENV'] == 'development'

  # In order to prevent unloading of AuthenticatedSystem
  config.load_once_paths += %W( #{RAILS_ROOT}/lib )

  # allows to find plugin in development tree locations
  # avoiding installing plugins to see them
  config.plugin_paths << File.join(RAILS_ROOT, '..', 'plugins') if ENV['RAILS_ENV'] != "production"

  # add extra plugin path - needed during RPM build
  # (webyast-base-ws is already installed in /srv/www/... but plugins are
  # located in /usr/src/packages/... during build)
  config.plugin_paths << '/usr/src/packages/BUILD' unless ENV['ADD_BUILD_PATH'].nil?

  config.after_initialize do
    unless ENV['RAILS_ENV'] == 'test'
      if ENV["RUN_WORKER"]
        Thread::new do 
          ENV["RUN_WORKER"] = 'false'
	  Delayed::Worker.new.start 
        end
      end
    end
  end
end

# don't load all plugins while just testing resource registration
unless defined? RESOURCE_REGISTRATION_TESTING
  STDERR.puts "\n*** registering plugins ***\n"
  # load lib/resource_registration.rb
  require "resource_registration"

  init.loaded_plugins.each do |plugin|
    ResourceRegistration.register_plugin(plugin)
  end
  
  ResourceRegistration.route ResourceRegistration.resources

end

# load global role assignments unless we're testing them
unless defined? PERMISSION_CHECK_TESTING
  
  USER_ROLES_CONFIG = "/etc/yast_user_roles"    

end

# look for all existing loaded plugin's public/ directories
plugin_assets = init.loaded_plugins.map { |plugin| File.join(plugin.directory, 'public') }.reject { |dir| not (File.directory?(dir) and File.exist?(dir)) }

require 'yast/rack/static_overlay'
init.configuration.middleware.use YaST::Rack::StaticOverlay, :roots => plugin_assets

unless ENV['RAILS_ENV'] == 'test'
  #Construct initial job queue in order to fillup the cache
  Delayed::Job.delete_all
  resources = Resource.find :all
  resources.each  do |resource|
    name = resource.href.split("/").last
    status = Object.const_get((name).classify) rescue $!
    if status.class != NameError 
      if status.respond_to?(:find)
#        puts "xxxxxxxxxx #{name}:find:all"
#         Delayed::Job.enqueue(PluginJob.new("#{name}:find:all"), -3, 5.seconds.from_now)
      end
      if status.respond_to?(:find_all) 
#        puts "Inserting job #{name}:find_all"
#        Delayed::Job.enqueue(PluginJob.new("#{name}:find_all"), -3)# if name == "users"
      end
    end
  end
end

