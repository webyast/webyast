require 'yaml'

# simple ruby module for reading last n lines from given file
# files for reading are specified in the configuration file
# /etc/webyast/vendor/logs.yml
module LogFile

  def self.Read(id, lines)
    parsed	= {}
    file_name	= "/etc/webyast/vendor/logs.yml"
    if File.exists?(file_name)
      parsed = YAML::load(File.open(file_name));
      parsed = {} unless parsed.is_a? Hash
    end

    unless parsed.has_key? id
      return "___WEBYAST___INVALID"
    end
    
    path	= parsed[id]["path"]
    lcount = lines.to_i rescue 0 #if someone pass type which doesn't have to_i
    lcount = 1 if lcount==0
#it is secure, because vendor specify path and lines is always number
    ret		= `tail -n #{lcount} #{path}`
    return ret
  end
end
