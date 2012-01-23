# =acts_as_static_record
# Permanently caches subclasses of ActiveRecord that contains data that changes rarely.
#
# Includes support for:
# * Find by Id, all, first (association lookups)
# * Cached caluculations: <tt>Neighborhood.count</tt>s, sum, max, min
# * Convenience lookups: <tt>Neighborhood[:seattle]</tt>
# * Additional support for column name lookups: <tt>Neighborhood.find_by_name 'Seattle'</tt>
#
# == Install
#   script/plugin install git://github.com/blythedunham/static_record_cache.git
#
# == Usage
#   class SomeMostlyStaticClass < ActiveRecord::Base
#     acts_as_static_record
#   end
#
# Any finds that do not contain additional conditions, joins, and other arguments
# become a cache call. One advantage over the query cache is that the static cache is searched
# eliminating the need for  +ActiveRecord+ to generate SQL
#
# When a cache key is specified with option <tt>:key</tt>, additional
# finder methods for ids and fields such as +find_by_id+ and +find_by_name_and_mother+
# are overwritten to search the cache when no arguments (conditions) are specified.
# If the cache key is not a column, then a finder method will be defined.
#   acts_as_static_record :key => :some_instance_method
# Will define <tt>find_by_some_instance_method(value)</tt>
#
# === Options
# * <tt>:key</tt> - a method or column of the instance used to specify a cache key. This should be unique.
# * <tt>:find</tt> an additional find scope to specify <tt>:conditions</tt>,<tt>:joins</tt>, <tt>:select</tt>, <tt>:joins</ff> etc
# * <tt>:find_by_attribute_support</tt> - set to true to add additional functionality for finders such as +find_by_id_and_name+ to use a cache search. This option is probably best for Rails 2.3
# * <tt>:lookup_key</tt> - access the record from the class by a key name like <tt>User[:snowgiraffe]</tt>. <tt>:lookup_key</tt> is the column on which do do the lookup.
#
# === Examples
# Caches on Id and telephone carrier name
#  class TelephoneCarrier < ActiveRecord::Base
#    acts_as_static_method :key => :name
#  end
#
# Caches the WhiteList on phone_number_digits (in addition to ID)
#  create_table :sms_white_list, :force => true do |t|
#    t.column :phone_number_id, :integer, :null => false
#    t.column :notes, :string, :length => 100, :default => nil
#  end
#
#  class SmsWhiteList < ActiveRecord::Base
#    belongs_to :phone_number
#
#    acts_as_static_record :key => :phone_number_digits,
#               :find => :select => 'carriers.*, phone_number.number as phone_number_digits'
#                        :joins => 'inner join phone_numbers on phone_numbers.carrier_id = carriers.id'
#
#    def phone_number_digits
#      self['phone_number_digits']||self.phone_number.number
#    end
#  end
#
# Direct cache hits
#  SmsWhiteList.find_by_phone_number_digits('12065551234')
#  SmsWhiteList.find_by_id(5)
#  SmsWhiteList.find :all
#
# Searched cache hits
#  SmsWhiteList.find_by_notes('Some note')
#
# ==Calculation Support
# Now with +calculate+ support for +sum+, +min+, and +max+ for integer columns and +count+ for all columns
# Cache hits do not occur if options other than +distinct+ are used.
#
# Cache hits:
#  Neighborhood.count
#  Neighborhood.count :name, :distinct => true
#  Neighborhood.sum :id
#  Neighborhood.max :id
# Not cache hits:
#  Neighborhood.max :name
#  Neighborhood.count :zip_code, :conditions => ['name = ?', 'Seattle']
#
# ==Convenience lookup
# Similar to acts_as_enumeration model returns the record where the
# <tt>acts_as_static_record :key</tt> option matches +lookup+
# If no key is specified, the primary_id column is used
#
#   class User < ActiveRecord::Base
#     acts_as_static_record :key => :user_name
#   end
#
# Then later we can reference the objects by the user_name
#   User[:blythe]
#   User['snowgiraffe']
#
# The key used will be the underscore version of the name. Punctuation marks
# are removed. The following are equivalent:
#  User[:blythe_snowgiraffeawesome]
#  User['blythe-SNOWGIRaffe   AWESome']
#
#  user = User.first
#  User[user.user_name] == user
#
# === Developers
# * Blythe Dunham http://snowgiraffe.com
#
# === Homepage
# * Github Project: http://github.com/blythedunham/static_record_cache/tree/master
# * Install:  <tt>script/plugin install git://github.com/blythedunham/static_record_cache.git</tt>
module ActsAsStaticRecord
  def self.extended(base)
    base.send :class_attribute, :acts_as_static_record_options
    base.acts_as_static_record_options = {}
    base.extend ClassMethods
  end

  module ClassMethods#:nodoc:
    # =acts_as_static_record
    # Permanently caches subclasses of ActiveRecord that contains data that changes rarely.
    #
    # Includes support for:
    # * Find by Id, all, first (association lookups)
    # * Cached caluculations: <tt>Neighborhood.count</tt>s, sum, max, min
    # * Convenience lookups: <tt>Neighborhood[:seattle]</tt>
    # * Additional support for column name lookups: <tt>Neighborhood.find_by_name 'Seattle'</tt>
    # 
    # == Install
    #   script/plugin install git://github.com/blythedunham/static_record_cache.git
    #
    # == Usage
    #   class SomeMostlyStaticClass < ActiveRecord::Base
    #     acts_as_static_record
    #   end
    #
    # Any finds that do not contain additional conditions, joins, and other arguments
    # become a cache call. One advantage over the query cache is that the static cache is searched
    # eliminating the need for  +ActiveRecord+ to generate SQL
    #
    # When a cache key is specified with option <tt>:key</tt>, additional
    # finder methods for ids and fields such as +find_by_id+ and +find_by_name_and_mother+
    # are overwritten to search the cache when no arguments (conditions) are specified.
    # If the cache key is not a column, then a finder method will be defined.
    #   acts_as_static_record :key => :some_instance_method
    # Will define <tt>find_by_some_instance_method(value)</tt>
    #
    # === Options
    # * <tt>:key</tt> - a method or column of the instance used to specify a cache key. This should be unique.
    # * <tt>:find</tt> an additional find scope to specify <tt>:conditions</tt>,<tt>:joins</tt>, <tt>:select</tt>, <tt>:joins</ff> etc
    # * <tt>:find_by_attribute_support</tt> - set to true to add additional functionality for finders such as +find_by_id_and_name+ to use a cache search. This option is probably best for Rails 2.3
    # * <tt>:lookup_key</tt> - access the record from the class by a key name like <tt>User[:snowgiraffe]</tt>. <tt>:lookup_key</tt> is the column on which do do the lookup.
    #
    # === Examples
    # Caches on Id and telephone carrier name
    #  class TelephoneCarrier < ActiveRecord::Base
    #    acts_as_static_method :key => :name
    #  end
    #
    # Caches the WhiteList on phone_number_digits (in addition to ID)
    #  create_table :sms_white_list, :force => true do |t|
    #    t.column :phone_number_id, :integer, :null => false
    #    t.column :notes, :string, :length => 100, :default => nil
    #  end
    #
    #  class SmsWhiteList < ActiveRecord::Base
    #    belongs_to :phone_number
    #
    #    acts_as_static_record :key => :phone_number_digits,
    #               :find => :select => 'carriers.*, phone_number.number as phone_number_digits'
    #                        :joins => 'inner join phone_numbers on phone_numbers.carrier_id = carriers.id'
    #
    #    def phone_number_digits
    #      self['phone_number_digits']||self.phone_number.number
    #    end
    #  end
    #
    # Direct cache hits
    #  SmsWhiteList.find_by_phone_number_digits('12065551234')
    #  SmsWhiteList.find_by_id(5)
    #  SmsWhiteList.find :all
    #
    # Searched cache hits
    #  SmsWhiteList.find_by_notes('Some note')
    #
    # ==Calculation Support
    # Now with +calculate+ support for +sum+, +min+, and +max+ for integer columns and +count+ for all columns
    # Cache hits do not occur if options other than +distinct+ are used.
    #
    # Cache hits:
    #  Neighborhood.count
    #  Neighborhood.count :name, :distinct => true
    #  Neighborhood.sum :id
    #  Neighborhood.max :id
    # Not cache hits:
    #  Neighborhood.max :name
    #  Neighborhood.count :zip_code, :conditions => ['name = ?', 'Seattle']
    #
    # ==Convenience lookup
    # Similar to acts_as_enumeration model returns the record where the
    # <tt>acts_as_static_record :key</tt> option matches +lookup+
    # If no key is specified, the primary_id column is used
    #
    #   class User < ActiveRecord::Base
    #     acts_as_static_record :key => :user_name
    #   end
    #
    # Then later we can reference the objects by the user_name
    #   User[:blythe]
    #   User['snowgiraffe']
    #
    # The key used will be the underscore version of the name. Punctuation marks
    # are removed. The following are equivalent:
    #  User[:blythe_snowgiraffeawesome]
    #  User['blythe-SNOWGIRaffe   AWESome']
    #
    #  user = User.first
    #  User[user.user_name] == user
    def acts_as_static_record(options={})

      acts_as_static_record_options.update(options) if options

      if acts_as_static_record_options[:find_by_attribute_support]
        extend ActsAsStaticRecord::DefineFinderMethods
      end

      extend  ActsAsStaticRecord::SingletonMethods
      include ActsAsStaticRecord::InstanceMethods

      unless respond_to?(:find_without_static_record)
        klass = class << self; self; end
        klass.class_eval "alias_method_chain :find, :static_record"
        klass.class_eval "alias_method_chain :calculate, :static_record"
      end

      define_static_cache_key_finder

      class_eval do
        before_save    {|record| record.class.clear_static_record_cache }
        before_destroy {|record| record.class.clear_static_record_cache }
      end
    end

    protected
    # Define a method find_by_KEY if the specified cache key
    # is not an active record column
    def define_static_cache_key_finder#:nodoc:
      return unless acts_as_static_record_options[:find_by_attribute_support]
      #define the key column if it is not a hash column
      if ((key_column = acts_as_static_record_options[:key]) &&
          (!column_methods_hash.include?(key_column.to_sym)))
        class_eval %{
          def self.find_by_#{key_column}(arg)
            self.static_record_cache[:key][arg.to_s]
          end
        }, __FILE__, __LINE__
      end
    end
  end

  module InstanceMethods
    
    # returns the lookup key for this record
    # For example if the defintion in +User+ was
    #   acts_as_static_record :key => :user_name
    #
    #  user.user_name
    #  => "Blythe Snow Giraffe"
    #
    #  user.static_record_lookup_key
    #  => 'blythe_snow_giraffe'
    #
    # which could then be used to access the record like
    #  User['snowgiraffe']
    #  => <User id: 15, user_name: "Blythe Snow Giraffe">
    #
    def static_record_lookup_key
      self.class.static_record_lookup_key(self)
    end
  end

  module SingletonMethods

    # Similar to acts_as_enumeration model returns the record where the
    # <tt>acts_as_static_record :key</tt> option matches +lookup+
    # If no key is specified, the primary_id column is used
    #
    #   class User < ActiveRecord::Base
    #     acts_as_static_record :key => :user_name
    #   end
    # Then later we can reference the objects by the user_name
    #   User[:blythe]
    #   User['snowgiraffe']
    #
    # The key used will be the underscore version of the name. Punctuation marks
    # are removed. The following are equivalent:
    #  User[:blythe_snowgiraffeawesome]
    #  User['blythe-SNOWGIRaffe   AWESome']
    #
    #  user = User.first
    #  User[user.user_name] == user
    def [](lookup_name)
      (static_record_cache[:lookup]||= begin

        static_record_cache[:primary_key].inject({}) do |lookup, (k,v)|

          lookup[v.static_record_lookup_key] = v
          lookup

        end
      end)[static_record_lookup_key(lookup_name)]

    end

    # Parse the lookup key
    def static_record_lookup_key(value)#:nodoc:
      if value.is_a? self
        static_record_lookup_key(
          value.send(
            acts_as_static_record_options[:lookup_key] ||
            acts_as_static_record_options[:key] ||
            primary_key
          )
        )
      else
        value.to_s.gsub(' ', '_').gsub(/\W/, "").underscore
      end
    end

    # Search the cache for records with the specified attributes
    #
    # * +finder+ - Same as with +find+ specify <tt>:all</tt>, <tt>:last</tt> or <tt>:first</tt>
    #   <tt>:all</all> returns an array of active records, <tt>:last</tt> or <tt>:first</tt> returns a single instance
    # * +attributes+ - a hash map of fields (or methods) => values
    #
    #   User.find_in_static_cache(:first, {:password => 'fun', :user_name => 'giraffe'})
    def find_in_static_record_cache(finder, attributes)#:nodoc:
      list = static_record_cache[:primary_key].values.inject([]) do |list, record|
        unless attributes.select{|k,v| record.send(k).to_s != v.to_s}.any?
          return record if finder == :first
          list << record
        end
        list
      end
      finder == :all ? list : list.last
    end

    # Perform find by searching through the static record cache
    # if only an id is specified
    def find_with_static_record(*args)#:nodoc:
      if scope(:find).nil? && args
        if args.first.is_a?(Fixnum) &&
            ((args.length == 1 ||
            (args[1].is_a?(Hash) && args[1].values.delete(nil).nil?)))
          return static_record_cache[:primary_key][args.first]
        elsif args.first == :all && args.length == 1
          return static_record_cache[:primary_key].values
        end
      end

      find_without_static_record(*args)
    end

    # Override calculate to compute data in memory if possible
    # Only processes results if there is no scope and the no keys other than distinct
    def calculate_with_static_record(operation, column_name, options={})#:nodoc:
      if scope(:find).nil? && !options.any?{ |k,v| k.to_s.downcase != 'distinct' }
        key = "#{operation}_#{column_name}_#{options.none?{|k,v| v.blank? }}"
        static_record_cache[:calc][key]||=
          case operation.to_s
          when 'count' then
              #count the cache if we want all or the unique primary key
              if ['all', '', '*', primary_key].include?(column_name.to_s)
                static_record_cache[:primary_key].length

              #otherwise compute the length of the output
              else
                static_records_for_calculation(column_name, options) {|records| records.length }
              end
          #compute the method directly on the result array
          when 'sum', 'max', 'min' then

              if columns_hash[column_name.to_s].try(:type) == :integer
                static_records_for_calculation(column_name, options) {|records| records.send(operation).to_i }
              end

          end

        return static_record_cache[:calc][key] if static_record_cache[:calc][key]

      end
      calculate_without_static_record(operation, column_name, options)
    end

    # Return the array of results to calculate if they are available
    def static_records_for_calculation(column_name, options={}, &block)#:nodoc:
      if columns_hash.has_key?(column_name.to_s)
        records = static_record_cache[:primary_key].values.collect(&(column_name.to_sym)).compact
        results = (options[:distinct]||options['distinct']) ? records.uniq : records
        block ? yield(results) : results
      else
        nil
      end
    end

    # Clear (and reload) the record cache
    def clear_static_record_cache
      @static_record_cache = nil
    end

    # The static record cache
    def static_record_cache
      @static_record_cache||= initialize_static_record_cache
    end

    protected

    # Find all the record and initialize the cache
    def initialize_static_record_cache#:nodoc:
      return unless @static_record_cache.nil?
      records = self.find_without_static_record(:all, acts_as_static_record_options[:find]||{})
      @static_record_cache = records.inject({:primary_key => {}, :key => {}, :calc => {}}) do |cache, record|
        cache[:primary_key][record.send(self.primary_key)] = record
        if acts_as_static_record_options[:key]
          cache[:key][record.send(acts_as_static_record_options[:key])] = record
        end
        cache
      end
    end
  end


  # This module is designed to define finder methods such as find_by_id to
  # search through the cache if no additional arguments are specified
  # The likelyhood of this working with < Rails 2.3 is pretty low.
  module DefineFinderMethods#:nodoc:

    #alias chain the finder method to the static_rc method
    #base_method_id would be like find_by_name
    def define_static_rc_alias(base_method_id)#:nodoc:
      if !respond_to?("#{base_method_id}_without_static_rc") &&
          respond_to?(base_method_id) && respond_to?("#{base_method_id}_with_static_rc")

          klass = class << self; self; end
          klass.class_eval "alias_method_chain :#{base_method_id}, :static_rc"
      end
    end

    # Retrieve the method name to call based on the attributes
    # Single attributes on primary key or the specified key call directly to the cache
    # All other methods iterate through the cache
    def static_record_finder_method_name(finder, attributes)#:nodoc:
      method_to_call = "find_in_static_record_cache(#{finder.inspect}, #{attributes.inspect})"
      if attributes.length == 1
        key_value = case attributes.keys.first.to_s
          when self.primary_key then [:primary_key, attributes.values.first.to_i]
          when acts_as_static_record_options[:key] then [:key, attributes.values.first.to_s]
        end

        method_to_call = "static_record_cache[#{key_value[0].inspect}][#{key_value[1].inspect}]" if key_value
      end
      method_to_call
    end

    # Define the finder method on the class, and return the name of the method
    # Ex. find_by_id will define find_by_id_with_static_rc
    #
    # The cache is searched if no additional arguments (:conditions, :joins, etc) are specified
    # If additional arguments do exist find_by_id_without_static_rc is invoked
    def define_static_record_finder_method(method_id, finder, bang, attributes)#:nodoc:
      method_to_call = static_record_finder_method_name(finder, attributes)
      method_with_static_record = "#{method_id}_with_static_rc"

      #override the method to search memory if there are no args
      class_eval %{
        def self.#{method_with_static_record}(*args)
          if (args.dup.extract_options!).any?
             #{method_id}_without_static_rc(*args)
          else
            result = #{method_to_call}
            #{'result || raise(RecordNotFound, "Couldn\'t find #{name} with #{attributes.to_a.collect {|pair| "#{pair.first} = #{pair.second}"}.join(\', \')}")' if bang}
          end
        end
      }, __FILE__, __LINE__

      method_with_static_record
    end

    #Method missing is overridden to use cache calls for finder methods
    def method_missing(method_id, *arguments, &block)#:nodoc:

      # If the missing method is  XXX_without_static_rc, define XXX
      # using the superclass ActiveRecord::Base method_missing then
      # Finally, alias chain it to XXX_with_static_rc
      if ((match = method_id.to_s.match(/(.*)_without_static_rc$/)) &&
          (base_method_id = match[1]))
        begin
          return super(base_method_id, *arguments, &block)
        ensure
          define_static_rc_alias(base_method_id)
        end
      end

      # If the missing method is a finder like find_by_name
      # Define on the class then invoke find_by_name_with_static_rc
      if match = ActiveRecord::DynamicFinderMatch.match(method_id)
        attribute_names = match.attribute_names
        if all_attributes_exists?(attribute_names) &&  match.finder?
          attributes = construct_attributes_from_arguments(attribute_names, arguments)
          method_name = define_static_record_finder_method(method_id, match.finder, match.bang?, attributes)
          return self.send method_name, *arguments
        end
      end

      #If nothing matches, invoke the super
      super(method_id, *arguments, &block)
    end
  end
end

ActiveRecord::Base.extend ActsAsStaticRecord unless defined?(ActiveRecord::Base.acts_as_static_record_options)

