#
#  Copyright (c) 2009-2012 Novell, Inc.
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


namespace 'check' do

  # define check:spelling task - check all words marked for translation
  # in pot files in a spell checker, requires gettext installed
  desc 'Check all texts in spellchecker'
  task 'spelling' => 'gettext:find' do
    raise "spell checker is missing, install 'ispell' package" unless File.exists? '/usr/bin/ispell'
    raise "american dictionary is missing, install 'ispell-american' package" unless File.exists? '/usr/lib/ispell/american.hash'

    # file with SLMS specific words
    dictionary = File.join(File.dirname(__FILE__), 'webyast.dictionary')
    success = true

    require 'set'

    Dir.glob('locale/*.pot').each do |file|
      puts "Processing file #{file}..."

      # messages are separated by empty line
      chunks = File.read(file).split("\n\n")
      # ignore the first block, it contains pot file metadata
      chunks.shift

      # remember the correct words to speed up the check
      processed = Set.new

      chunks.each do |c|
        comments = c.scan /^#.*$/

        # ignore ActiveRecord row name translations
        next if comments.any? { |com| com.match /^#: locale\/model_attributes.rb/ }

        if c.match /^msgid "(.*)"$/
          words = $1.gsub('\n', "\n").split /\s+/

          # print the comment header just once
          comment_printed = false

          words.each do |word|
            # escape single quotes
            word.gsub! /'/,"'\\\\''"

            # skip already checked words
            next if processed.include? word

            result = `echo -n '#{word}' | /usr/bin/ispell -H -d american -p #{dictionary}`
            if result.match /^word: how about: (.*)$/
              unless comment_printed
                puts comments.join "\n"
                comment_printed = true
              end

              puts "Word '#{word}' not found, possibilities: #{$1}"
            elsif result.match /^word: not found/
              unless comment_printed
                puts comments.join "\n"
                comment_printed = true
              end

              puts "Word '#{word}' not found"
            else
              processed.add word
            end
          end

          success &= !comment_printed

          puts if comment_printed
        end
      end

      raise "Spell check failed. Fix the spelling or if it's correct add it to the custom dictionary (file #{dictionary})" unless success
      puts "Spell check finished successfully"
    end
  end
end
