#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

module BaseModel
  # == Base
  # Shared ancestor for models that want to act similar as ActiveResource or ActiveRecord model.
  #
  # Inspired by ActiveModel from rails3.0
  # Supported features
  # * Validation
  # * Callbacks
  # * Mass assignment
  # * Serialization
  #
  # 
  # === Example
  #   class Systemtime < BaseModel::Base
  #
  #     # Date settings format is dd/mm/yyyy
  #     attr_accessor :date
  #     validates_format_of :date, :with => /^\d{2}\/\d{2}\/\d{4}$/, :allow_nil => true
  #     # time settings format is hh:mm:ss
  #     attr_accessor :time
  #     validates_format_of :time, :with => /^\d{2}:\d{2}:\d{2}$/, :allow_nil => true
  #     # Current timezone as id
  #     attr_accessor :timezone
  #     #check if zone exists
  #     validates_each :timezone, :allow_nil => true do |model,attr,zone|
  #       contain = false
  #       unless model.timezones.nil?
  #         model.timezones.each do |z|
  #           contain = true if z["entries"][zone]
  #         end
  #         model.errors.add attr, "Unknown timezone" unless contain
  #       end
  #     end
  #     # Utc status possible values is UTCOnly, UTC and localtime see yast2-country doc
  #     attr_accessor :utcstatus
  #     validates_inclusion_of :utcstatus, :in => [true,false], :allow_nil => true
  #     attr_accessor :timezones
  #     validates_presence_of :timezones
  #     # do not massload timezones, as it is read-only
  #     attr_protected :timezones
  #
  #     after_save :restart_collectd
  #     # to_xml and to_json is automatic provided
  #     # load and new(options) is also automatic provided
  #   end  


  class Base 
    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend  ActiveModel::Naming
    extend  ActiveModel::Callbacks

    # initialize attributes by hash in attr
    def initialize(attr={})
      assign_attributes(attr)
    end

    # for mass assignment
    def assign_attributes(values, options = {})
      values.each do |k, v|
        whitelist = self.class.accessible_attributes
        next if !whitelist.blank? && !(whitelist.include?(k.to_sym))
        blacklist = self.class.protected_attributes
        next if !blacklist.blank? && blacklist.include?(k.to_sym)
        send("#{k}=", v) if self.respond_to?(k)
      end
    end

    #for serialization
    def attributes
      ret = {}
      attr_list = @attr_serialized || self.instance_variables.collect { |v| v.to_sym }
      attr_list.each do |attr|
        value = self.instance_variable_get(attr)
        name = attr.to_s[1..-1]
        ret[name] = value unless value == nil
      end
      ret
    end

    # requirement for class which should be used in ActiveModel
    # see http://www.engineyard.com/blog/2009/my-five-favorite-things-about-rails-3/ (paragraph 4)
    def to_model
      self
    end

    def persisted?
      false
    end

    # saves result
    # if fails sets error
    # see ActiveRecord::Base#save or ActiveResource::Base#save
    # Do not overwritte it, overwrite instead create or update
    def save
      create_or_update
    end

    # Initial fake implementation which allows ActiveRecord::Validation to alias it, but we use our own version defined below.
    # see save
    def save!
      raise("Internal error: Save! is only to allow alias of activeRecord in validations, but we redefine it so
          this implementation should not be ever called")
    end


    # identification if create new source or update already existing one
    # by default return false ( always update )
    def new_record?
      false #always update by default
    end

    # Creates or updates source depending on result of new_record?
    # Use method save unless you really know what you are doing.
    def create_or_update
      (new_record? ? create : update) != false
    end

    # Creates new source.
    # By default do nothing.
    # Overwrite only if you overwrite also new_record? otherwise it is never call
    # If problem occur returns false and must properly set Error structure see ActiveRecord::Error
    def create
      true
    end

    # Updates source.
    # By default do nothing.
    # Overwrite it if model is not read-only
    # If problem occur returns false and must properly set Error structure see ActiveRecord::Error
    def update
      true
    end

    # destroys source.
    # By default do nothing.
    # Overwrite it if model is not read-only
    # If problem occur returns false and must properly set Error structure see ActiveRecord::Error
    def destroy
      true
    end

    # This is redefined save! from ActiveRecord, as we want to throw own exceptions
    # throws InvalidParameters exception when validation failed. Return same value as return save.
    # if exception is not raised it is correctly reported to webclient as failed validation see ActiveResource#validations
    def save!
      unless valid?
        report = {}
        errors.each { |attr,msg| report[attr.to_sym] = msg }
        raise InvalidParameters.new report
      end
      save
    end

    # defines attributes which should be serialized
    # usage (class with two attributes to serialize):
    #   class Test
    #     include Serialization
    #     attr_serialized :arg1
    #     attr_serialized :arg2
    #   end
    def self.attr_serialized(*args)
      @attr_serialized ||= []
      @attr_serialized.concat args.collect { |v| "@#{v.to_s}".to_sym }
    end

    #extend validation with site validation

    # validates that in attributes is set valid URI
    def self.validates_uri(*attr_names)
      configuration = {}
      configuration.update attr_names.extract_options!

      validates_each(attr_names,configuration) do |record,attr_name,value|
        begin
          URI.parse value
        rescue URI::InvalidURIError => e
          Rails.logger.warn "Invalid URI: #{e.inspect}"
          record.errors.add(attr_name, :invalid, :default => configuration[:message], :value => value)
        end
      end
    end

  end
end
