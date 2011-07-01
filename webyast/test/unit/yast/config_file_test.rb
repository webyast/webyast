#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

require File.dirname(__FILE__) + '/../../test_helper'
require 'yast/config_file'

def test_data(name)
  File.join(File.dirname(__FILE__), "data", name)
end

class ConfigFileTest < ActiveSupport::TestCase
  def setup
    YaST::ConfigFile.stubs(:config_default_location).returns(test_data('config'))
  end

  def test_config
    # simple usage
    config = YaST::ConfigFile.new(:vendor)

    assert_equal(config.path, test_data('config/vendor.yml'))
    
    assert_equal("This is an evil eula that will make you think twice before clicking it", config['appliance']['eula'])

    # now try to load an non-existing resource
    # this should be ok
    config = nil
    assert_nothing_raised do
      config = YaST::ConfigFile.new(:whatever)
    end
    # and the path should be pointed to the right file
    assert_equal(test_data('config/whatever.yml'), config.path)

    # now try to load an non-existing file
    assert_raise YaST::ConfigFile::NotFoundError do
      YaST::ConfigFile.load_file(test_data('config/whatever.yml'))
    end

    #assert_instance_of Hash, config
  end
  
end
