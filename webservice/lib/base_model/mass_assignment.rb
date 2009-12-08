module BaseModel
  module MassAssignment
    def load(attributes)
      attributes.each do |k,v|
        instance_variable_set ( "@#{k.to_s}",v )
      end
    end
  end
end
