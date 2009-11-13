
# = Language model
# Provides set and gets resources from YaPI language module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Language

  # cache available languages as it is change only rarely
  @@available = {}
  
  # current language
  attr_accessor   :language
  # utf8 settings ("true" or "false")
  attr_accessor   :utf8
  # root locale settings ("true" or "false" or "ctype")
  # see yast-country documentation
  attr_accessor   :rootlocale

  private
  
  # Creates argument for dbus call which specify what data is requested.
  # Available languages is cached so request it only if it is necessary.
  # return:: hash with requested keys
  def self.create_read_question #:doc:
    ret = {
      "current" => "true",
      "utf8" => "true",
      "rootlang" => "true"
    }
    if @@available.nil? || @@available.empty?
      ret["languages"]= "true"
    end
    return ret
  end
  
  public
  # Parses response from dbus YaPI call
  # response:: response from dbus
  def parse_response(response) #:doc:
    @language = response["current"]
    @utf8 = response["utf8"]
    @rootlocale = response["rootlang"]
    if response["languages"]
        @@available = response["languages"]
    end
  end

  # Getter for available static field
  def available
    @@available
  end

  # fills language instance with data from YaPI.
  # 
  # +warn+: Doesn't take any parameters.
  def Language.find
    ret = Language.new
    ret.parse_response YastService.Call("YaPI::LANGUAGE::Read",create_read_question)
    return ret
  end

  # Saves data from model to system via YaPI
  def save
    settings = {}
    settings["current"] = @language if @language #set only if value is passed
    settings["utf8"] = @utf8 if @utf8 #set only if value is passed
    settings["rootlang"] = @rootlocale if @rootlocale #set only if value is passed
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
