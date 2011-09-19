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

class PluginJob < Struct.new(:class_name,:method,:arguments)

  class << self
    # Runs job asynchronous.
    # @param[Integer] prio priority of job
    # @param[Object,String,Symbol] object on which is method called. 
    #   If method is class variable use symbol or string with name.
    #   If it is instance method pass instance (in case of problems check if object can properly serialize and deserialize from YAML).
    # @param[Symbol] method name as symbol
    # @param[Array] args variable list of method arguments. Any element must be serializable to YAML ( and deserializable also )
    #
    # @example run class method
    #   PluginJob.run_async(0,:Patch,:install,id,:force => true)
    # @example run instance method
    #   patch = Patch.new id
    #   PluginJob.run_async(0,patch,:install)
    def run_async(prio,object,method,*args)
      Delayed::Job.enqueue(PluginJob.new(object,method,args),prio)
    end

    # Counts the jobs which are running
    # @param[Object,String,Symbol] object on which job should run
    # @param[Symbol,nil] method called method or all method if nil passed
    # @param[Array] args list of all parameters or empty array which match any arguments
    def running (object, method = nil, *args)
      count = 0
      jobs = Delayed::Job.all
      jobs.any? do |job|
        data = YAML.load job.handler
        if !args.empty? #all args
          count += 1 if object == data[:class_name] &&
                        method == data[:method] &&
                        args == data[:arguments]
        elsif method
          count += 1 if object == data[:class_name] &&
                        method == data[:method]
        else
          count += 1 if object == data[:class_name]
        end
      end
      count
    end

    # Checks if job is running
    # @param[Object,String,Symbol] object on which job should run
    # @param[Symbol,nil] method called method or all method if nil passed
    # @param[Array] args list of all parameters or empty array which match any arguments
    def running? (object, method = nil, *args)
      PluginJob.running(object, method, *args) > 0 ? true : false
    end
  end

#internal method. Use run_async and running? for asynchronous jobs
  def perform

    #FIXME: this is a workaround only
    I18n.supported_locales = ["en"]

    object = nil
    object = self[:class_name]
    if object.class == Symbol || object.class == String
      object = Object.const_get(object) rescue $!
    end
    function_method = self[:method]
    function_args = self[:arguments]
    if object.class != NameError && object.respond_to?(function_method)
      Rails.logger.info "Calling job: #{object}:#{function_method}"
      Rails.logger.info "             args: #{function_args.inspect}" unless function_args.blank?
      call_identifier = YastCache.key(object,function_method,*function_args)
      Rails.cache.delete(call_identifier) #cache reset. This dedicates that
                                          #the values has been re-read
      ret = object.send(function_method, *function_args)
      Rails.logger.info "Job returned"  #{ret.inspect}
      resources = Resource.find :all
      resources.each  do |resource|
        if resource.cache_reload_after > 0
          name = resource.href.split("/").last
          if YastCache.find_key(name) == call_identifier
            Rails.logger.info "Enqueuing job again (sleep #{resource.cache_reload_after} seconds)"
            Delayed::Job.enqueue(PluginJob.new(self[:class_name],function_method,function_args), resource.cache_priority, 
                                 (resource.cache_reload_after).seconds.from_now)
          end
        end
      end
    else
      Rails.logger.error "Method #{object}:#{function_method} not available"
    end
  end
end

