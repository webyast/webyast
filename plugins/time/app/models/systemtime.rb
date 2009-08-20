# = Systemtime model
# Provides set and gets resources from YaPI time module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Systemtime

  @@timezones = Array.new()

  # Date settings format is dd/mm/yyyy
  attr_accessor :date
  # time settings format is hh:mm:ss
  attr_accessor :time
  # Current timezone as id
  attr_accessor :timezone
  # Utc status possible values is UTCOnly, UTC and localtime see yast2-country doc
  attr_accessor :utcstatus

  private

  # Creates argument for dbus call which specify what data is requested.
  # Available timezones is cached so request it only if it is necessary.
  # return:: hash with requested keys
  def Systemtime.create_read_question #:doc:
    ret = {
      "timezone" => "true",
      "utcstatus" => "true",
      "currenttime" => "true"
    }
    ret["zones"]= @@timezones.empty? ? "true" : "false"
    return ret
  end

  public

  # Parses response from dbus YaPI call
  # response:: response from dbus
  def parse_response(response) #:doc:
    timedate = response["time"]
    @time = timedate[timedate.index(" - ")+3,8]
    @date = timedate[0..timedate.index(" - ")-1]
    #convert date to format for datepicker
    @date.sub!(/^(\d+)-(\d+)-(\d+)/,'\3/\2/\1')
    @utcstatus= response["utcstatus"]
    @timezone = response["timezone"]
    if response["zones"]
      @@timezones = response["zones"]
    end
  end

  #Getter for static timezones
  def Systemtime.timezones
    return @@timezones
  end

  def Systemtime.create_from_xml(xmlroot)
    systemtime = Systemtime.new
    systemtime.time = xmlroot[:time]
    systemtime.date = xmlroot[:date]
    systemtime.timezone = xmlroot[:timezone]
    systemtime.utcstatus = xmlroot[:utcstatus]
    return systemtime
  end

  def initialize     
  end

  # fills time instance with data from YaPI.
  #
  # +warn+: Doesn't take any parameters.
  def Systemtime.find
    ret = Systemtime.new()
    ret.parse_response YastService.Call("YaPI::TIME::Read",create_read_question)
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    settings = {}
    if @timezone and !@timezone.empty?
      settings["timezone"] = @timezone
    end
    if @utcstatus and !@utcstatus.empty?
      settings["utcstatus"] = @utcstatus
    end
    need_rescue = false
    if (@date and !@date.empty?) and
        (@time and !@time.empty?)
      date = @date.split("/")
      datetime = "#{date[2]}-#{date[0]}-#{date[1]} - "+@time
      settings["currenttime"] = datetime
      need_rescue = true
    end
    begin
      YastService.Call("YaPI::TIME::Write",settings)
    rescue Exception => e
      #XXX hack to avoid dbus timeout durign moving time to future
      unless need_rescue
        raise
      end

    end
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.systemtime do
      xml.tag!(:time, @time )
      xml.tag!(:date, @date )
      xml.tag!(:timezone, @timezone )
      xml.tag!(:utcstatus, @utcstatus )
      xml.timezones({:type => "array"}) do
        @@timezones.each do |region|
          if not region.empty?
            xml.region do
              xml.tag!(:name,  region["name"])
              xml.tag!(:central,  region["central"])
              xml.entries({:type => "array"}) do
                region["entries"].each do |id,name|
                  xml.timezone do
                    xml.tag!(:id, id)
                    xml.tag!(:name, name)
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
