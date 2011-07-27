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

require 'active_resource/http_mock'
module ActiveResource
  class HttpMock
    class << self
      # sets authentication for webyast structure to generate proper
      # authentication header
      def set_authentication
        YaST::ServiceResource::Session.site = "http://localhost"
        YaST::ServiceResource::Session.login = "test"
        YaST::ServiceResource::Session.auth_token = "1234"
        ResourceCache.instance.send(:permissions=,[])
        ResourceCache.instance.send(:resources=,[])
      end

      # Gets authentication header which must send request for authentication
      # to rest-service
      def authentication_header
        {"Authorization"=>"Basic OjEyMzQ=",
         "ACCEPT_LANGUAGE"=>"en_US"}
      end

      # Gets authentication header which must send request for authentication
      # to rest-service
      def authentication_header_without_language
        {"Authorization"=>"Basic OjEyMzQ="}
      end
    end

    class Responder
      # generate request to introspect target rest-service
      # routes:: hash with format interface => path
      # opts:: hash with additional options (keys policy with value and singular with true if resource is singular)
      def resources(routes,opts={})
        response = "<resources type=\"array\">"
        routes.each do |interface,path|
          response << "<resource><interface>#{interface}</interface><href>#{path}</href>"
          response << (opts[:policy] ? "<policy>#{opts[:policy]}</policy>" : "<policy/>")
          response << ("<singular type=\"boolean\">" + (opts[:singular].nil? ? "true" : opts[:singular].to_s) + "</singular>")
          response << "</resource>\n"
        end
        response << "</resources>"
        get   "/resources.xml",   {}, response, 200
        get   "/resources.xml",   HttpMock.authentication_header, response, 200
      end

      # generate response for permission request
      # prefix:: prefix of permissions (filter passed to permission call)
      # perm:: hash with permissin as key and boolean if permission is granted
      # opts:: additional options (not used yet)
      def permissions(prefix,perm,opts={})
        response = "<permissions type=\"array\">"
        perm.each do |perm,granted| 
          response << "<permission>"
          response << "<granted type=\"boolean\">#{granted.to_s}</granted>"
          response << "<id>#{prefix}.#{perm.to_s}</id>"
          response << "</permission>"
        end
        response << "</permissions>"
        get   "/permissions.xml?user_id=test", HttpMock.authentication_header_without_language, response, 200
      end
    end

  end
end
