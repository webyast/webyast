
# this is a helper script
#
# ruby-dbus is NOT thread safe and therefore patches cannot be safely read
# in a separate thread, workaround is to use a separate process (this script)

bs = BackgroundStatus.new do
  # print the progress in XML format
  puts bs.to_xml

  # print it immediately, flush the output buffer
  $stdout.flush
end

patches = Patch.do_find(:all, bs)

puts patches.to_xml(:root => "patches", :dasherize => false).gsub!("\n", '')
