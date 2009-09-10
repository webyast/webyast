require 'resolvable'

class Package < Resolvable

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.package do
      xml.tag!(:resolvable_id, @resolvable_id )
      xml.tag!(:name, @name )
      xml.tag!(:version, @version )
    end
  end

  def self.find(what)
    if what == :installed
      package_list = Array.new
      self.execute("GetPackages", what.to_s, "Package") { |line1,line2,line3|
        columns = line2.split ";"
        package = Package.new(:resolvable_id => line2,
                              :name => columns[0],
                              :version => columns[1]
                             )
                            # :arch => columns[2],
                            # :repo => columns[3],
                            # :summary => line3 )
       package_list << package
     }
    package_list
    end
  end
end
