require "rexml/document"

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
    Scr.execute ("/bin/chmod -R 755 #{tmpdir}")

    file = File.new( tmpfile )
    doc = REXML::Document.new file
    @commands = Hash.new
    doc.elements.each("commandline/commands/command") { |commandElement| 
      command = Hash.new
      command['help'] = commandElement.elements['help'].to_a[0]
      optionsElement = commandElement.elements['options']
      options = Hash.new
      optionsElement.each() { |optionElement| 
        if optionElement.to_s.lstrip.length > 0
          option = Hash.new
          option["help"] = optionElement.elements['help'].to_a[0]
          option["type"] = optionElement.elements['type'].to_a[0]
          options[optionElement.elements['name'].to_a[0]] = option
        end
      }
      command['options'] = options
      @commands[commandElement.elements['name'].to_a[0]] = command
    }
    puts "Founded command options/calls #{@commands.inspect}"

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
