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

module ActionController
  class UrlRewriter
      #monkey patch for url rewriter to allow easy change of port in url_for
      def rewrite_url(options)
      rewritten_url = ""

      unless options[:only_path]
        rewritten_url << (options[:protocol] || @request.protocol)
        rewritten_url << "://" unless rewritten_url.match("://")
        rewritten_url << rewrite_authentication(options)
        rewritten_url << (options[:host] || options.key?(:port) ? @request.host : @request.host_with_port )
        rewritten_url << ":#{options.delete(:port)}" if options.key?(:port)
      end

      path = rewrite_path(options)
      rewritten_url << ActionController::Base.relative_url_root.to_s unless options[:skip_relative_url_root]
      rewritten_url << (options[:trailing_slash] ? path.sub(/\?|\z/) { "/" + $& } : path)
      rewritten_url << "##{CGI.escape(options[:anchor].to_param.to_s)}" if options[:anchor]

      rewritten_url
    end
  end
end
