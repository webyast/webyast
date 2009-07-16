class Systemtime

  @@timezones = Array.new()

  attr_accessor :date,
    :time,
    :timezone,
    :utcstatus

  private
  def parse_response(response)
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

  def create_read_question
    ret = {
      "timezone" => "true",
      "utcstatus" => "true",
      "currenttime" => "true"
    }
    ret["zones"]= @@timezones.empty? ? "true" : "false"
    return ret
  end

  public

  def timezones
    return @@timezones
  end

  def initialize     
  end

  def find
    parse_response YastService.Call("YaPI::TIME::Read",create_read_question)
  end

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
