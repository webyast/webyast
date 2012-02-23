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

# Haml gettext parser module
#
#  http://pastie.org/445297
require 'gettext/tools/rgettext'
require 'gettext/tools/parser/ruby'
require 'haml'

class Haml::Engine
  # Overriden function that parses Haml tags
  # Injects gettext call for plain text action.
  def parse_tag(line)
    tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
      nuke_inner_whitespace, action, value = super(line)
    @precompiled << "_(\"#{value}\")\n" unless action || value.empty?
      [tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
    nuke_inner_whitespace, action, value]
  end

  # Overriden function that producted Haml plain text
  # Injects gettext call for plain text action.
  def push_plain(text)
    @precompiled << "_(\"#{text}\")\n"
  end
end

# Haml gettext parser
module HamlParser
  module_function

  def target?(file)
    File.extname(file) == ".haml"
  end

  def parse1(file, ary)
    haml = Haml::Engine.new(IO.readlines(file).join)
    code = haml.precompiled.split(/$/)
    GetText::RubyParser.parse_lines(file, code, ary)
  end

  def parse2(file, ary, regex_start, regex_end)
    haml = Haml::Engine.new(IO.readlines(file).join)
    code_stream = haml.precompiled
    position = code_stream =~ regex_start
    code = []
    result = []
    while position
      code_stream = code_stream[position,code_stream.size-1]
      end_position = code_stream =~ regex_end
      if end_position
        end_position += 3
        code << code_stream[0..end_position]
        code_stream = code_stream[end_position,code_stream.size-1]
        position = code_stream =~ regex_start
      else
        puts "parser error for file #{file}"
        return result
      end
    end
    begin
      result = GetText::RubyParser.parse_lines(file, code, ary)
    rescue Exception => e
      puts "Error:#{file} #{e.inspect}"
    end
    result
  end

  def parse(file, ary = [])
    parse1(file, ary) + parse2(file, ary, /( |\()_\(\"/, /\"\)/) + parse2(file, ary, /( |\()_\(\'/, /\'\)/)
  end

end

GetText::RGetText.add_parser(HamlParser)

