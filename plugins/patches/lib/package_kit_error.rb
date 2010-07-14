
class PackageKitError < BackendException
  def initialize(description)
    @description = description
    super("PackageKit error")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "PACKAGEKIT_ERROR"
      xml.description @description
    end
  end
end


