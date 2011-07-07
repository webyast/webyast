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

# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.dirname(__FILE__) + '/../test_helper'

class PrivateRoutingTest < ActionController::TestCase
  test "plugin private routing" do
    searchdir = File.join(File.dirname(__FILE__),"..","..","..","plugins")

    if File.directory? searchdir
      Dir.foreach(searchdir) { |filename|
        unless filename[0].chr == "."
          assert !File.exist?(File.join(searchdir,filename,"config","routes.rb")), "Plugin #{filename} contains private routing"
        end
      }
    end
  end
end
