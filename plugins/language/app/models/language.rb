class Language 
  @@available = {}
  attr_accessor  :language,
    :utf8,
    :rootlocale
  #--------------------------------------------------------------------------------
  #
  #local methods
  #
  #--------------------------------------------------------------------------------
  private
  #
  # dbus parsers
  #

  def parse_response(response)
    @language = response["current"]
    @utf8 = response["utf8"]
    @rootlocale = response["rootlang"]
    if response["languages"]
        @@available = response["languages"]
    end
  end

  def create_read_question
    ret = {
      "current" => "true",
      "utf8" => "true",
      "rootlang" => "true"
    }
    ret["languages"]= "true" if @@available.empty?
    return ret
  end


  

  #
  # set
  #
  public

  def available
    return @@available
  end

  def find
    parse_response YastService.Call("YaPI::LANGUAGE::Read",create_read_question)
  end

  def save
    settings = {
      "current" => @language,
      "utf8" => @utf8,
      "rootlang" => @rootlocale
    }
    YastService.Call("YaPI::LANGUAGE::Write",settings)
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
        @@available.each do |k,v|
          xml.language do
            xml.tag!(:id, k)
            xml.tag!(:name, v[0]) # [native UTF8, native ascii, UTF8 extension, english name]
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
