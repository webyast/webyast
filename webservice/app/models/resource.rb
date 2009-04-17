class Resource < ActiveRecord::Base
  acts_as_taggable
  belongs_to :domain
  def to_s
    name
  end
end
