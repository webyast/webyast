class Carrier < ActiveRecord::Base
  has_many :phone_numbers
end



class StaticCarrier < ActiveRecord::Base
  set_table_name 'carriers'
  acts_as_static_record
  has_many :phone_numbers, :foreign_key => :carrier_id
end


class StaticCarrierWithKey < ActiveRecord::Base
  set_table_name 'carriers'
  acts_as_static_record :key => :name
  has_many :phone_numbers, :foreign_key => :carrier_id
end

class StaticCarrierWithNonColumnKey < ActiveRecord::Base
  set_table_name 'carriers'
  acts_as_static_record :key => :non_column
  has_many :phone_numbers, :foreign_key => :carrier_id

  def non_column
    "NONCOLUMN: " + self.to_param.to_s
  end
end