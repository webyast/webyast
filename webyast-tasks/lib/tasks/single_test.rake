#--
# Webyast framework
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

require 'rake'

# This helper task allows to execute single/individual test cases
rule "" do |t|
  # test:file:method
  if /test:(.*)(:([^.]+))?$/.match(t.name)
    arguments = t.name.split(":")[1..-1]
    file_name = arguments.first
    test_name = arguments[1..-1].map{|x| x.gsub(/^test_/, '')}

    if File.exist?("test/unit/#{file_name}_test.rb")
      run_file_name = "unit/#{file_name}_test.rb"
    elsif File.exist?("test/unit/#{file_name}.rb")
      run_file_name = "unit/#{file_name}.rb"
    elsif File.exist?("test/unit/#{file_name}")
      run_file_name = "unit/#{file_name}"
    elsif File.exist?("test/functional/#{file_name}_controller_test.rb")
      run_file_name = "functional/#{file_name}_controller_test.rb"
    elsif File.exist?("test/functional/#{file_name}_test.rb")
      run_file_name = "functional/#{file_name}_test.rb"
    end

    sh "ruby -Ilib:test test/#{run_file_name} -n /#{test_name}/"
  end
end
