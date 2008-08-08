class Services < ActiveRecord::Base
  has_many :commands
  has_many :confs
end
