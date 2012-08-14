#
#  Copyright (c) 2012 Novell, Inc.
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


def clean_online_help doc
  doc.css('h2.title span.permalink').remove()
  doc.css('a[alt="Permalink"]').remove()
  doc.css('tr.head td:first').remove()

  # remove chapter number from title
  titles = doc.css('h2.title')

  titles.each do |title|
    # \302\240 is unicode non-breaking space
    if title.content.match /^\d+\.\d+\.\302\240(.*)/
      title.content = $1
    end
  end

  # check whether there is a reference to another module
  puts "\n** WARNING: Detected reference to another section, the file probably needs manual edit\n\n" unless doc.css('a.xref').empty?

  # just to be sure to exclude any potentional Javascript
  doc.css('script').remove()
end

def download_module_help model
  require 'open-uri'
  require 'nokogiri'

  url = (model == "Area") ? "https://doc.opensuse.org/products/other/WebYaST/webyast-user_sd/cha.webyast.user.control.html#cha.webyast.user.control.status" :
    "https://doc.opensuse.org/products/other/WebYaST/webyast-user_sd/cha.webyast.user.modules.html"
    
  puts "Downloading #{url}..."
  html = open(url).read

  doc = Nokogiri::HTML(html)
  doc.encoding = 'utf-8'

  unless doc.nil?
    if model == "Limits"
      doc.css('div.sect2').each do |link|
        title = link.attributes['title'].text

        if title.include? model
          puts "Using section: #{title}"

          clean_online_help link

          return link.to_html
        end
      end
    else
      doc.css('div.sect1').each do |link|
        title = link.attributes['title'].text

        if title.include? model
          puts "Using section: #{title}"

          clean_online_help link
          link.css('div.sect2').remove()

          return link.to_html
        end
      end
    end
  end

  return ""
end

def create_online_help_task keyword, filename = nil
  require 'rake'

  filename ||= keyword.downcase

  namespace :download do

    desc "Download online help from https://doc.opensuse.org (section #{keyword})"
    task :online_help do
      html = download_module_help keyword

      if html.empty?
        puts "No online help found"
      else
        require 'fileutils'
        FileUtils.mkdir_p "public/online_help"

        path = "public/online_help/#{filename}.html"
        puts "Saving help to file #{path}"

        File.open(path, "w") do |file|
          file.puts html
        end
      end
    end

  end
end