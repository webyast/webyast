require File.dirname(__FILE__) + '/test_helper'

class StaticActiveRecordContextTest < TestCaseSuperClass
  self.fixtures :carriers, :phone_numbers


  def setup
    super
    StaticCarrierWithKey.clear_static_record_cache
    StaticCarrier.clear_static_record_cache
    StaticCarrierWithNonColumnKey.clear_static_record_cache
  end
  
  def test_should_load_all_records
    StaticCarrier.find :all
    assert_equal Carrier.count, cache_instance(StaticCarrier)[:primary_key].size
  end

  def test_should_load_all_records_with_key
    StaticCarrierWithKey.find :all
    assert_equal Carrier.count, cache_instance(StaticCarrierWithKey)[:primary_key].size
    assert_equal Carrier.count, cache_instance(StaticCarrierWithKey)[:key].size

    #cached on key
    cache_instance(StaticCarrierWithKey)[:key].each {|cache_key, cache_item|
      assert(cache_key, cache_item.name)
    }
  end

  def test_should_load_all_records_with_non_column_key
    StaticCarrierWithNonColumnKey.find :all
    assert_equal Carrier.count, cache_instance(StaticCarrierWithNonColumnKey)[:primary_key].size
    assert_equal Carrier.count, cache_instance(StaticCarrierWithNonColumnKey)[:key].size

    #cached on key
    cache_instance(StaticCarrierWithNonColumnKey)[:key].each {|cache_key, cache_item|
      assert(cache_key, cache_item.non_column)
    }
  end

  def test_should_not_load_cache_with_conditions
    StaticCarrier.find :all, :conditions => 'id is not null'
    assert_nil cache_instance(StaticCarrier)
  end

  def test_should_load_all_when_accessing_one_record
    phone = phone_numbers(:phone_number_1)
    phone.static_carrier
    phone.reload
    assert_queries(0){
     phone.static_carrier
    }
    assert_equal Carrier.count, cache_instance(StaticCarrier)[:primary_key].size
    assert_equal 0, cache_instance(StaticCarrier)[:key].size
  end

  def test_should_define_method_for_non_column_key
    assert StaticCarrierWithNonColumnKey.respond_to?(:find_by_non_column)

    record = StaticCarrierWithNonColumnKey.find_by_non_column('NONCOLUMN: 1')
    assert(1, record.to_param)
  end


  def test_finders_for_column_key

    assert_queries(1) {
      record = StaticCarrierWithKey.find_by_name_and_id('Verizon', 1)
      assert(record)
      assert_equal('Verizon', record.name)
      assert_equal("1", record.to_param)

      record = StaticCarrierWithKey.find_by_name_and_id('Verizon', 2)
      assert_nil(record)
    }
  end

  def test_finders_for_primary_key_id

    StaticCarrierWithKey.find :all
    assert_queries(0) {
      record = StaticCarrierWithKey.find_by_id(1)
      assert(record)
      assert_equal('Verizon', record.name)
      assert_equal("1", record.to_param)
    }
    
    assert_queries(1) {
      record = StaticCarrierWithKey.find_by_id(2, :conditions => 'id = 1')
      assert_nil(record)
    }
  end

  def test_finders_for_column_key_base

    StaticCarrierWithKey.find :all
    assert_queries(0) {
      record = StaticCarrierWithKey.find_by_name('Verizon')
      assert(record)
      assert_equal('Verizon', record.name)
      assert_equal("1", record.to_param)
    }
    assert_queries(1) {
      record = StaticCarrierWithKey.find_by_name('Verizondd', :conditions => 'id is not null')
      assert_nil(record)
    }
  end


  def test_finders_for_column_key_with_conditions
    #load up the cache
    StaticCarrierWithKey.find :all
    
    assert_queries(1) {
      #This performs one query because the conditions are not nil
      record = StaticCarrierWithKey.find_by_name_and_id('Verizon', 1, :conditions => 'id is not null')
      assert(record)
      assert_equal('Verizon', record.name)
      assert_equal("1", record.to_param)

      #This should use the cache
      record = StaticCarrierWithKey.find_by_name_and_id('Verizon', 1)
      assert(record)
      assert_equal('Verizon', record.name)
      assert_equal("1", record.to_param)
    }
    
    #This should use the newly defined method and run it since there are conditions
    assert_queries(1) {
      #This performs one query because the conditions are not nil
      record = StaticCarrierWithKey.find_by_name_and_id('Verizon', 1, :conditions => 'id is not null')
      assert(record)
      assert_equal('Verizon', record.name)
      assert_equal("1", record.to_param)
    }
  end


  protected

  #calling static_record_cache invokes the cache
  def cache_instance(klass)
    klass.instance_variable_get('@static_record_cache')
  end

end
