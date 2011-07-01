class ContextCarrier < ActiveRecord::Base
  set_table_name 'carriers'
  extend StaticActiveRecordContext
  has_many :phone_numbers, :foreign_key => :carrier_id
end
