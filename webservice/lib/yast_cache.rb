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

  def YastCache.reset(key, delay = 0)
    Rails.cache.delete(key)
    Delayed::Job.enqueue(PluginJob.new(key),0, (delay).seconds.from_now )
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
          Rails.logger.error "Trying again in #{job_delay} seconds" if reload
        end
        block_ret
      }
    else
      ret = Rails.cache.fetch(key, options)
    end
    YastCache.reset(key,job_delay) if re_load #add reload into the job queue
    raise raised_exception unless raised_exception.nil? #raising exception to the next level
    ret
  end
end

