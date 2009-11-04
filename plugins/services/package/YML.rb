require 'yaml'

# simple module for parsimg yaml files
module YML
  def self.parse(file_name)
    ret = {}
    if File.exists?(file_name)
      ret = YAML::load(File.open(file_name));
      ret = {} unless ret.is_a? Hash
    end
    return ret
  end
end
