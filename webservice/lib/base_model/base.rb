module BaseModel
  class Base

    def to_model
      self
    end

    def initialize(attr={})
      load(attr)
    end

    def save
      create_or_update
    end

    def save!
      create_or_update
      #TODO raise exception
    end

    def new_record?
      false #always update by default
    end

    def create_or_update
      (new_record? ? create : update) != false
    end

    def create
      true
    end

    def update
      true
    end

    def destroy
    end

#remove overwritten method_missing from activeRecord
    alias :method_missing_orig :method_missing
    include ActiveRecord::AttributeMethods
    alias :method_missing :method_missing_orig
#remove overwritten respond_to
    alias :respond_to? :respond_to_without_attributes?

    include ActiveRecord::Validations
    include ActiveRecord::Callbacks


    include BaseModel::MassAssignment
    include BaseModel::Serialization

    include YastRoles #to access permission check in models

  end
end
