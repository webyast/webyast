#
# This provides generic commands for
# YaST modules in the command line mode
#
class YastModule
  require "scr"  
  #
  # iterates over all yast module links
  #
  def self.each
    # run YaST to get a list of modules
    ret = Scr.execute ("LANG=en.UTF-8 /sbin/yast2 --list")
    lines = ret[:stdout].split "\n"
    lines::each do |l|   
      if l.length > 0 && l != "Available modules:"
          yield l
      end
    end
  end
    
  #
  # YastModule.all -> Array of string
  #  returns array of all available YaST modules
  #

  def YastModule.all
    result = []
    YastModule::each do |d|
      result << d
    end
    result
  end


  def YastModule.getcommands link
    tmpdir = Scr.read( ".target.tmpdir" );
    Scr.execute ("/bin/mkdir #{tmpdir}")
    tmpfile = tmpdir + "/yastOptions" 
    path = "LANG=en.UTF-8 /sbin/yast2 " + link + " xmlhelp xmlfile=#{tmpfile}"
    Scr.execute (path)

#    @commands = Hash.from_xml(tmpfile)
STDERR.puts "xxxxxxxxxxxxxxx /usr/local/src/rails/rest-service/yast-api/test/rest_tests/users_tux_sshkey"
#@commands = Hash.from_xml("/usr/local/src/rails/rest-service/yast-api/test/rest_tests/users_tux_sshkey")
 Hash.from_xml("/usr/local/src/rails/rest-service/yast-api/test/rest_tests/users_tux_sshkey")
STDERR.puts "xxxxxxxxxxxxxxx#{@commands.inspect}"

    Scr.execute ("/bin/rm -rf #{tmpdir}")
    return @commands
  end
  
  #
  # YastModule.new link
  #   Creates a new instance of YaST module <link>
  #
  # Attributes
  #  link: link of the YaST module
  #
  
  attr_reader :link
  
  def initialize link
    link = link.to_s unless link.is_a? String
    @link = link
  end
  
  def method_missing( method, *args )
#    raise "Unknown method #{method}" unless @commands.include?( method.to_s )
    :unknown
  end
  
  #
  # See 'The Rails Way', page 510
  #

  def to_xml( options = {} )
    STDERR.puts "#{self}.to_xml"
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
#    xml.modules do
#      xml.tag!(:link, @link )
#      xml.commands do
#	@commands.each do |f|
#	  xml.tag!(:link, f)
#	end
#      end
#    end  
  end  

end
