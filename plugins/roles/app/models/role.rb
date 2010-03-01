require 'yaml'
require 'exceptions'

# = Systemtime model
# Provides set and gets resources from YaPI time module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Role < BaseModel::Base

attr_accessor :users
attr_accessor :permissions
attr_accessor :name

ROLES_DEF_PATH = File.join Paths::VAR, "roles", "roles.yml"
ROLES_ASSIGN_PATH = File.join Paths::VAR, "roles", "roles_assign.yml"

def initialize(name,permissions=[],users=[])
  @name = name
  @permissions = (permissions||[]).sort
  @users = (users||[]).sort
end

def self.find(what=:all,options={})
  result = find_all
  return case what
  when :all then
     result.values
  else
    result.find { |k,v| k.to_sym == what }[1] #return value, not key
  end
end

private 
def self.find_all
  raise CorruptedFileException.new( ROLES_DEF_PATH ) unless File.exist? ROLES_DEF_PATH
  raise CorruptedFileException.new( ROLES_ASSIGN_PATH ) unless File.exist? ROLES_ASSIGN_PATH
  definitions = YAML::load( IO.read( ROLES_DEF_PATH ) ) #FIXME convert yaml parse error to own exc
  result = {}
  definitions.each do |k,v|
    result[k] = Role.new( k, v )
  end
  assigns = YAML::load( IO.read( ROLES_ASSIGN_PATH ) )
  assigns.each do |k,v|
    result[k] = Role.new(k) if result[k].nil? #incosistent files
    result[k].users = v.sort
  end
  return result
end

end
