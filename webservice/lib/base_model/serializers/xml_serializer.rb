module BaseModel
  module Serialization
    def to_xml(options={},&block)
      options[:attributes] = self.class.serialized_attributes
      serializer = XmlSerializer.new(self,options)
      block_given? ? serializer.serialize(&block) : serializer.serialize
    end

    def from_xml(xml)
      load(Hash.from_xml(xml).values.first)
      self
    end

    class XmlSerializer < BaseModel::Serialization::Serializer
      def serialize
        root = options[:root] || @model.class.model_name.singular
        builder = options[:builder] || Builder::XmlMarkup.new(options)
        builder.tag!(root){
          @attributes.each do |attr|
            value = @model.instance_variable_get(attr)
            name = attr.to_s[1..-1]
            serialize_value(name,value,builder)
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
        else
          builder.tag!(name,value.to_s)
        end
      end
    end
  end
end
