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

require 'digest/md5'

module Kernel
private
  def this_method
    caller[0] =~ /`([^']*)'/ and $1
  end
  def calling_method
    caller[1] =~ /`([^']*)'/ and $1
  end
  def model_symbol(object)
    if object.instance_of? Class
      object.to_s.to_sym
    else
      object.class.to_s.to_sym
    end
  end
end

class YastCache

  include Singleton

  def YastCache.active; @active ||= false; end
  def YastCache.active= a; @active = a; end
  def YastCache.job_queue_enabled?; YastCache.active; end

  def YastCache.key(model, method, *args)
    unless args.empty?
      return "#{model.to_s.downcase}:#{method.to_s.downcase}:#{args}"
    else
      return "#{model.to_s.downcase}:#{method.to_s.downcase}"
    end        
  end

  # returns reals method name
  def YastCache.has_find_method(model_name)
    model_name.capitalize!
    object = Object.const_get((model_name).classify) rescue $!
    if object.class == NameError && model_name.end_with?("s")
      #trying real "s" like "dn" -> "dns", "kerbero" -> "kerberos",...
      model_name = (model_name).classify + "s"
      object = Object.const_get(model_name) rescue $!
    else
      model_name = (model_name).classify
    end
    if object.class != NameError && object.respond_to?(:find)
      arguments = object.method(:find).arity != 0  ? :all : nil
      return model_name, arguments
    end    
    return nil
  end

  def YastCache.find_key(model_name, key = [[:all]])
    mod_name, dummy = YastCache.has_find_method(model_name)
    return nil if mod_name.blank?
    object = Object.const_get(mod_name) rescue $!
    if object.method(:find).arity != 0 
      #has :all parameter
      return "#{mod_name.downcase}:find:#{key.inspect}"
    else
      return "#{mod_name.downcase}:find"
    end
  end

  def YastCache.reset(calling_object, *arguments)
    YastCache.reset_and_restart(calling_object, 0, true, *arguments)
  end

  def YastCache.reset_and_restart(calling_object, delay, delete_cache, *arguments)
    unless YastCache.active
#      Rails.logger.debug "YastCache.reset: Cache is not active"
      return
    end
    model = model_symbol(calling_object)
    if !arguments.empty? && arguments[0] !=  :all
      #reset also find.all caches
      YastCache.reset_and_restart(calling_object, delay, delete_cache, :all)
    end
    key = YastCache.key(model, :find, arguments)
    Rails.cache.delete(key) if delete_cache
    jobs = Delayed::Job.find(:all)
    start_job = true
    jobs.each { |job|
      data = YAML.load job.handler
      if !arguments.empty? #all args
        found = model == data[:class_name] &&
                :find == data[:method] &&
                arguments == data[:arguments]
      else
        found = model == data[:class_name] &&
                :find == data[:method] &&
                data[:arguments].empty?
      end
      if found 
        if delete_cache
          job.run_at = Time.now #set starttime to now in order to fill cache as fast as possible
          job.save
        end
        Rails.logger.info("Job #{key} already inserted")
        start_job = false
      end
    }
    if start_job
      Rails.logger.info("Inserting job #{key}")
      unless arguments.empty?
        PluginJob.run_async((delay).seconds.from_now, model, :find, *arguments) 
      else
        PluginJob.run_async((delay).seconds.from_now, model, :find)
      end
    end
  end

  def YastCache.delete(calling_object, *arguments)
    unless YastCache.active
#      Rails.logger.debug "YastCache.delete: Cache is not active"
      return
    end
    cache_key = YastCache.key(model_symbol(calling_object), :find, arguments)
    Rails.cache.delete(cache_key)

    #finding involved keys e.g. user:find:<id> includes user:find::all
    YastCache.reset(calling_object, :all)
  end
    
  def YastCache.fetch(calling_object, *options)

    unless YastCache.active
#      Rails.logger.debug "YastCache.fetch: Cache is not active"
      if  block_given?
        return yield
      else
        Rails.logger.error "YastCache.fetch: No block is given"       
        return nil
      end
    end
    key = YastCache.key(model_symbol(calling_object), :find, options)
    job_delay = 3
    raised_exception = nil
    re_load = Rails.cache.exist?(key) ?  true : false
    if  block_given?
      ret = Rails.cache.fetch(key) {
        block_ret = nil
        begin
          block_ret = yield
          if block_ret.blank?
            #no data found -> remove entry from the cache table
            cache_data = DataCache.find_by_path key
            cache_data.each { |cache|
              cache.destroy
            } unless cache_data.blank? 
          else
            #update MD5 if needed
            md5 = Digest::MD5.hexdigest(block_ret.to_json)
            cache_data = DataCache.find_by_path key
            cache_data.each { |cache|
              if cache.refreshed_md5.blank? || cache.refreshed_md5 != md5
                cache.refreshed_md5 = md5
                cache.picked_md5 = md5 if cache.picked_md5.blank?
                cache.save
              end
            } unless cache_data.blank? 
          end
        rescue Exception => raised_exception
          Rails.logger.error "YastCache.fetch(#{key}) failed: #{raised_exception.inspect}"        
          if re_load
            Rails.logger.error "Trying again in #{job_delay} seconds"
          else
            raise raised_exception #should be shown to the user
          end
        end
        block_ret
      }
      if ret.blank?
        Rails.cache.delete(key)
        Rails.logger.debug "deleting empty cache #{key} #{!Rails.cache.exist?(key)}"
      end
    else
      ret = Rails.cache.fetch(key)
      md5 = Digest::MD5.hexdigest(ret.to_json)
      cache_data = DataCache.find_by_path key
      cache_data.each { |cache|
        if cache.picked_md5.blank? || cache.picked_md5 != md5
          cache.picked_md5 = md5
          cache.save
        end
      } unless cache_data.blank? 
    end
    delete_cache = false
    YastCache.reset_and_restart(calling_object,job_delay,delete_cache,*options) if re_load #add reload into the job queue
    return ret if ret.nil?
    ret.dup #has to be dup cause the cache value is frozen
  end
end

