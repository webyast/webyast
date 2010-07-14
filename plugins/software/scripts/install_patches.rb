#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++


# this is a helper script
#
# ruby-dbus is NOT thread safe and therefore patches cannot be safely read
# in a separate thread, workaround is to use a separate process (this script)

# this is an observer class which prints changes in the progress
# in XML format on stdout
class ProgressPrinter
  def initialize(prog)
    # watch changes in a progress status object
    prog.add_observer(self)
  end

  # this is the callback method
  def update(progress)
    # print the progress in XML format on single line
    puts progress.to_xml.gsub("\n", '')

    # print it immediately, flush the output buffer
    $stdout.flush
  end
end

bs = BackgroundStatus.new

# register a progress printer for the progress object
ProgressPrinter.new(bs)

pk_id = ARGV[2]

begin
  result = Resolvable.do_package_kit_install(pk_id, bs)
  puts ({'result' => result}).to_xml(:root => "patch_installation", :dasherize => false).gsub("\n", '')
rescue Exception => e
  if e.respond_to? :to_xml
    puts e.to_xml.gsub("\n", '')
  else
    puts PackageKitError.new(e.message).to_xml.gsub("\n", '')
  end
end
