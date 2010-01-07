module BaseModel
  module Serialization
    # Helper class for serializer implementation.
    #
    # Inspired by ActiveRecord Serializer
    class Serializer
      #passed options to serializer
      attr_reader :options
      #attributes to serialize
      attr_reader :attributes

      # initialize serializer
      # 
      # model:: model to serialize
      # options:: generic options for serializer, not used now
      def initialize(model,options={})
        @model = model
        @options = options
        @attributes = model.class.serialized_attributes
        unless @attributes
          @attributes = model.instance_variables.collect { |v| v.to_sym }
        end
      end

      #to overwrite
      def serialize
      end
    end

    module ClassMethods
      # defines attributes which should be serialized
      # usage (class with two attributes to serialize):
      #   class Test
      #     include Serialization
      #     attr_serialized :arg1
      #     attr_serialized :arg2
      #   end
      def attr_serialized(*args)
        @attr_serialized ||= []
        @attr_serialized.concat args.collect { |v| "@#{v.to_s}".to_sym }
      end

      # Gets attributes which should be serialized, containing @ at beggining
      # so result from attr_serialized example is:
      #   [ :'@arg1', :'arg2' ]
      def serialized_attributes
        @attr_serialized
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

  end
end

#FIXME Strange, in some case (use server instead of console and load from remote service) require doesn't work
# it looks like it create problematic dependency load and doesn't add to_xml method, change to load help
load 'base_model/serializers/json_serializer.rb'
load 'base_model/serializers/xml_serializer.rb'
