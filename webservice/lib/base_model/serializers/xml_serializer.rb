module BaseModel
  module Serialization
    # Serializes model to XML
    #
    # +WARNING+:: keys from hash is get to tags unescaped, so don't use hash with keys which can break XML tag (this behavior might change in future)
    # options:: recognizes common Builder::XmlMarkup options (if root is not given, it uses singular of model name )
    # block:: not used now
    def to_xml(options={:indent => 2},&block)
      serializer = XmlSerializer.new(self,options)
      block_given? ? serializer.serialize(&block) : serializer.serialize
    end

    # loads model from xml
    def from_xml(xml)
      load(Hash.from_xml(xml).values.first)
      self
    end

    class XmlSerializer < BaseModel::Serialization::Serializer
      def serialize
        root = options[:root] || @model.class.model_name.singular
        builder = options[:builder] || Builder::XmlMarkup.new(options)
        builder.instruct! unless options[:skip_instruct]
        builder.tag!(root){
          @attributes.each do |attr|
            value = @model.instance_variable_get(attr)
            name = attr.to_s[1..-1]
            serialize_value(name,value,builder) unless value.nil?
          end
        }
      end

      protected
      #place for all types for special serializing
      def serialize_value(name,value,builder)
        if value.is_a? Array
          builder.tag!(name,{:type => "array"}) do
            value.each do |v|
              serialize_value(name,v,builder)
            end
          end
        elsif value.is_a? Hash
        builder.tag!(name) do
            value.each do |k,v|
              serialize_value(k,v,builder)
            end
          end
        elsif value.respond_to? :to_xml #value has own serialization method
          value.to_xml :root => name, :skip_instruct => true, :builder => builder
        else
          type = XML_TYPE_NAMES[value.class.to_s]
          opts = {}
          opts[:type] = type if type
          #NOTE: can be optimalized for primitive types like boolean or numbers to avoid XML escaping
          builder.tag!(name,value.to_s,opts)
        end
      end

      XML_TYPE_NAMES = { #type conversion
          "Symbol"     => "symbol",
          "Fixnum"     => "integer",
          "Bignum"     => "integer",
          "BigDecimal" => "decimal",
          "Float"      => "float",
          "TrueClass"  => "boolean",
          "FalseClass" => "boolean",
          "Date"       => "date",
          "DateTime"   => "datetime",
          "Time"       => "datetime",
          "ActiveSupport::TimeWithZone" => "datetime"
        } unless defined?(XML_TYPE_NAMES)

    end
  end
end
