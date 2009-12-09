module BaseModel
  module Serialization
    class Serializer
      attr_reader :options, :attributes

      def initialize(model,options={})
        @model = model
        @options = options
        @attributes = options[:attributes]
        unless @attributes
          @attributes = model.instance_variables.collect { |v| v.to_sym }
        end
      end

      #to overwrite
      def serialize
      end
    end

    module ClassMethods
      def attr_serialized(*args)
        @attr_serialized ||= []
        @attr_serialized.concat args
      end

      def serialized_attributes
        @attr_serialized
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

  end
end
require 'base_model/serializers/xml_serializer'
require 'base_model/serializers/json_serializer'
