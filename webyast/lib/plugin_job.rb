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

require 'gettext_rails'

class PluginJob < Struct.new(:function_string)
  def perform

    #FIXME: this is a workaround only    
    I18n.supported_locales = ["en"]

    function_array = function_string.split(":")
    raise "Invalid job entry: #{function_string}" if function_array.size < 2
    function_class = function_array.shift.capitalize
    function_method = function_array.shift
    function_args = []
    symbol_found = false
    #building argument list. Evaluating symbols
    function_array.each { |arg|
      if arg.blank?
        symbol_found = true  
      else
        if symbol_found
          symbol_found = false
          function_args << arg.to_sym
        else
          function_args << eval(arg) #translate it back to array,hash,string..
        end
      end
    }
    object = Object.const_get(function_class) rescue $!
    if object.class != NameError && object.respond_to?(function_method)
      Rails.logger.info "Calling job: #{function_class}:#{function_method}"
      Rails.logger.info "             args: #{function_args.inspect}" unless function_args.blank?
      Rails.cache.delete(function_string) #cache reset. This dedicates that
                                          #the values has been re-read
      ret = object.send(function_method, *function_args)
      Rails.logger.info "Job returned"
#      Rails.logger.info "Job returns: #{ret.inspect}"
      resources = Resource.find :all
      resources.each  do |resource|
        if resource.cache_reload_after > 0
          name = resource.href.split("/").last
          if YastCache.find_key(name) == function_string
            Rails.logger.info "Enqueuing job again (sleep #{resource.cache_reload_after} seconds)"
            Delayed::Job.enqueue(PluginJob.new(function_string), resource.cache_priority, 
                                 (resource.cache_reload_after).seconds.from_now)
          end
        end
      end
    else
      Rails.logger.error "Method #{function_class}:#{function_method} not available"
    end
  end    
end  

