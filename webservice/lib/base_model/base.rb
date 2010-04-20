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
  # === Validation
  # It is used validation from ActiveRecord. For details see ActiveRecord::Validations
  # 
  # Not all validation is usable in all models. Basic supported ones is:
  # * validates_presence_of
  # * validates_format_of
  # * validates_inclusion_of
  # * validates_exclusion_of
  # * validates_range_of
  # * validates_lenght_of
  # * validates_numberically_of
  # * validates_each (general validation)
  # * validates_numberically_of
  # see ActiveRecord::Validations::ClassMethods documentation for arguments
  #
  # === Callbacks
  # It is used to add hook to actions from ActiveRecord. For details see ActiveRecord::Callbacks
  # Supported callbacks (all have before and after variant also):
  # * around_create
  # * around_destroy
  # * around_save
  # * around_update
  # * around_validation
  # * around_validation_on_create
  # * around_validation_on_update
  # * general around_filter
  # see ActiveRecord::Callbacks documentation for arguments
  # 
  # === Mass assignment
  # see BaseModel::MassAssignment
  #
  # === Serialization
  # Framework to support serialization. By default is support xml and json serialization (method to_xml and to_json)
  # and deserialization (from_xml and from_json).
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


    # requirement for class which should be used in ActiveModel
    # see http://www.engineyard.com/blog/2009/my-five-favorite-things-about-rails-3/ (paragraph 4)
    def to_model
      self
    end

    # initialize attributes by hash in attr
    def initialize(attr={})
      load(attr)
    end

    # saves result
    # if fails sets error
    # see ActiveRecord::Base#save or ActiveResource::Base#save
    # Do not overwritte it, overwrite instead create or update
    def save
      create_or_update
    end

    # same as save but throws exception if error occur
    # see save
    def save!
      create_or_save || raise("Internal error: Should be redefined")
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

    #remove overwritten method_missing from activeRecord (as Base model doesn't know attributes)
    alias_method :method_missing_orig, :method_missing
    #required by validations
    include ActiveRecord::AttributeMethods
    alias_method :method_missing, :method_missing_orig
    #remove overwritten respond_to (as Base model doesn't have attributes
    alias_method :respond_to?, :respond_to_without_attributes?

    #Validations in model
    include ActiveRecord::Validations
    
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

    #Callbacks in model
    include ActiveRecord::Callbacks


    #Mass assignment support
    include BaseModel::MassAssignment
    #serialization of models
    include BaseModel::Serialization

    #here is redefined save! from ActiveRecord, as we want to throw own exceptions
    def save!
      unless valid?
        report = {}
        errors.each { |attr,msg| report[attr.to_sym] = msg }
        raise InvalidParameters.new report
      end
      save
    end
  end
end
#Hack to properly generate error message without ActiveRecord special methods
module ActiveRecord
  class Error
    # do not call any record specific methods
    def generate_message(*args)
      @message
    end

    # do not call any record specific methods
    def generate_full_message(*args)
      @message
    end

    # do not call any record specific methods
    def default_options
      {}
    end
  end
end
