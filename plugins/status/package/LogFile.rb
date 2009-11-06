require 'yaml'

module LogFile

  def self.Read(id, lines)
    parsed	= {}
    file_name	= "/etc/webyast/vendor/logs.yml"
    if File.exists?(file_name)
      parsed = YAML::load(File.open(file_name));
      parsed = {} unless parsed.is_a? Hash
    end

    path	= parsed[id]["path"]

    # FIXME this is wrong, system does not return stdout, but only boolean
    ret		= Kernel.system("tail -n #{lines} #{path}")
    return ret
  end
end
