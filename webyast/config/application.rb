require File.expand_path('../boot', __FILE__)
require 'rails/all'
require 'fast_gettext'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  #Bundler.require(*Rails.groups(:assets => %w(development test)))
  Bundler.require *Rails.groups(:assets) if defined?(Bundler)
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end



module Webyast
  class Application < Rails::Application
    require 'plugin_job'
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.secret_token = '9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1'
    config.to_prepare do
      Devise::SessionsController.layout "main" 
    end
    # remove quiet_assets initializer when this works
    # issue #2639
    #config.assets.logger = nil

    config.after_initialize do
      YastCache.active = config.action_controller.perform_caching 

      #check if table for caches exist and cache is active
      if ActiveRecord::Base.connection.tables.include?('data_caches') &&
         ActiveRecord::Base.connection.tables.include?('delayed_jobs') &&
         YastCache.active

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

    end
  end
end

# TODO: GET AVAILABLE LOCALES AUTOMATICALLY !!!!
FastGettext.add_text_domain 'webyast-base', :path => 'locale'
FastGettext.default_text_domain = 'webyast-base'
FastGettext.default_available_locales = ["ar","cs","de","es","en_US","fr","hu","it","ja","ko","nl","pl","pt_BR","ru","sv","zh_CN","zh_TW"]





