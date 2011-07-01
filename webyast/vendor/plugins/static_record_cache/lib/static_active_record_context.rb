# ==StaticActiveRecordContext
# Simple module to extends technoweenie's rad ActiveRecordContext plugin
# http://svn.techno-weenie.net/projects/plugins/active_record_context/
# to permanently cache active record data for the life of the class
#
# As with active_record_context, only finds based on ids are cache hits, however
# id finders are the majority of calls from associations. If cache hits on
# fields and methods are needed, refer to acts_as_static_record[link:files/acts_as_static_record_rb.html]
#
#  class TelephoneCarriers < ActiveRecord::Base
#    extend StaticActiveRecordContext
#    has_many :phone_numbers
#  end
#  
# The following would exercise a cache hit
#  phone_number.telephone_carrier
#
#
# The static cache is available both inside and outside +with_context+ block, where as
# the cache for typical records the context is only with the block.
#
#  PhoneNumber.with_context {
#    PhoneNumber.find :all
#    TelephoneCarriers.find :all
#  }
#
#  phone = PhoneNumber.find_by_id(1)             # not a cache hit
#  phone.telephone_carrier                       # cache hit
#  telephone_carrier = TelephoneCarrier.find(1)  # cache hit
#
# === Developers
# * Blythe Dunham http://snowgiraffe.com
#
# === Homepage
# * Rdoc: http://snowgiraffe.com/rdocs/static_record_cache/
# * Github Project: http://github.com/blythedunham/static_record_cache/tree/master
# * Install:  <tt>script/plugin install git://github.com/blythedunham/static_record_cache.git</tt>
module StaticActiveRecordContext
  def self.extended(base)#:nodoc
    base.class_inheritable_accessor :static_record_context
  end

  def context_cache#:nodoc:
    self.static_record_context ||= {}
  end

  def context_cache=(map)#:nodoc:
    self.static_record_context = map unless map.nil?
  end

  # Reload the cache for this class only
  def reload_context_cache
    self.static_record_context = {}
  end

  # Call ActiveRecord::Base to cache the other objects
  def with_context(&block)#:nodoc:
    ActiveRecord::Base.with_context(&block)
  end
end
