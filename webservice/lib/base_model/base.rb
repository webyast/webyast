module BaseModel
  class Base

    def save
      create_or_update
    end

    def save!
      create_or_update
      #TODO raise exception
    end

    def new_record?
      true
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

    include BaseModel::MassAssignment
    include ActiveRecord::AttributeMethods
    include ActiveRecord::Validations
    include ActiveRecord::Callbacks
  end
end
