class Language 
@@available = []
attr_reader :language,
              :utf8,
              :rootlocale,
              :available
#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------
public
#
# get
#


  def fill_available
     @@available = YastService.Call("YaPI::LANGUAGE::GetLanguages")
  end

  def fill_language    
    @language = YastService.Call("YaPI::LANGUAGE::GetCurrentLanguage")
  end

  def fill_utf8
    @utf8 = YastService.Call("YaPI::LANGUAGE::IsUTF8")
  end

  def fill_rootlocale
    @rootlocale = YastService.Call("YaPI::LANGUAGE::GetRootLang")
  end

#
# set
#
public
  def language=(arg)
    @language=arg
    unless YastService.Call("YaPI::LANGUAGE::SetCurrentLanguage",arg)
      Rails.logger.error "yast2 language not set"
    end
  end

  def utf8=(arg)
    @utf8=arg
    unless YastService.Call("YaPI::LANGUAGE::SetUTF8",@utf8)
      Rails.logger.error "yast2 utf8 not set"
    end
  end
  def rootlocale=(arg)
    @rootlocale=arg
    unless YastService.Call("YaPI::LANGUAGE::SetRootLang",@rootlocale)
      Rails.logger.error "yast2 root locale not set"
    end
  end
  
  def initialize
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.language do
      xml.tag!(:current, @language )
      xml.tag!(:utf8, @utf8)
      xml.tag!(:rootlocale, @rootlocale )
      xml.available({:type => "array"}) do
         @@available.each do |line|
           xml.language do
              # Checking input data before processing
              # Example: pt_BR (Portugues brasileiro)
              if line.match(/^[\w_]+---.*/)
                xml.tag!(:id, line[0..(line.index('---')-1)])
                xml.tag!(:name, line[(line.index('---')+3)..(line.length)])
              else
                raise "Unexpected input:\n" + line + "\n\nGot:\n" + @@available
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
