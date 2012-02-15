#
#  Copyright (c) 2012 Novell, Inc.
#  All Rights Reserved.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public License as
#  published by the Free Software Foundation; version 2.1 of the license.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with this library; if not, contact Novell, Inc.
#
#  To contact Novell about this file by physical or electronic mail,
#  you may find current contact information at www.novell.com

def enable_gem_groups(enabled)
  gemfile = ENV["BUNDLE_GEMFILE"] || "Gemfile"
  lines = File.read(gemfile).split("\n")

  # current state - in/out a group definition
  in_group = false

  lines.each do |line|
    if in_group
      puts "# #{line}"
      if line.match /^\s*end\s*/
        in_group = false
      end
    else
      if line.match(/^\s*group\s*:(\S+)\sdo/) && !enabled.include?($1.to_sym)
        in_group = true
        puts "# #{line}"
      else
        puts line
      end
    end
  end
end

namespace :gemfile do
  desc "Print Gemfile content suitable for production (with all groups commented out)"
  task :production do
    enable_gem_groups []
  end

  desc "Print Gemfile content with enabled assets group"
  task :assets do
    enable_gem_groups [:assets]
  end

  desc "Print Gemfile content with enabled test group"
  task :test do
    enable_gem_groups [:test]
  end
end
