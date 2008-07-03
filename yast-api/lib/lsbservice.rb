#
# This provides generic functions for
# LSB compatible services
#
#
#
class Lsbservice
  PREFIX = '/etc/init.d/'
  
  #
  # iterates over all service names
  #
  def self.each
    Dir.entries(PREFIX).each do |d|
      next if d[0,1] == '.'
      next if d == "README"
      next if File.directory?( PREFIX+d )
      yield d
    end
  end
    
  #
  # Lsbservice.all -> Array of string
  #  returns array of all available services
  #
  
  def Lsbservice.all
    result = []
    Lsbservice::each do |d|
      result << d
    end
    result
  end

  # 0 - success
  # 1 - generic or unspecified error
  # 2 - invalid or excess argument(s)
  # 3 - unimplemented feature (e.g. "reload")
  # 4 - insufficient privilege
  # 5 - program is not installed
  # 6 - program is not configured
  # 7 - program is not running
  @@states = [ :success, :error, :badargs, :unimplemented, :noperm, :notinstalled, :notconfigured, :notrunning ]
  
  #
  # Lsbservice.new name
  #   Creates a new instance of Lsbservice for service <name>
  #
  # Attributes
  #  path: path to init script
  #  functions: available functions as array of strings, typically "start", "stop", ...
  #
  
  attr_reader :path, :functions
  def initialize name
    name = name.to_s unless name.is_a? String
    IO.popen( PREFIX+name, 'r+' ) do |pipe|
      loop do
	break if pipe.eof?
	l = pipe.read
        case l
	when /Usage:\s*(\S*)\s*{([^}]*)}/
#	  STDERR.puts "USAGE: #{$1}, #{$2}"
	  @path = $1
	  @functions = $2.split "|"
	  break
	end
      end
    end
  end
  
  def method_missing( method, *args )
    raise "Unknown method #{method}" unless @functions.include?( method.to_s )
    system( PREFIX + @name, method.to_s, *args )
    @@states[ $? ]
  end
end
