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
    ret = Scr.execute("LANG=en.UTF-8 /sbin/yast2 --list")
    lines = ret[:stdout].split "\n"
    lines = lines.sort
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
  
  #
  # YastModule.new id
  #   Creates a new instance of YaST module <id>
  #
  # Attributes
  #  id: name of the YaST module
  #
  
  attr_reader :id, :commands
  
  def initialize id
    id = id.to_s unless id.is_a? String
    @id = id
    @commands = nil
  end

  
  def method_missing( method, *args )
#    raise "Unknown method #{method}" unless @commands.include?( method.to_s )
    :unknown
  end
  

  def commands ()
    if @commands != nil
       return @commands
    end
    @commands = Hash.new
    tmpdir = Scr.read( ".target.tmpdir" );
    Scr.execute("/bin/mkdir #{tmpdir}")
    tmpfile = tmpdir + "/yastOptions" 
    path = "LANG=en.UTF-8 /sbin/yast2 " + @id + " xmlhelp xmlfile=#{tmpfile}"
    Scr.execute (path)
    file = Scr.readArg(".target.string",tmpfile)
    if file != false
      doc = REXML::Document.new file
      doc.elements.each("commandline/commands/command") { |commandElement| 
        command = Hash.new
        command['help'] = commandElement.elements['help'].to_a[0]
        optionsElement = commandElement.elements['options']
        options = Hash.new
        if optionsElement
           optionsElement.each() { |optionElement| 
             if optionElement.to_s.lstrip.length > 0
               option = Hash.new
               option["help"] = optionElement.elements['help'].to_a[0]
               option["type"] = optionElement.elements['type'].to_a[0]
               options[optionElement.elements['name'].to_a[0]] = option
             end
           }
        end
        command['options'] = options
        @commands[commandElement.elements['name'].to_a[0]] = command
      }
    end
    puts "Founded command options/calls #{@commands.inspect}"

    Scr.execute("/bin/rm  #{tmpfile}")
    return @commands
  end

  #
  # See 'The Rails Way', page 510
  #

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.module do
       xml.tag!(:id, @id )
       if @commands != nil
         xml.commands do
	   @commands.each do |name,descr|
             xml.command do
               xml.tag!(:name, name)
               xml.tag!(:help, descr["help"])
               xml.options do
                 descr["options"].each do |nameOption,option|
                   xml.option do
                     xml.tag!(:name, nameOption)
                     xml.tag!(:type, option["type"])
                     xml.tag!(:help, option["help"])
                   end
                 end
               end
             end
           end
         end
       end
    end  
  end  

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
