require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class GroupsTest < ActiveSupport::TestCase

  GROUP_READ_DATA = { 'more_users' => { 'games' => 1,
                                        'tux' => 1
                                      },
                      'userlist' => {},
                      'gidNumber' => 100,
                      'cn' => 'users',
                      'userPassword' => 'x',
                      'type' => 'local'
                    };

  GROUP_LOCAL_CONFIG = { "type" => ["s","local"], "cn" => ["s","users"] }
  
  GROUP_SYSTEM_CONFIG = { "type" => ["s","system"], "cn" => ["s","users"] }

  GROUP_WRITE_DATA= { 'userlist' => ["as", [] ],
                      'gidNumber' => ["i", 100],
                      'cn' => ["s",'new_users']
                    };

  OK_RESULT = ""

  def setup
    Group # make ruby load this class before stubbing
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns(GROUP_READ_DATA)
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_SYSTEM_CONFIG).once.returns({})
    YastService.stubs(:Call).with("YaPI::USERS::GroupsGet",{"type"=>["s","system"]}).once.returns({100 => GROUP_READ_DATA})
    YastService.stubs(:Call).with("YaPI::USERS::GroupsGet",{"type"=>["s","local"]}).once.returns({100 => GROUP_READ_DATA})
    @model  = Group.find "users"
    @models = Group.find_all
  end

  def test_read
    assert_not_nil @model.gid
    assert_not_nil @model.cn
    assert_not_nil @model.old_cn
    assert_instance_of(Array, @model.default_members)
    assert_instance_of(Array, @model.members)
    assert_not_nil @model.type
    
    assert_not_nil @models
    assert_instance_of(Array, @models)
  end

  def test_write
    @model.cn = "new_users"
    assert_nothing_raised do
      YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns(GROUP_READ_DATA)
      YastService.stubs(:Call).with("YaPI::USERS::GroupModify",GROUP_LOCAL_CONFIG,GROUP_WRITE_DATA).once.returns(OK_RESULT)
      @model.save
    end
  end
end
