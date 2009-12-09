module BaseModel
  module MassAssignment
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
      def attr_accessible ( *args )
        @attr_accessible ||= []
        @attr_accessible.concat args
      end

      def accessible_attributes
        @attr_accessible
      end

      def attr_protected ( *args )
        @attr_protected ||= []
        @attr_protected.concat args
      end

      def protected_attributes
        @attr_protected
      end
    end
  end
end
