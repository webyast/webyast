class Resource < ActiveRecord::Base
  belongs_to :domain
  def to_s
    name
  end
end
