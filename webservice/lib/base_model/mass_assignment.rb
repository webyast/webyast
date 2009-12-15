module BaseModel
  # == Mass Assignment module
  # Adds ability to load instance variables from hash
  # It allow whitelisting and blacklisting variables which should not be
  # overwritten. It respect common behavior in ActiveResource and ActiveRecord.
  # For mass loading see ActiveResource::Base#load
  # For whitelisting details see ActiveRecord::Base.attr_accessible
  # For blacklisting details see ActiveRecord::Base.attr_protected
  #
  # Example:
  #   class C
  #     include BaseModel::MassAssignment
  #
  #     attr_accessor :attr1, attr2, :internal
  #
  #     attr_protected :internal
  #
  #     def instantiate(attr={})
  #         load attr
  #     end
  #   end
  module MassAssignment
    # loads hash to instance variables, where keys is names of variables and 
    # hash value is variables values
    # it has same behavior as ActiveResource::Base#load
    def load(attributes)
      attributes.each do |k,v|
        whitelist = self.class.accessible_attributes
        next if whitelist && !(whitelist.include?(k.to_sym))
        blacklist = self.class.protected_attributes
        next if blacklist && blacklist.include?(k.to_sym)
        instance_variable_set("@#{k.to_s}",v)
      end
    end

    def self.included(base)
      base.send(:extend,ClassMethods)
    end

    module ClassMethods

      # Defines attributes which should be loaded by mass assignment.
      # By default is used all attributes
      # For disable using loading non-whitelisted attributes use
      # without parameters
      # param args is variable number of symbols which identify variables
      def attr_accessible ( *args )
        @attr_accessible ||= []
        @attr_accessible.concat args
      end

      # Gets list of allowed attributes. If result is nil, then is allowed is
      # all attributes which is not protected.
      def accessible_attributes
        @attr_accessible
      end

      # Defines attributes which cannot be loaded by mass assignment.
      # By default all attributes is not protected.
      # Note only used if whitelist is not specified by attr_accessible
      # param args is variable number of symbols which identify variables
      def attr_protected ( *args )
        @attr_protected ||= []
        @attr_protected.concat args
      end

      # Gets list of protected attributes. If result is nil, then no attributes is protected.
      def protected_attributes
        @attr_protected
      end
    end
  end
end
