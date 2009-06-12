class Commands
end

#
# This provides generic commands for
# LSB compatible services
#
#
#
class Lsbservice
  PREFIX = '/etc/init.d/'
  
  # Iterates over all service links
  # Makes up some because the real ones are too many
  # to store in a session cookie (?!?!)    
  def self.mock_each
    items = ["cron", "cups", "gpm", "ntp", "random", "smbfs", "sshd", "nfs",
      "java.binfmt_misc",
      "autofs", "apache2", "avahi-daemon", "SuSEfirewall2_setup", "pure-ftpd" ]
    items.each {|i| yield i}
  end
    
  #
  # iterates over all service links
  #
  def self.each
    Dir.foreach(PREFIX) do |d|
      next if d[0,1] == '.'
      # halt kills the X session
      next if %w(README boot halt rc reboot skeleton skeleton.compat).include? d
      next if File.directory?( PREFIX+d )
      yield d
    end
  end
    
  #
  # Lsbservice.all -> Array of string
  #  returns array of all available services
  #
  
  def self.all
    result = []
    each do |d|
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
  # Lsbservice.new link
  #   Creates a new instance of Lsbservice for service <link>
  #
  # Attributes
  #  link: link of the service
  #  path: path to init script
  #  commands: available commands as array of strings, typically "start", "stop", ...
  #
  
  attr_reader :link, :path, :commands
  
  def initialize link
    link = link.to_s unless link.is_a? String
    @link = link
    @commands = []
    @path = PREFIX+link
    raise "Nonexistent service #{link}" unless File.exists?( path )
    if File.executable?( path )
      # run init script to get its 'Usage' line
      IO.popen( path, 'r+' ) do |pipe|
	loop do
	  break if pipe.eof?
	  l = pipe.read
	  case l
	  when /Usage:\s*(\S*)\s*\{([^\}]*)\}/
#	    	  STDERR.puts "USAGE: #{$1}, #{$2}"
	    @path = $1
	    @commands = $2.split("|")
	    break
	  end
	end
      end
    end
    if @commands.length == 0
      #put at least run|stop|status|restart
      @commands = ["run",
                   "stop",
                   "status",
                   "restart"]
    end
  end
  
  
  #
  # See 'The Rails Way', page 510
  #
  
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.service do
      xml.tag!(:link, @link )
      xml.tag!(:path, @path )
      xml.commands do 
         @commands.each do |c|
            xml.command do 
              xml.tag!(:name, c)
            end
         end
      end
    end  
  end

end
