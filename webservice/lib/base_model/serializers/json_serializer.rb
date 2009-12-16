require 'active_support/json'
module BaseModel
  module Serialization
    # serializes model to json
    # as root element uses singular model name
    def to_json(options={},&block)
      super
    end

    # restore model from json
    def from_json(json)
      hash = ActiveSupport::JSON.decode(json)
      load(hash.values.first)
    end

private
    def as_json(options={})
      hash = {}
      Serializer.new(self,options).attributes.each do |attr|
        val = instance_variable_get(attr)
        hash[attr.to_s[1..-1]] = val unless val.nil? #remove nil values
      end
      hash = { self.class.model_name.singular => hash }
      hash
    end

  end
end
