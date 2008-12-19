class User < ActiveRecord::Base
  has_many :permissions
end
