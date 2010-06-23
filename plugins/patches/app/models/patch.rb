require 'resolvable'

# Model for patches available via package kit
class Patch < Resolvable

  def to_xml( options = {} )
    super :patch_update, options
  end

  # find patches
  # Patch.find(:available)
  # Patch.find(212)
  def self.find(what)
    patch_updates = Array.new
    self.execute("GetUpdates", "NONE", "Package") { |line1,line2,line3|
      columns = line2.split ";"
      if what == :available || columns[1] == what
        update = Patch.new(:resolvable_id => columns[1],
                           :kind => line1,
                           :name => columns[0],
                           :arch => columns[2],
                           :repo => columns[3],
                           :summary => line3 )

        if what == :available
          # add the update to the list
          patch_updates << update
        else
          # just return this single update
          patch_updates = update
        end
      end
    }
    return patch_updates
  end

  # installs this
  def install(background = false)
    self.class.install(id, background)
  end

  # Patch.install(patch)
  # Patch.install(id)
  def self.install(patch, background = false)
    if patch.is_a?(Patch)
      update_id = "#{patch.name};#{patch.resolvable_id};#{patch.arch};#{patch.repo}"
      Rails.logger.debug "Install Update: #{update_id}"
      self.package_kit_install(update_id, background)
    else
      # if is not an object, assume it is an id
      patch_id = patch
      patch = Patch.find(patch_id)
      raise "Can't install update #{patch_id} because it does not exist" if patch.nil? or not patch.is_a?(Patch)
      self.install(patch, background)
    end
  end

end
