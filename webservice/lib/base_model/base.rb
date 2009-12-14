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
  # TODO add example

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
      create_or_update
      #TODO raise exception
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
    alias :method_missing_orig :method_missing
    #required by validations
    include ActiveRecord::AttributeMethods
    alias :method_missing :method_missing_orig
#remove overwritten respond_to (as Base model doesn't have attributes
    alias :respond_to? :respond_to_without_attributes?

    #Validations in model
    include ActiveRecord::Validations
    #Callbacks in model
    include ActiveRecord::Callbacks


    #Mass assignment support
    include BaseModel::MassAssignment
    #serialization of models
    include BaseModel::Serialization
  end
end
