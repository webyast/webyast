#! /usr/bin/env ruby
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

require "rake"
require "English"

def make_rdoc_header(input_fname, output_fname)
  File.open(input_fname, "r") do |inf|
    File.open(output_fname, "w") do |out|
      out.puts "#--"
      inf.each_line { |l| out.printf "# %s", l }
      out.puts "#++"
    end
  end
end

file "GPLv2.rb" => "GPLv2" do |t|
  make_rdoc_header t.prerequisites[0], t.name
end

def verbose(msg)
  # FIXME verbose seems to be on by default, but can use rake -q
  if RakeFileUtils.verbose
    puts msg
  end
end

LIMIT = (ENV["LIMIT"] || 10).to_i
def license_report
  # FIXME: operate on distributed files, i.e. tarballs
  report = {:missing => [], :seen => [], :unneeded => [], :skipped => []}
  filenames = `git ls-files`.split "\n"
  filenames.each do |fn|
    # file name checks
    if fn =~ /\.yml\z/ || fn =~ /\.conf\z/ || fn =~ /\.xml\z/
      report[:skipped] << "#{fn}: skipped by name match (configuration file)"
      next
    elsif fn =~ /README/ 
      report[:skipped] << "#{fn}: skipped by name match (README file)"
      next
    elsif fn =~ /^db\//
      report[:skipped] << "#{fn}: skipped by name match (generated DB migration or schema)"
      next
    elsif fn =~ /licenses\//
      report[:skipped] << "#{fn}: skipped by name match (already contain license)"
      next
    elsif fn =~ /COPYING/
      report[:skipped] << "#{fn}: skipped by name match (already contain license)"
      next
    elsif fn =~ /Rakefile/
      report[:skipped] << "#{fn}: skipped by name match (Rakefile)"
      next
    elsif fn =~ /browsing_test.rb/
      report[:skipped] << "#{fn}: skipped by name match (browsing_test.rb)"
      next
    elsif fn =~ /model_attributes.rb/
      report[:skipped] << "#{fn}: skipped by name match (model_attributes.rb)"
      next
    elsif fn =~ /Gemfile/
      report[:skipped] << "#{fn}: skipped by name match (Gemfile)"
      next
    elsif fn =~ /\/rrdtool.*\.txt/
      report[:skipped] << "#{fn}: skipped by name match (rrdtool output is not licensed)"
      next
    elsif fn =~ /\.changes\z/
      report[:skipped] << "#{fn}: skipped by name match (changes file)"
      next
    elsif fn =~ /\.haml\z/
      report[:skipped] << "#{fn}: skipped by name match (haml file)"
      next
    elsif fn =~ /vendor\/plugins/
      report[:skipped] << "#{fn}: skipped by name match (polkit policy file)"
      next
    elsif fn =~ /\.policy\z/
      report[:skipped] << "#{fn}: skipped by name match (polkit policy file)"
      next
    elsif fn =~ /\.png\z/ || fn =~ /\.odg\z/ || fn =~ /\.gif\z/ || fn =~ /\.swf\z/ || fn =~ /\.ico\z/
      report[:skipped] << "#{fn}: skipped by name match (binary file)"
      next
    elsif fn =~ /\.po\z/ || fn =~ /\.mo\z/
      report[:skipped] << "#{fn}: skipped by name match (translation file)"
      next
    elsif fn =~ /\.gemspec\z/ || fn =~ /\.mo\z/
      report[:skipped] << "#{fn}: skipped by name match (gemspec file)"
      next
    elsif fn =~ /\.curl\z/
      report[:skipped] << "#{fn}: skipped by name match (test fixture)"
      next
    elsif fn =~ /\.gitignore\z/
      report[:skipped] << "#{fn}: skipped by name match (version system file)"
      next
    end

    # file content checks
    seen_copyright = false
    skipped = false

    File.open(fn, "r") do |f|
      f.each_line do |l|
        if $INPUT_LINE_NUMBER < 3 && l =~ /Source:/
          skipped = true
          report[:skipped] << "#{fn}: skipped (external or generated source)"
          break
        end
        break if $INPUT_LINE_NUMBER > LIMIT
        if l =~ /copyright/i
          seen_copyright = true
          break
        end
      end
    end
    next if skipped

    if seen_copyright
      report[:seen] << "#{fn}:#{$INPUT_LINE_NUMBER}: copyright seen"
    elsif $INPUT_LINE_NUMBER <= LIMIT
      report[:unneeded] << "#{fn}:#{$INPUT_LINE_NUMBER}: copyright unneeded, file too short"
    else
      report[:missing] << "#{fn}:#{$INPUT_LINE_NUMBER}: error: copyright missing (in first #{LIMIT} lines)"
    end
  end

  puts "\nMissing license:"
  report[:missing].each { |m| puts m }
  exit 1 unless report[:missing].empty?
  verbose "\nSkipped files:"
  report[:skipped].each { |m| verbose m }
  verbose "\nCopyright find in these files:"
  report[:seen].each { |m| verbose m }
  verbose "\nCopyright detected as not needed in this files:"
  report[:unneeded].each { |m| verbose m }
end

namespace "license" do
  desc "Check the copyright+license headers in files"
  task :report do
    license_report
  end
end

task :package => "license:report"
