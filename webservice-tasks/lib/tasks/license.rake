#! /usr/bin/env ruby
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
  filenames = `git ls-files`.split "\n"
  filenames.each do |fn|
    # file name checks
    if fn =~ /\.yml\z/
      verbose "#{fn}: skipped by name match"
      next
    end

    # file content checks
    seen_copyright = false

    File.open(fn, "r") do |f|
      f.each_line do |l|
        break if $INPUT_LINE_NUMBER > LIMIT
        if l =~ /copyright/i
          seen_copyright = true
          break
        end
      end
    end

    if seen_copyright
      verbose "#{fn}:#{$INPUT_LINE_NUMBER}: copyright seen"
    elsif $INPUT_LINE_NUMBER <= LIMIT
      verbose "#{fn}:#{$INPUT_LINE_NUMBER}: copyright unneeded, file too short"
    else
      puts "#{fn}:#{$INPUT_LINE_NUMBER}: error: copyright missing (in first #{LIMIT} lines)"
    end
  end
end

namespace "license" do
  desc "Check the copyright+license headers in files"
  task :report do
    license_report
  end
end

task :default => "license:report"
