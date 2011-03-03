require File.dirname(__FILE__) + '/test_helper'

class StaticActiveRecordContextTest < TestCaseSuperClass
  self.fixtures :carriers, :phone_numbers
  

  def test_should_store_one_record
    ContextCarrier.context_cache = {}
    phone = phone_numbers(:phone_number_1)
    phone.context_carrier
    phone.reload
    phone.context_carrier

    assert_equal 1, ContextCarrier.context_cache[ContextCarrier].size
    assert_equal(carriers(:carrier_1).attributes, ContextCarrier.cached[phone.carrier.id].attributes)
  end

  def test_should_store_all_records_in_cache
    ContextCarrier.context_cache = {}
    
    records = ContextCarrier.find(:all)
    assert_equal 13, ContextCarrier.context_cache[ContextCarrier].size

    records.each{ |record|
      carrier = carriers("carrier_#{record.to_param}")
      assert_equal carrier.attributes, ContextCarrier.cached[carrier.id].attributes
    }
  end

  def test_should_retain_cache_after_other_record_context
    PhoneNumber.with_context do
      PhoneNumber.find(:all)
      assert_equal PhoneNumber.count, PhoneNumber.context_cache[PhoneNumber].size
      ContextCarrier.find(:all)
      assert_equal ContextCarrier.count, ContextCarrier.context_cache[ContextCarrier].size
    end

    assert_nil PhoneNumber.context_cache
    assert_equal ContextCarrier.count, ContextCarrier.context_cache[ContextCarrier].size
  end

  def test_should_retain_cache_after_same_record_context
    ContextCarrier.with_context do
      PhoneNumber.find(:all)
      assert_equal PhoneNumber.count, PhoneNumber.context_cache[PhoneNumber].size
      ContextCarrier.find(:all)
      assert_equal ContextCarrier.count, ContextCarrier.context_cache[ContextCarrier].size
    end

    assert_nil PhoneNumber.context_cache
    assert_equal ContextCarrier.count, ContextCarrier.context_cache[ContextCarrier].size
  end

end
