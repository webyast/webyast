
require File.dirname(__FILE__) + '/../test_helper'

class RestdocTest < ActiveSupport::TestCase

  def setup
    @dummy_path = 'dummy/plugin/path'
    Rails.configuration.stubs(:plugin_paths).returns(@dummy_path)
    Dir.stubs(:'[]').with("#{@dummy_path}/*").returns(["#{@dummy_path}/dummy_plugin"])
    File.stubs(:directory?).with("#{@dummy_path}/dummy_plugin/app").returns(true)
    File.stubs(:directory?).with("#{@dummy_path}/dummy_plugin/public").returns(true)
    Dir.stubs(:'[]').with("#{@dummy_path}/dummy_plugin/public/**/restdoc/index.html").returns(
      ["#{@dummy_path}/dummy_plugin/public/controller/restdoc/index.html"])
    File.stubs(:file?).with("#{@dummy_path}/dummy_plugin/public/controller/restdoc/index.html").returns(true)
  end

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end

  def test_find
    r = Restdoc.find :all

    assert_equal ["controller/restdoc/index.html"], r
  end

  def test_find_nothing
    Dir.stubs(:'[]').with("#{@dummy_path}/dummy_plugin/public/**/restdoc/index.html").returns([])

    r = Restdoc.find :all

    assert_equal [], r
  end
end