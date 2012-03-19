#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

module StatusHelper
  def limits_reached group
    group.single_graphs.each do |single_graph|
      single_graph["lines"].each do |line|
        return true unless line["limits"]["reached"].blank?
      end    
    end
    return false
  end

  def graph_id group, headline=nil
    id = "#{group}" 
    id += "_" + headline if headline
    id.delete!('\"')
    id.tr!(' /','_')
    id
  end

  def log_id id
    "log-#{id}-console"
  end

  def evaluate_next_graph group, single_graphs, index
    return "$('#progress').hide();\n" if index+1 > single_graphs.size
    graph_div_id = graph_id(group, single_graphs[index]["headline"])
    return "$.ajax({ url: '" +
           url_for( { :action => "evaluate_values", :group_id => group, :graph_id => single_graphs[index]["headline"]} ) + 
           "',\n" +
           "         type: 'POST',\n" +
           "         success: function(data, status, xhr) {\n" +
           "           $('#" + graph_id(group, single_graphs[index]["headline"]) + "').html(data);\n" +
           evaluate_next_graph(group, single_graphs, index+1) +
           "         },\n" +
           "         error: function(xhr, status, error) {\n" +
           "           $('#" + graph_id(group, single_graphs.first["headline"]) + "').html('<b>" +
                       escape_javascript( _("Error: Cannot get information.")) + "</b>');\n" +
           "         }\n" +
           "      });\n"
  end

end
