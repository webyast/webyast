# = Language model
# Provides set and gets resources from YaPI time module.
# Main goal is handle YaPI specific calls and data formats. Provide cleaned
# and well defined data.
class Language
  # cache available languages as it is change only rarely
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

  # Parses response from dbus YaPI call
  # response:: response from dbus
  def parse_response(response)
    @language = response["current"]
    @utf8 = response["utf8"]
    @rootlocale = response["rootlang"]
    if response["languages"]
        @@available = response["languages"]
    end
  end

  # Creates argument for dbus call which specify what data is requested.
  # Available languages is cached so request it only if it is necessary.
  # return:: hash with requested keys
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

  # Getter for available static field
  def Language.available
    return @@available
  end

  # fills language instance with data from YaPI.
  # +warn+: Doesn't take any parameters and is not static.
  def find
    parse_response YastService.Call("YaPI::LANGUAGE::Read",create_read_question)
  end

  # Saves data from model to system via YaPI
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
