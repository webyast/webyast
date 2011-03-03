class PhoneNumber < ActiveRecord::Base
  belongs_to :carrier
  belongs_to :context_carrier, :class_name => 'ContextCarrier', :foreign_key => :carrier_id
  belongs_to :static_carrier, :class_name => 'StaticCarrier', :foreign_key => :carrier_id
end