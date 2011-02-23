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

class YastCache

  def YastCache.find_key(model_name, key = ":all")
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
      if object.method(:find).arity != 0 
        #has :all parameter
        return "#{model_name}:find:#{key}"
      else
        return "#{model_name}:find"
      end
    end    
    return nil
  end

  def YastCache.reset(cache_key, delay = 0, delete_cache = true)
    #finding involved keys e.g. user:find:<id> includes user:find::all
    function_array = cache_key.split(":")
    raise "Invalid job entry: #{function_string}" if function_array.size < 2
    keys = [cache_key]
    unless (function_array.size == 2 ||
            (function_array.size == 4 && function_array == "all")) 
      #add general <module>:find to the list
      keys << YastCache.find_key(function_array.shift)
    end

    keys.each { |key|
      Rails.cache.delete(key) if delete_cache
      jobs = Delayed::Job.find(:all)
      found = false
      jobs.each { |job|
        found = true if key == job.handler.split("\n")[1].split[1]
      } unless jobs.blank?
      if found
        Rails.logger.info("Job #{key} already inserted")
      else
        Rails.logger.info("Inserting job #{key}")
        Delayed::Job.enqueue(PluginJob.new(key),0, (delay).seconds.from_now )
      end
    }
  end
    
  def YastCache.fetch(key, options = {})
    job_delay = 3
    raised_exception = nil
    re_load = Rails.cache.exist?(key) ?  true : false
    if  block_given?
      ret = Rails.cache.fetch(key, options) {
        block_ret = nil
        begin
          block_ret = yield
          if block_ret == nil
            #no data found -> remove entry from the cache table
            cache_data = DataCache.all(:conditions => "path = '#{key}'")
            cache_data.each { |cache|
              cache.destroy
            } unless cache_data.blank? 
          else
            #update MD5 if needed
            md5 = Digest::MD5.hexdigest(block_ret.to_json)
            cache_data = DataCache.all(:conditions => "path = '#{key}' AND ( refreshed_md5 is NULL OR refreshed_md5 != '#{md5}')")
            cache_data.each { |cache|
              cache.refreshed_md5 = md5
              cache.picked_md5 = md5 if cache.picked_md5.blank?
              cache.save
            } unless cache_data.blank? 
          end
        rescue Exception => raised_exception
          Rails.logger.error "YastCache.fetch(#{key}) failed: #{raised_exception.inspect}"        
          Rails.logger.error "Trying again in #{job_delay} seconds" if re_load
        end
        block_ret
      }
    else
      ret = Rails.cache.fetch(key, options)
      md5 = Digest::MD5.hexdigest(ret.to_json)
      cache_data = DataCache.all(:conditions => "path = '#{key}' AND ( picked_md5 is NULL OR picked_md5 != '#{md5}')")
      cache_data.each { |cache|
        cache.picked_md5 = md5
        cache.save
      } unless cache_data.blank? 
    end
    delete_cache = false
    YastCache.reset(key,job_delay,delete_cache) if re_load #add reload into the job queue
    raise raised_exception unless raised_exception.nil? #raising exception to the next level
    return ret if ret.nil?
    ret.dup #has to be dup cause the cache value is frozen
  end
end

