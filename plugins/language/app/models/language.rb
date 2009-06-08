class Language 

  attr_accessor :first_language, 
                :second_languages,
                :available

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------
private
#
# get
#


  def fill_available
     ret = Scr.instance.execute(["/sbin/yast2", "language", "list"])
     if ret && ret[:exit] == 0
       @available = ret[:stderr]
     else
       logger.error "yast2 language list returns error"
       @available = ""
     end
  end

  def get_languages
     ret = Scr.instance.execute(["/sbin/yast2", "language", "summary"])
     if ret && ret[:exit] == 0
       lines = ret[:stderr].split "\n"
       lines.each do |s|
         column = s.split(" ")
         case column[0]
           when "Current"
             @first_language = column[2]
           when "Additional"
             @second_languages = column[2]
         end
       end
     else
       logger.error "yast2 language list returns summary"
       @second_languages = ""
       @first_language = ""
     end
  end

#
# set
#

  def write_first_language
    Scr.instance.execute(["/sbin/yast2", "language", "set",  "lang=#{@first_language}", "no_packages"])
  end

  def write_second_languages
    Scr.instance.execute(["/sbin/yast2", "language", "set", "languages=#{@second_languages.join(",")}", "no_packages"])
  end



public
  def initialize 
     @second_languages = ""
     @available = ""
  end

  def read
    initialize
    fill_available
    get_languages
  end

  def safe ()
    write_first_language
    write_second_languages
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.language do
      xml.tag!(:first_language, @first_language )
      xml.second_languages({:type => "array"}) do
         @second_languages.split( "," ).each do |lang| 
            xml.language do
               xml.tag!(:id, lang)
            end
         end
      end
      xml.available({:type => "array"}) do
         @available.split("\n").each do |line|
           xml.language do
              # Checking input data before processing
              # Example: pt_BR (Portugues brasileiro)
              if line.match(/^[\w_]+ \(.*\)/)
                xml.tag!(:id, line[0..(line.index('(')-2)])
                xml.tag!(:name, line[(line.index('(')+1)..(line.length-2)])
              else
                raise "Unexpected input:\n" + line + "\n\nGot:\n" + @available
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
