#
# Resource class
#

class Resource
  require 'resource_registration'
  attr_accessor :implementations, :interface

  class Implementation
    attr_accessor :controller, :interface

    def initialize(interface, impl_hash)
      @interface = interface
      @policy    = impl_hash[:policy]
      @singular  = impl_hash[:singular]
      @controller= impl_hash[:controller]
    end

    def link_to
      "/#{@controller}"
      #               url_for :only_path => :true,
      #                       :controller => @controller,
      #                       :action => (@singular ? :show : :index)
    end

    def action
      @singular ? :show : :index
    end

    def to_xml( options = {} )
      xml = options[:builder] ||= Builder::XmlMarkup.new(options)
      xml.instruct! unless options[:skip_instruct]
      xml.implementation do
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
    @interface = interface
    @implementations = (implementations or []).collect {|impl| Implementation.new(interface, impl)}
  end

  def self.all
    resources = ResourceRegistration.resources.sort.collect {|interface,implementations| new(interface,implementations)}
    Resources.new resources
  end

  def self.find(interface)
    implementations = ResourceRegistration.resources[interface] or []
    new(interface, implementations)
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.resource do
      xml.interface(@interface)
      xml.implementations(:type => :array) do
        @implementations.each do |implementation|
          implementation.to_xml(:builder => xml, :skip_instruct => true)
        end
      end
    end
  end

  def to_json( options = {} )
    Hash.from_xml(to_xml).to_json
  end
end

class Resources < Array
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.resources(:type => :array) do
      each {|resource| resource.to_xml(:builder => xml, :skip_instruct => true)}
    end
  end

  def to_json
    Hash.from_xml(to_xml).to_json
  end
end
