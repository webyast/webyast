#
# Resource class
#

class Resource
  require 'resource_registration'
  attr_accessor :implementations

  class Implementation
    attr_accessor :controller, :interface

    def initialize(interface, impl_hash)
      @interface = interface
      @policy    = impl_hash[:policy]
      @singular  = impl_hash[:singular]
      @controller= impl_hash[:controller]
    end

    def link_to
      "/#{@controller}/#{action}"
      #               url_for :only_path => :true,
      #                       :controller => @controller,
      #                       :action => (@singular ? :show : :index)
    end

    def action
      @singular ? :show : :index
    end

    def to_xml(xml_builder = nil)
      xml = xml_builder || Builder::XmlMarkup.new
      xml.resource do
        xml.interface(@interface)
        xml.policy(@policy)
        xml.singular(@singular, :type => :boolean)
        xml.href(link_to)
      end 
    end

    def to_json
      Hash.from_xml(to_xml).to_json
    end
  end

  def initialize (interface, implementations)
    @implementations = (implementations or []).collect {|impl| Implementation.new(interface, impl)}
  end

  def self.all
    all_implementations = []
    ResourceRegistration.resources.sort.each do |interface,implementations|
      all_implementations += implementations.collect {|impl| Implementation.new(interface, impl)}
    end
    all_resources = new(nil,[])
    all_resources.implementations = all_implementations
    all_resources
  end

  def self.find(interface)
    implementations = ResourceRegistration.resources[interface] or []
    new(interface, implementations)
  end

  def to_xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.resources(:type => :array) do
      @implementations.each do |implementation|
        implementation.to_xml(xml)
      end
    end
  end

  def to_json( options = {} )
    Hash.from_xml(to_xml).to_json
  end

end
