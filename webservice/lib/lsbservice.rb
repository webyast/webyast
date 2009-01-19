#
# This provides generic commands for
# LSB compatible services
#
#
#
class Lsbservice
  PREFIX = '/etc/init.d/'
  
  #
  # iterates over all service links
  #
  def self.each
#    Dir.entries(PREFIX).each do |d|
     ["cron", "cups", "gpm", "ntp", "random", "smbfs", "sshd", "nfs",
      "autofs", "apache2", "avahi-daemon", "SuSEfirewall2" ].each do |d|
      next if d[0,1] == '.'
      next if d == "README"
      next if d == "reboot"
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
  # Lsbservice.new link
  #   Creates a new instance of Lsbservice for service <link>
  #
  # Attributes
  #  link: link of the service
  #  path: path to init script
  #  commands: available commands as array of strings, typically "start", "stop", ...
  #
  
  attr_reader :link, :path, :commands
  attr_accessor :error_id, :error_string
  
  def initialize link
    link = link.to_s unless link.is_a? String
    @link = link
    @commands = []
    @error_id = 0
    @error_string = ""
    @path = PREFIX+link
    raise "Unexisting service" unless File.exists?( path )
    if File.executable?( path )
      # run init script to get its 'Usage' line
      IO.popen( path, 'r+' ) do |pipe|
	loop do
	  break if pipe.eof?
	  l = pipe.read
	  case l
	  when /Usage:\s*(\S*)\s*\{([^\}]*)\}/
	    	  STDERR.puts "USAGE: #{$1}, #{$2}"
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
  
  def method_missing( method, *args )
    raise "Unknown method #{method}" unless @commands.include?( method.to_s )
    puts "Running '#{@path} #{method}'"
    system("#{@path} #{method} #{args.join(' ')} > /dev/null 2>&1")
    puts "Returned #{$?.class}, #{$?.inspect}, #{$?.exitstatus}"
    s = $?.exitstatus
    return @@states[ s ] if s < @@states.size
    :unknown
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
      xml.tag!(:commands, @commands.join(","))
      xml.tag!(:error_id, @error_id )
      xml.tag!(:error_string, @error_string )
    end  
  end

end
