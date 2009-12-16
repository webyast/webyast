
# this is a singleton class for managing background processes with progress
# for long running tasks

class BackgroundManager

  include Singleton

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
    ret = false
    @mutex.synchronize do
      ret = @running.has_key? id
    end
    ret
  end

  # is the process finished?
  def process_finished?(id)
    ret = false
    @mutex.synchronize do
      ret = @done.has_key? id
    end
    ret
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
    ret = nil
    @mutex.synchronize do
      ret = @running[id]
      ret = ret.dup unless ret.nil?
    end
    ret
  end

  # get the final value, the value is removed from the internal structure
  def get_value(id)
    ret = nil
    @mutex.synchronize do
      ret = @done.delete id
    end
    ret
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

