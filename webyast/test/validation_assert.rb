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

require "open3"

class ActionController::TestCase
  # Assert which checks if body of response is valid.
  # 
  # Use tidy checks. Failed if contain any error. 
  # If body contain errors or warnings it writes body to file tidy-failed.html
  #
  # === example
  #   require File.expand_path( File.join("test","validation_assert"), RailsParent.parent )
  #   
  #   class SystemtimeControllerTest < ActionController::TestCase
  #     def test_index
  #       get :index
  #       assert_response :success
  #       assert_valid_markup
  #     end
  #   end
  def assert_valid_markup(markup=@response.body)
    if @response.redirect?
      return
    end

    fail("Tidy is not available, install 'tidy'") unless system("which tidy &>/dev/null")

    Open3.popen3('tidy -e') do |stdin, stdout, stderr|
      # write the markup to tidy
      stdin.puts markup
      stdin.close_write
      stdout.read
      output = stderr.read

      messages = []
      output.each_line do |line|
        messages << line.chomp if line =~ /Warning|Info|Error/
      end

      errors = 0
      warns = 0
      if output =~ /^(\d+) warnings*, (\d+) errors*/
        warns = $1.to_i
        errors = $2.to_i
        unless (errors == 0 and warns == 0)
          filename = ENV["TIDY_FAILED_FILE"].blank? ? "tidy-failed.html" : ENV["TIDY_FAILED_FILE"]
          begin
            File.open(filename,"w+") do
              |file|
              file.puts markup
            end
          rescue Exception => e
            puts "WARNING: Cannot save tidy output: #{e.message}.\nUse TIDY_FAILED_FILE variable to override the default location."
          end
        end
        assert (errors == 0), "#{errors} validation errors and #{warns} warnings found:\n#{messages.map{ |x| "- #{x}"}.join("\n")} \n
            See #{Dir.pwd}/tidy-failed.html"
      end
      
    end
  end
end
