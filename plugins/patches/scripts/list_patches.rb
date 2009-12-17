
# this is a helper script
#
# ruby-dbus is NOT thread safe and therefore patches cannot be safely read
# in a separate thread, workaround is to use a separate process (this script)

# this an observer class which prints changes in the progress
# in XML format on stdout
class ProgressPrinter
  def initialize(prog)
    # watch changes in a progress status object
    prog.add_observer(self)
  end

  # this is the callback method
  def update(progress)
    # print the progress in XML format
    puts progress.to_xml

    # print it immediately, flush the output buffer
    $stdout.flush
  end
end

bs = BackgroundStatus.new

# register a progress printer for the progress object
ProgressPrinter.new(bs)

what = ARGV[0] || :available

patches = Patch.do_find(what, bs)

puts patches.to_xml(:root => "patches", :dasherize => false).gsub!("\n", '')
