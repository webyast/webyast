

require 'singleton'

class DbusLock

  include Singleton

  def initialize
    @lock = Mutex.new
  end

  def locked?
    @lock.locked?
  end

  def synchronize
    @lock.synchronize do
      yield
    end
  end
  
  def self.locked?
    DbusLock.instance.locked?
  end

  def self.synchronize
    Rails.logger.info "Waiting for DBus lock... (#{caller(2).first})"

    DbusLock.instance.synchronize do
        Rails.logger.info "DBus lock obtained (#{caller(3).first})"
        yield
    end

    Rails.logger.info "DBus lock released"
  end

end
