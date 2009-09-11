require 'resolvable'

class Package < Resolvable

  def to_xml( options = {} )
    super :package, options
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
