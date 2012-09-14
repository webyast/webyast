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
      try_updating_db do
        Delayed::Job.enqueue(PluginJob.new(object,method,args),{:priority =>prio})
      end
    end

    # All running/queued PluginJob jobs
    def jobs
      Delayed::Job.all.delete_if do |job|
        !YAML.load(job.handler).is_a?(PluginJob)
      end
    end

    def find(class_name, method = nil, *args)
      Delayed::Job.all.find do |job|
        data = YAML.load job.handler
        next unless data.is_a? PluginJob

        if !args.empty? #all args
          return job if class_name == data[:class_name] &&
                        method == data[:method] &&
                        args == data[:arguments]
        elsif method
          return job if class_name == data[:class_name] &&
                        method == data[:method]
        else
          return job if class_name == data[:class_name]
        end
      end

      return nil
    end

    # Counts the jobs which are running
    # @param[Object,String,Symbol] object on which job should run
    # @param[Symbol,nil] method called method or all method if nil passed
    # @param[Array] args list of all parameters or empty array which match any arguments
    def running (object, method = nil, *args)
      count = 0
      jobs.each do |job|
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
      !PluginJob.find(object, method, *args).nil?
    end

    # SQLite does not support concurrent write access to DB from different threads
    # This code retries to update DB if it fails (with 1 second delay),
    # If the retry procedure fails 20 times it gives up.
    # (See https://bugzilla.novell.com/show_bug.cgi?id=780389)
    def try_updating_db
      if block_given?
        # the current attempt number
        attempt = 0

        begin
          attempt += 1
          yield
        rescue SQLite3::SQLException => e
          if attempt <= 20
            # wait a little bit so the other process can finish writing,
            # but do not sleep in test mode (faster test run)
            sleep 1 unless Rails.env.test?

            Rails.logger.warn "DB update failed, retrying again (#{attempt})"
            retry
          else
            Rails.logger.error "DB update failed: #{e.message}"
            raise
          end
        end
      end
    end

  end

#internal method. Use run_async and running? for asynchronous jobs
  def perform

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

            try_updating_db do
              Delayed::Job.enqueue(PluginJob.new(self[:class_name],function_method,function_args),
                                 {:priority => resource.cache_priority, 
                                   :run_at => (resource.cache_reload_after).seconds.from_now})
            end

          end
        end
      end
    else
      Rails.logger.error "Method #{object}:#{function_method} not available"
    end
  end
end

