
# = Language model
# Provides set and gets resources from YaPI language module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Language < BaseModel::Base
  
  # current language
  attr_accessor   :current
  # utf8 settings ("true" or "false")
  attr_accessor   :utf8
  # root locale settings ("true" or "false" or "ctype")
  # see yast-country documentation
  attr_accessor   :rootlocale
  # available languages on target machine.
  #
  # It is a array of hashs. Each hash contain keys id ( of language,
  # value for language variable) and name (which is localized language
  # name in UTF8.
  attr_reader     :available

  private
  
  # Creates argument for dbus call which specify what data is requested.
  # return:: hash with requested keys
  def self.create_read_question #:doc:
    {
      "current" => "true",
      "utf8" => "true",
      "rootlang" => "true",
      "languages" => "true"
    }
  end
  
  public
  # Parses response from dbus YaPI call
  # response:: response from dbus
  def parse_response(response) #:doc:
    @current = response["current"]
    @utf8 = response["utf8"]
    @rootlocale = response["rootlang"]
    if response["languages"]
      @available = response["languages"].collect { |k,v| { :id => k, :name => v[0] } } # v array => [native UTF8, native ascii, UTF8 extension, english name]
    end
  end

  # fills language instance with data from YaPI.
  def Language.find(*args)
    ret = Language.new
    ret.parse_response YastService.Call("YaPI::LANGUAGE::Read",create_read_question)
    return ret
  end

  # Saves data from model to system via YaPI
  def save
    settings = {}
    settings["current"] = @current if @current #set only if value is passed
    settings["utf8"] = @utf8 if @utf8 #set only if value is passed
    settings["rootlang"] = @rootlocale if @rootlocale #set only if value is passed
    YastService.Call("YaPI::LANGUAGE::Write",settings)
  end
end
