require 'active_support/json'
module BaseModel
  module Serialization
    def to_json(options={},&block)
      super
    end

    def from_json(json)
      hash = ActiveSupport::JSON.decode(json)
      load(hash.values.first)
    end

    def as_json(options={})
      hash = {}
      Serializer.new(self,options).attributes.each do |attr|
        hash[attr.to_s[1..-1]] = instance_variable_get(attr)
      end
      hash = { self.class.model_name.singular => hash }
      hash
    end

  end
end
