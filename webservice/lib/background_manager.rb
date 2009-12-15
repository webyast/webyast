
# this is a helper module for managing background processes with progress
# for long running tasks

module BackgroundManager
  # class variables - they keep the information between requests
  # DO NOT USE THEM DIRECTLY, USE THE THREAD SAFE METHODS BELOW!
  #
  # currently running requests in background (current states)
  @@running = Hash.new
  # finished requests (actual results)
  @@done = Hash.new
  # a mutex which guards access to the shared class variables above
  @@mutex = Mutex.new

  # define a new background process
  # id is unique ID
  def add_process(id)
    @@mutex.synchronize do
      @@running[id] = BackgroundStatus.new unless @@running.has_key?(id)
    end
  end

  # is the process running?
  def process_running?(id)
    @@mutex.synchronize do
      return @@running.has_key? id
    end
  end

  # is the process finished?
  def process_finished?(id)
    @@mutex.synchronize do
      return @@done.has_key? id
    end
  end

  # remove the progress status and remember the real final value
  def finish_process(id, value)
    @@mutex.synchronize do
      @@running.delete(id)
      @@done[id] = value
    end
  end

  # get the current progress
  # returns a copy, use update_progress() for updating the progress
  def get_progress(id)
    @@mutex.synchronize do
      ret = @@running[id]
      ret.nil? ? nil : ret.dup
    end
  end

  # get the final value, the value is removed from the internal structure
  def get_value(id)
    @@mutex.synchronize do
      return @@done.delete id
    end
  end

  # update the progress
  def update_progress(id, &block)
    @@mutex.synchronize do
      bs = @@running[id]

      yield bs if bs && block_given?
    end
  end

  # is background processing possible?
  # if cache_classes is disabled it is not possible
  # because all classes are reloaded between requests
  # and the static attributes keeping the progress are lost
  def background_enabled?
    return Rails.configuration.cache_classes
  end

end

