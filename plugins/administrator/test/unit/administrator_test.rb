require 'test_helper'

require 'administrator'

class AdministratorTest < ActiveSupport::TestCase

  def setup    
    @model = Administrator.instance
  end

  def test_save_password
    ret = @model.save_password("new password")
    assert ret
  end

#  def test_read_aliases
#    assert @model.aliases.size == 0
#    YastService.stubs(:Call).with('YaPI::ADMINISTRATOR::Read').returns({ "aliases" => [ "a@b" ] })
#    ret = @model.read_aliases
#    assert ret
#    assert @model.aliases.size == 1
#  end

  def test_save_aliases
    assert @model.aliases.size == 0
    ret = @model.save_aliases([ "test@domain.com", "a@b" ])
    assert ret
    assert @model.aliases.size == 2
  end

end
