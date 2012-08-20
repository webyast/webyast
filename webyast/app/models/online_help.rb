#--
# Webyast Webclient framework
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

# RORSCAN_INL: do not know whats wrong here....
require 'open-uri'

class OnlineHelp
  @@modules_html = nil
  @@control_html = nil

  def self.find(model)
    return OnlineHelp.parse(model)
  end
  
  def OnlineHelp.parse(model)
    Rails.logger.info "***** ONLINE HELP for #{model} *****"
    
    unless model == "Area" #TODO: Find better way to navigate through WebYaST documentation
      @@modules_html = open("https://doc.opensuse.org/products/other/WebYaST/webyast-user_sd/cha.webyast.user.modules.html").read unless @@modules_html
      html = @@modules_html
    else
      @@control_html = open("https://doc.opensuse.org/products/other/WebYaST/webyast-user_sd/cha.webyast.user.control.html#cha.webyast.user.control.status").read unless @@control_html
      html = @@control_html
    end
    
    doc = Nokogiri::HTML(html)
    doc.encoding = 'utf-8'

    unless doc.nil?
      if model == "Limits" #TODO: Find better way to navigate through WebYaST documentation
        doc.css('div.sect2').each do |link|
          title = link.attributes['title'].text
          Rails.logger.info title.inspect

          if title.include? model
            link.css('h2.title span.permalink').remove()
            link.css('a[alt="Permalink"]').remove()
            link.css('tr.head td:first').remove()
            link.css('script').remove()

            return link
          end
        end
      else
        doc.css('div.sect1').each do |link|
          title = link.attributes['title'].text
          Rails.logger.info title.inspect

          if title.include? model
            link.css('h2.title span.permalink').remove()
            link.css('a[alt="Permalink"]').remove()
            link.css('tr.head td:first').remove()
            link.css('div.sect2').remove()
            link.css('script').remove()

            return link
          end
        end
      end
    end
    Rails.logger.info "***** Document END *****"
  end
  
end
