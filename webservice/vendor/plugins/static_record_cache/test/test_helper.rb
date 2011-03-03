

require 'ostruct'

require File.dirname(__FILE__)+"/../../../../config/boot"

begin ; require 'active_record' ; rescue LoadError;  require 'rubygems'; require 'active_record'; end

require 'active_support'
require 'active_record'
require 'active_record/version'
require 'active_record/fixtures'
require 'mocha'
require 'test/unit'
require 'fileutils'


dir = File.dirname(__FILE__)

require File.join(dir, '/../init')

ActiveRecord::Base.logger = Logger.new("debug.log")

config = ActiveRecord::Base.configurations['test'] = {
  :adapter  => "mysql",
  :username => "root",
  :encoding => "utf8",
  :host => '127.0.0.1',
  :database => 'static_record_cache' }

ActiveRecord::Base.establish_connection( config )


if File.exists?(active_record_context_dir = File.join(dir, '../../active_record_context'))
  require File.join(active_record_context_dir, '/lib/technoweenie/active_record_context.rb')
  require File.join(active_record_context_dir, '/init')
else
  raise LoadError.new("Cannot load active record context please install plugin")
end

require File.join( dir, '/db/schema.rb' )

models_dir = File.join( dir, 'models' )
$: << models_dir
Dir[ models_dir + '/*.rb'].each { |m| require m }





if ActiveRecord::VERSION::STRING < '2.3.1'
  
  TestCaseSuperClass = Test::Unit::TestCase
  class Test::Unit::TestCase #:nodoc:
    self.use_transactional_fixtures = true
    self.use_instantiated_fixtures = false
    
    def assert_queries(num = 1)
      $queries_executed = []
      yield
    ensure
      %w{ BEGIN COMMIT }.each { |x| $queries_executed.delete(x) }
      assert_equal num, $queries_executed.size, "#{$queries_executed.size} instead of #{num} queries were executed.#{$queries_executed.size == 0 ? '' : "\nQueries:\n#{$queries_executed.join("\n")}"}"
    end

  end

  Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
else



  TestCaseSuperClass = ActiveRecord::TestCase
  require 'active_record/test_case'
  class ActiveRecord::TestCase #:nodoc:
    include ActiveRecord::TestFixtures
    self.use_transactional_fixtures = true
    self.use_instantiated_fixtures = false
    self.fixtures :all
  end
  ActiveRecord::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
end

ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL = [/^PRAGMA/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/, /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/, /SHOW FIELDS/]

  def execute_with_query_record(sql, name = nil, &block)
    $queries_executed ||= []
    $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
    execute_without_query_record(sql, name, &block)
  end

  alias_method_chain :execute, :query_record
end

class TestCaseSuperClass
  def logger; ActiveRecord::Base.logger; end
  def self.logger; ActiveRecord::Base.logger; end
end
