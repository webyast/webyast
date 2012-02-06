#--
# Webyast framework
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

require 'singleton'

# load resources and populate database

class ResourceRegistrationError < StandardError
end

class ResourceRegistrationPathError < ResourceRegistrationError
end

class ResourceRegistrationFormatError < ResourceRegistrationError
end

class ResourceRegistration
  attr_reader :resources

  include Singleton

  def initialize
    @in_production = (ENV['RAILS_ENV'] == "production")
    @resources = Hash.new

    Rails::Engine::Railties.engines.each do |engine|
      if engine.class.to_s.match /^WebYaST::.*Engine$/
        Rails.logger.info "Found Webyast engine #{engine.class}"
        res_path = File.join(engine.config.root, 'config')
        if defined? RESOURCE_REGISTRATION_TESTING
          raise ResourceRegistrationPathError.new("Could not access plugin directory: #{res_path}") unless File.exists?( res_path )
        end
#       $stderr.puts "checking #{res_path}"
        res_path = File.join(res_path, 'resources')
        if defined? RESOURCE_REGISTRATION_TESTING
          raise ResourceRegistrationPathError.new("Could not access plugin directory: #{res_path}") unless File.exists?( res_path )
        end
#        $stderr.puts "self.register_plugin #{res_path}"
        registration_count = 0
        Dir.glob(File.join(res_path, '**/*.y*ml')).each do |descriptor|
#         $stderr.puts "checking #{descriptor}"
          next unless descriptor =~ %r{#{res_path}/((\w+)/)?(\w+)\.y(a)?ml$}
#         $stderr.puts "registering #{descriptor}"
          register(descriptor)
          registration_count += 1
        end
        if defined? RESOURCE_REGISTRATION_TESTING
          raise ResourceRegistrationPathError.new("Could not find any YAML file with resource description below #{res_path}") unless registration_count > 0
        end
      end
    end
  end
end # class ResourceRegistration
