class Domain < ActiveRecord::Base
  has_many :resources
  def to_s
    name
  end
end
