# Copyright (c) 2010 Novell Inc.
#
# Based on
# http://github.com/accuser/flonch/blob/master/lib/response_validator.rb
# Copyright (c) 2009 Matthew Gibbons <mhgibbons@me.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
require 'tidy'

module YaST
  module Rack
    
    class ResponseValidator
      include ViewHelpers::HtmlHelper
      
      DEFAULT_TIDY_OPTS = {
        'char-encoding'     => 'utf8',
        'indent'            => true,
        'indent-spaces'     => 2,
        'tidy-mark'         => false,
        'wrap'              => 0
      }
  
      attr_accessor :options
  
      def initialize(app, options = {})
        options.stringify_keys!
        options.reverse_merge! DEFAULT_TIDY_OPTS
    
        self.options = options
    
        @app = app  
      end
  
      def call(env)
        status, headers, response = @app.call(env)

        if should_validate? headers, env
          response = ::Rack::Response.new(validate(response.body, :partial => xhr?(env)), status, headers)
          response.finish
        else
          [ status, headers, response ]
        end
      end
  
      private

      # whether it is an ajax request
      def xhr?(env)
        env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" # RORSCAN_ITL
      end
      
      def should_validate?(headers, env)
        headers && headers["Content-Type"] && headers["Content-Type"].include?("text/html") && !env["QUERY_STRING"].include?("tidy=no")
      end

      def validate(content, opts={}) #:nodoc:
        cooked_content = content
        if opts[:partial]
          # insert basic boilerplate that makes a partial page pass thru Tidy
          first_line = content.each_line.to_a.first || ""
          if first_line.include?("DOCTYPE")
            doctype = first_line
          else
            doctype = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
          end
          # BTW, do not insert newlines here, otherwise line numbers will
          # not match in the Tidy report
          cooked_content = "#{doctype}\n<html><head><title>tidy</title></head><body>#{content}</body></html>"
        end

        Tidy.open(self.options) do |tidy|
          tidy.clean(cooked_content)
          unless tidy.errors.empty?
              content << present_errors(tidy.errors)
          end
        end
        content
      end
      
      def present_errors(s)
        "<div class='ui-state-error'><p><b>HTML errors:</b></p><pre>#{html_escape(s)}</pre></div>"
      end

      HTML_ESCAPE	=	{ 
        '&' => '&amp;', 
        '>' => '&gt;', 
        '<' => '&lt;', 
        '"' => '&quot;' 
      }
    
      def html_escape(s)
        s.to_s.gsub(/[&"><]/) { |special| HTML_ESCAPE[special] }
      end
    end

  end
end
