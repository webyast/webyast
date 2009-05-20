class Language 

  attr_accessor :first_language, 
                :second_languages,
                :available

  def initialize 
     @second_languages = ""
     @available = ""
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
              xml.tag!(:id, line[0..(line.index('(')-2)])
              xml.tag!(:name, line[(line.index('(')+1)..(line.length-2)])
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
