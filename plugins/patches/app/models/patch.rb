require 'resolvable'

# Model for patches available via package kit
class Patch < Resolvable

  @@running = Hash.new
  @@done = Hash.new

  def to_xml( options = {} )
    super :patch_update, options
  end

  # find patches using PackageKit
  def self.do_find(what, bg_status = nil)
    patch_updates = Array.new
    self.execute("GetUpdates", "NONE", "Package", bg_status) { |line1,line2,line3|
      columns = line2.split ";"
      if what == :available || columns[1] == what
        update = Patch.new(:resolvable_id => columns[1],
                           :kind => line1,
                           :name => columns[0],
                           :arch => columns[2],
                           :repo => columns[3],
                           :summary => line3 )
        return update if columns[1] == what #only the first entry will be returned in a hash
        patch_updates << update
      end
    }
    return patch_updates
  end

  # find patches
  # Patch.find(:available)
  # Patch.find(212)
  def self.find(what, opts = {})
    background = opts[:background]

    # background reading doesn't work correctly if class reloading is active
    # (static class members are lost between requests)
    if background && !Rails.configuration.cache_classes
      Rails.logger.info "Class reloading is active, cannot run background thread (set config.cache_classes = true)"
      background = false
    end

    if background
      if @@done.has_key?(what)
        Rails.logger.debug "Request #{what} is done"
        @@running.delete(what)
        return @@done.delete(what)
      end

      running = @@running[what]
      if running
        Rails.logger.debug "Request #{what} is already running: #{running.inspect}"
        return [running]
      end

      bs = BackgroundStatus.new
      @@running[what] = bs

      Rails.logger.info "Starting background thread for reading patches..."
      Thread.new do
        res = do_find(what, bs)
        Rails.logger.info "*** Patches thread: Found #{res.size} applicable patches"
        @@done[what] = res
      end

      return [bs]
    else
      return do_find(what)
    end
  end

  # installs this
  def install
    self.class.install(id)
  end

  # Patch.install(patch)
  # Patch.install(id)
  def self.install(patch)
    if patch.is_a?(Patch)
      update_id = "#{patch.name};#{patch.resolvable_id};#{patch.arch};#{patch.repo}"
      Rails.logger.debug "Install Update: #{update_id}"
      self.package_kit_install(update_id)
    else
      # if is not an object, assume it is an id
      patch_id = patch
      patch = Patch.find(patch_id)
      raise "Can't install update #{patch_id} because it does not exist" if patch.nil? or not patch.is_a?(Patch)
      self.install(patch)
    end
  end

end
