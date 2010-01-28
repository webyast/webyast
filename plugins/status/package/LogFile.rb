require 'yaml'

# simple ruby module for reading last n lines from given file
# files for reading are specified in the configuration file
# /etc/webyast/vendor/logs.yml
module LogFile

  def self.Read(id, pos_begin, lines)
    parsed	= {}
    file_name	= "/etc/webyast/vendor/logs.yml"
    if File.exists?(file_name)
      parsed = YAML::load(File.open(file_name));
      parsed = {} unless parsed.is_a? Hash
    end

    unless parsed.has_key? id
      return "___WEBYAST___INVALID"
    end
    
    path = parsed[id]["path"]
    p_begin = pos_begin.to_i rescue 1 #if someone pass type which doesn't have to_i
    lcount = lines.to_i rescue 50 #if someone pass type which doesn't have to_i
    ret = `wc -l #{path}`
    file_length = ret.split()[0].to_i rescue 0 #if someone pass type which doesn't have to_i
    if p_begin > 0 && p_begin < file_length-lcount
      tail_pos = file_length-p_begin
    else
      tail_pos = lcount
    end
    #it is secure, because vendor specify path and lines is always number
    ret	= `tail -n #{tail_pos} #{path}|head -n #{lcount}`
    return {:value=>ret, :position=>"#{file_length-tail_pos}"}
  end
end
