class Systemtime

  @@timezones = Array.new()

  attr_accessor :datetime,
                :timezone,
                :utcstatus

  private
  def parse_response(response)
    @datetime = response["time"]
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
    unless @timezone.nil? or @timezone.empty?
      settings["timezone"] = @timezone
    end
    unless @utcstatus.nil? or @utcstatus.empty?
      settings["utcstatus"] = @utcstatus
    end
    unless @datetime.nil? or @datetime.empty?
      settings["currenttime"] = @datetime
    end
    YastService.Call("YaPI::TIME::Write",settings)
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.systemtime do
      xml.tag!(:time, @datetime )
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
