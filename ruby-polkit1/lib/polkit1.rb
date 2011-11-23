require "polkit1/version"
require 'polkit1.so' # native
require 'inifile'

module PolKit1
  POLKIT_PATH = "/etc/polkit-1/localauthority/"

  def self.polkit1_check(perm, user_name)
    raise "invalid user name" if (user_name =~ /\\$/ or user_name.include? "'")
    #get user id
    uid = `id -u '#{user_name}'`
    raise "unknown user" if $? != 0
    polkit1_check_uid perm, uid.to_i
  end

  def self.polkit1_write(section, perm, granted, user_name)
    raise "invalid user name" if (user_name =~ /\\$/ or user_name.include? "'")
    raise "section name required" if section.empty?
    raise "user name required" if user_name.empty?
    Dir.mkdir(POLKIT_PATH) unless File.directory?(POLKIT_PATH)
    path_name = POLKIT_PATH + section
    Dir.mkdir(path_name) unless File.directory?(path_name)
    file = File.join(path_name, perm + ".pkla" )
    if File.exists?(file)
      ini_file = IniFile.load(file,:comment => '#') 
    else
      ini_file = IniFile.new(file,:comment => '#')
      ini_file[perm]["Action"] = perm
      ini_file[perm]["ResultAny"] = "yes"
      ini_file[perm]["ResultInactive"] = "no"
      ini_file[perm]["ResultActive"] = "no"
    end
    permissions = []
    permission_string = "unix-user:"+user_name
    if ini_file[perm].has_key? "Identity"
      permissions = ini_file[perm]["Identity"].split(";")
      unless granted
        permissions = permissions.delete_if { |pe| pe == permission_string }
      else
        permissions << permission_string unless permissions.include?(permission_string)
      end
    else 
       permissions << permission_string
    end
    unless permissions.empty?
      ini_file[perm]["Identity"] = permissions.join(";")
    else
      ini_file.delete_section(perm)
    end
    ini_file.save     
    File.delete(file) if File.size(file) == 0
  end

end

