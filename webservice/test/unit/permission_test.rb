require File.dirname(__FILE__) + '/../test_helper'

# Test Permission class

class PermissionTest < ActiveSupport::TestCase
  def test_create_permission
    perm = Permission.new
    assert perm
    assert perm.name.empty?
    assert !perm.grant
  end
  def test_create_permission_with_args
    perm = Permission.new "foo", true
    assert_equal perm.name, "foo"
    assert perm.grant
  end
  def test_permission_to_xml
    perm = Permission.new "foo", true
    xml = perm.to_xml
    assert xml
    hash = Hash.from_xml(xml)
    assert hash
    perm = hash["permission"]
    assert perm
    assert_equal perm["name"], "foo"
    assert perm["grant"]
  end
  def test_permission_to_json
    perm = Permission.new "foo", true
    json = perm.to_json
    assert json
#    hash = Hash.from_json(json)
#    assert hash
#    perm = hash["permission"]
#    assert perm
#    assert_equal perm["name"], "foo"
#    assert perm["grant"]
  end
end