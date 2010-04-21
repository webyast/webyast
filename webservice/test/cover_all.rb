#!/usr/bin/ruby
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

#
# Do full coverage test for .../webservice and .../../plugins/*
#
# Usage:
#
# ruby cover_all.rb 2> /dev/null
#

require 'find'

def coverage_test dir = "."
  wd = Dir.getwd
  Dir.chdir dir
  puts "Coverage for #{dir}:"
  coverage= Hash.new
  task = nil
  Dir.new("test").each do |f|
    next if f[0,1] == "."
    next if f[-1..-1] == "~"
    next if f[-3..-1] == ".rb"
    task = nil
    case f.split("/").pop
    when "unit": task = "units"
    when "functional" : task = "functionals"
    when "integration" : task = "integration"
    end
    next unless task
    res = %x{rake test:#{task}:rcov}
    res.scan(/^\|[^\.\s].*\.rb.*$/) do |c|
      covs = c.split "|"
      file = covs[1]
      percent = covs[-1].to_f
      coverage[file] = percent unless coverage[file] && (coverage[file] > percent)
    end
  end rescue nil
  puts "*** No tests for #{dir}" unless task
  coverage.each do |file,percent|
    next if percent > 99.0
    puts "  %6.2f%%  %-35s" % [percent, file]
  end
  Dir.chdir wd
  puts
end

def visit_plugins dir = ".."
  path = File.join(dir, "plugins")
  Dir.new(path).each do |f|
    next if f[0,1] == "."
    coverage_test File.join(path,f)
  end
end

coverage_test
visit_plugins
