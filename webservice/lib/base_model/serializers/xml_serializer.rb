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
            builder.tag!(attr.to_s[1..-1],@model.instance_variable_get(attr))
          end
        }
      end
    end
  end
end
