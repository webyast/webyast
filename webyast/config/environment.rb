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

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Webyast::Application.initialize!

GettextI18nRails.translations_are_html_safe = true

YastCache.active = Rails.env.production? ? true : false

if YastCache.active && !ENV["DISABLE_DATA_PREFETCH"]
  #check if table for caches exist and cache is active
  if ActiveRecord::Base.connection.tables.include?('data_caches') &&
     ActiveRecord::Base.connection.tables.include?('delayed_jobs')

    #remove cache information
    DataCache.delete_all
    #Construct initial job queue in order to fillup the cache
    Delayed::Job.delete_all
    resources = Resource.find :all
    resources.each  do |resource|
      name = resource.href.split("/").last
      if resource.cache_enabled
        model_name, arguments = YastCache.has_find_method(name)
        if !model_name.blank?
          if resource.cache_arguments.blank?
            if arguments.blank?
              STDERR.puts "Inserting job #{model_name}.find with priority #{resource.cache_priority}"
               PluginJob.run_async(resource.cache_priority, model_name.to_sym, :find)
            else
              STDERR.puts "Inserting job #{model_name}.find(#{arguments.inspect}) with priority #{resource.cache_priority}"
              PluginJob.run_async(resource.cache_priority, model_name.to_sym, :find, arguments)
            end
          else
            arg_hash = resource.cache_arguments #this is save cause the string is fix defined in a config
            if arguments.blank?
              STDERR.puts "Inserting job #{model_name}.find(#{arg_hash.inspect}) with priority #{resource.cache_priority}"
              PluginJob.run_async(resource.cache_priority, model_name.to_sym, :find, arg_hash )
            else
              STDERR.puts "Inserting find job of #{model_name}.find(#{arguments.inspect}, #{arg_hash.inspect}) with priority #{resource.cache_priority}"
              PluginJob.run_async(resource.cache_priority, model_name.to_sym, :find, arguments, arg_hash )
            end
          end
        else
          STDERR.puts "Ignoring job #{name}:find* (not runable)"
        end
      else
        STDERR.puts "Ignoring job #{name}:find (configured)"
      end
    end
    #added special request for none plugins
    STDERR.puts "Inserting job :Permission :find :all"
    PluginJob.run_async(0,:Permission, :find, :all)
    STDERR.puts "Inserting job :Permission :find :all {'with_description'=>'1'}"
    PluginJob.run_async(0,:Permission, :find, :all, {"with_description"=>"1"})
    STDERR.puts "Inserting job :GetentPasswd :find"
    PluginJob.run_async(-3,:GetentPasswd, :find)
  end

  if ENV["RUN_WORKER"]
    Thread::new do
      ENV["RUN_WORKER"] = 'false'
      Delayed::Worker.new.start
    end
  end
end
