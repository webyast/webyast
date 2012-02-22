# find the rails parent
require File.join(File.dirname(__FILE__), '..', 'config', 'rails_parent')
require File.join(RailsParent.parent, "test","test_helper")
require File.join(RailsParent.parent, "test","plugin_basic_tests")
require File.join(RailsParent.parent, "test","validation_assert")
