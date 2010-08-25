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

# this is a singleton class for managing background processes with progress
# for long running tasks

class BackgroundManager

  include Singleton

  attr_reader :running, :done
  # instance variables - they keep the information between requests

  def initialize
    # currently running requests in background (current states)
    @running = Hash.new
    # finished requests (actual results)
    @done = Hash.new
    # a mutex which guards access to the shared class variables above
    @mutex = Mutex.new
  end

  # define a new background process
  # id is unique ID
  def add_process(id)
    @mutex.synchronize do
      @running[id] = BackgroundStatus.new unless @running.has_key?(id)
    end
  end

  # is the process running?
  def process_running?(id)
    @mutex.synchronize do
      @running.has_key? id
    end
  end

  # is the process finished?
  def process_finished?(id)
    @mutex.synchronize do
      @done.has_key? id
    end
  end

  # does process exist? (you can also match id using a regexp - see get_matching_process_ids)
  def process_exists?(id)
    @mutex.synchronize do
      @done.has_key?(id) || @running.has_key?(id)
    end
  end

  # remove the progress status and remember the real final value
  def finish_process(id, value)
    @mutex.synchronize do
      @running.delete(id)
      @done[id] = value
    end
  end

  # get the current progress
  # returns a copy, use update_progress() for updating the progress
  def get_progress(id)
    @mutex.synchronize do
      ret = @running[id]
      ret = ret.dup unless ret.nil?
      ret
    end
  end

  # gets all ids of precess matching regex running and also done
  def get_matching_process_ids(regex)
    @mutex.synchronize do
      ret = []
      ret.merge @running.keys.select{ |k| k.to_s =~ regex }
      ret.merge @done.keys.select{ |k| k.to_s =~ regex }
      ret
    end
  end

  # get the final value, the value is removed from the internal structure
  def get_value(id)
    @mutex.synchronize do
      @done.delete id
    end
  end

  # update the progress
  def update_progress(id, &block)
    @mutex.synchronize do
      bs = @running[id]

      yield bs if bs && block_given?
    end
  end

  # is background processing possible?
  # if cache_classes is disabled it is not possible
  # because all classes are reloaded between requests
  # and the attributes keeping the progress are lost
  def background_enabled?
    return Rails.configuration.cache_classes
  end

end

