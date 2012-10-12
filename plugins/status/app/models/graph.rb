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

#
# This class handles the graph configuration for the status module
# The yaml file is located in config/status_configuration.yaml
#

require 'builder'
require 'yast/paths'

class Graph
  require 'yaml'

  attr_reader :group_name
  attr_reader :headline
  attr_reader :y_scale
  attr_reader :y_label
  attr_reader :y_max
  attr_reader :y_decimal_places
  attr_reader :single_graphs

  private

  # avoid race conditions when creating the config file
  # at background - allow only one thread writing it
  #
  @@mutex = Mutex.new

  #global variables
  @@configuration_file = "status_configuration.yaml" 
  @@translate = true

  # 
  # reading data from Metric
  #
  def self.read_data(id)
    data = {}
    metric = Metric.find(id)
    data = metric.data() if metric
    return data
  end


  #
  # Checking limit. Return true if a limit has been reached.
  #
  def check_limits(metric_id, metric_column, limits)
    id = Metric.default_host + "+" + metric_id
    metric_column ||= "value"
    data = Graph.read_data(id)
    limit_reached = false
    data.each do |key, values|
      if key == metric_column
        values.each do |date, value| 
          if limits.has_key?("max") && limits["max"].to_i > 0 && value && limits["max"].to_i < value/y_scale.to_i
            Rails.logger.info "Max #{limits['max']} for #{metric_id}(#{metric_column}) has been reached"
            limit_reached = true
          end 
          if limits.has_key?("min") && limits["min"].to_i > 0 && value && limits["min"].to_i > value/y_scale.to_i
            Rails.logger.info "Min #{limits['min']} for #{metric_id}(#{metric_column}) has been reached"
            limit_reached = true
          end 
          break if limit_reached
        end
      end
      break if limit_reached
    end
    limit_reached
  end

  #
  # evalualte config directory of the status plugin
  #
  def self.plugin_config_dir()
     File.join YaST::Paths::VAR, "status"
  end

  #
  # Create a default configriation file based on the return values of
  # the metrics
  #
  def self.create_config(filename)
    config = Hash.new
    metrics = Metric.find(:all)

    #if metrics is empty the collectd deamon is not running
    raise ServiceNotRunning.new('collectd') if metrics.blank?

    #Disk
    _("GByte") #just for translation
    _("Disk") #just for translation
    disk = {"headline"=>'_("Disk")',
            "y_scale"=>1073741824, 
            "y_label"=>'_("GByte")', 
            "y_max"=>nil,
            "y_decimal_places"=>0,
            "single_graphs"=>[]}
    metrics.each do |metric|
      if (metric.type == "df" && !metric.type_instance.start_with?("dev") && 
          !metric.type_instance.downcase.start_with?("media")) #no plugable media and CDROM,DVD,...
        metric_id = metric.id[metric.host.length+1..metric.id.length-1] #cut off host-id
        disk["single_graphs"] << {"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, 
                                              "metric_column"=>"used", "metric_id"=>metric_id}, 
                                             {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, 
                                              "metric_column"=>"free", "metric_id"=>metric_id}], 
                                   "headline"=>metric.type_instance, 
                                   "cummulated"=>"true",
                                   "linegraph"=>"false"}
      end
    end
    config["Disk"] = disk unless disk["single_graphs"].blank?
    
    #Network
    _("MByte/s") #just for translation
    _("Network") #just for translation
    network = {"headline"=>'_("Network")',
               "y_scale"=>1, 
               "y_label"=>'_("MByte/s")', 
               "y_max"=>nil,
               "y_decimal_places"=>0,
               "single_graphs"=>[]}
    metrics.each do |metric|
      if metric.type == "if_packets" && 
         (metric.type_instance.start_with?("eth") || metric.type_instance.start_with?("ctc"))
        metric_id = metric.id[metric.host.length+1..metric.id.length-1] #cut off host-id
        network["single_graphs"] << {"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, 
                                              "metric_column"=>"rx", "metric_id"=>metric_id}, 
                                             {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, 
                                              "metric_column"=>"tx", "metric_id"=>metric_id}], 
                                   "headline"=>metric.type_instance, 
                                   "cummulated"=>"false",
                                   "linegraph"=>"true"}
      end
    end
    config["Network"] = network unless network["single_graphs"].blank?

    #Memory
    _("MByte") #just for translation
    _("Memory") #just for translation
    memory = {"headline"=>'_("Memory")',
              "y_scale"=>1048567, 
              "y_label"=>'_("MByte")', 
              "y_max"=>nil,
              "y_decimal_places"=>0,
              "single_graphs"=>[]}
    lines = []
    metrics.each do |metric|
      if metric.type == "memory" && ["free", "used", "cached"].include?(metric.type_instance)
        metric_id = metric.id[metric.host.length+1..metric.id.length-1] #cut off host-id
        lines << {"label"=>metric.type_instance, "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>metric_id}
      end
    end
    memory["single_graphs"] << {"lines"=>lines,
                                "headline"=>"Memory", 
                                "cummulated"=>"true",
                                "linegraph"=>"false"} unless lines.blank?
    config["Memory"] = memory unless memory["single_graphs"].blank?

    #CPU
    _("Percent") #just for translation
    _("CPU") #just for translation
    cpu = {"headline"=>'_("CPU")',
           "y_scale"=>1, 
           "y_label"=>'_("Percent")', 
           "y_max"=>100,
           "y_decimal_places"=>0,
           "single_graphs"=>[]}
    graphs = {}
    metrics.each do |metric|
      if metric.plugin == "cpu" && ["idle", "user"].include?(metric.type_instance)
        lines = graphs[metric.plugin_instance] || []
        metric_id = metric.id[metric.host.length+1..metric.id.length-1] #cut off host-id
        lines << {"label"=>metric.type_instance, "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>metric_id}
        graphs[metric.plugin_instance] = lines
      end
    end
    graphs.each do |key, lines|
      cpu["single_graphs"] << {"lines"=>lines,
                               "headline"=>"CPU-" + key, 
                               "cummulated"=>"false",
                               "linegraph"=>"true"} unless lines.blank?
    end
    config["CPU"] = cpu unless cpu["single_graphs"].blank?

    # avoid multiple threads creating a config in parallel
    @@mutex.synchronize do
      f = File.open(filename, "w")
      f.write(config.to_yaml)
      f.close
    end
  end

  public

  #
  # translate headlines, labels,....
  #
  def self.translate_config_data(node)
    if node.is_a? Hash
      node.each do |key,data|
        node[key] = translate_config_data data
      end
    elsif node.is_a? Array
      counter = 0
      node.each do |data|
        node[counter] = translate_config_data data
        counter +=1
      end
    elsif node.is_a? String
      node = node.strip
      if node =~ /^_\(\"/ && node =~ /\"\)$/
        node = _(node[3..node.length-3]) #try to translate it
      end
    end
    return node
  end 

  #
  # reading configuration file
  #
  def self.parse_config(translate = false, path = nil)
    path = File.join(Graph.plugin_config_dir(), @@configuration_file ) if path == nil
    #create default configuration file
    Graph.create_config(path) unless File.exists?(path)

    #reading configuration file
    ret = YAML.load(File.open(path))
    if translate
      return translate_config_data(ret) 
    else
      return ret
    end
  end

  # initialize on element
  def initialize(group_id,value,limitcheck=true )
    raise InvalidParameters.new(:headline => "UNKNOWN") unless (value["headline"] && 
                                                                value["headline"].is_a?(String))
    raise InvalidParameters.new(:y_scale => "UNKNOWN")  unless (value["y_scale"] && 
                                                               (value["y_scale"].is_a?(String) || 
                                                                value["y_scale"].is_a?(Integer)))
    raise InvalidParameters.new(:y_label => "UNKNOWN")  unless (value["y_label"] && 
                                                                value["y_label"].is_a?(String))
    raise InvalidParameters.new(:y_max => "UNKNOWN")    if (value["y_max"] && 
                                                            !value["y_max"].is_a?(String) &&
                                                            !value["y_max"].is_a?(Integer))
    raise InvalidParameters.new(:y_decimal_places => "UNKNOWN")    unless (value["y_decimal_places"] && 
                                                                (value["y_decimal_places"].is_a?(String) || 
                                                                 value["y_decimal_places"].is_a?(Integer)))

    @group_name = group_id
    @headline = value["headline"]
    @y_scale = value["y_scale"]
    @y_label = value["y_label"]
    @y_max = value["y_max"]
    @y_decimal_places = value["y_decimal_places"]
    if limitcheck
      value["single_graphs"].each do |graph|
        graph["lines"].each do |line|
          line["limits"]["reached"] = check_limits(line["metric_id"], line["metric_column"], line["limits"])
        end
      end
    end
    @single_graphs = value["single_graphs"]
  end

  def self.find(what, limitcheck = true)
    #checking if collectd is running
    raise ServiceNotRunning.new('collectd') unless Metric.collectd_running?
    do_find(what, limitcheck)
  end

  #
  # find
  # Graph.find(:all, limitcheck)
  # Graph.find(id, limitcheck)
  # "id" could be the graph group (CPU, Disc) or the path of the collectd entry (metric_id)
  #      (e.g. cpu-0+cpu-system)
  # "limitcheck" checking if limit has been reached (default: true)
  #
  def self.do_find(what, limitcheck = true)
    config = parse_config(@@translate)
    return nil if config==nil

    unless what == :all
      config = config.delete_if {|key,value|
        found = key == what #checking for group
        unless found
          #checking for collectd entry
          value["single_graphs"].each{|graph|
            graph["lines"].each{|line|
              if line["metric_id"] == what           
                found = true
                break
              end
            }
            break if found
          }       
        end
        !found
      } 
    end

    ret = []

    config.each {|key,value|
      ret << Graph.new(key,value,limitcheck)
    }

    if what == :all || ret.blank?
      return ret    
    else
      Rails.logger.error "There are more results for #{what} -> #{ret.inspect} Taking the first one..." if ret.size > 1
      return ret.first
    end
  end

  #
  # find_limits
  # Graph.find_limits(metric_id, group_id=nil)
  # group_id: graph group (CPU, Disc). 
  # The first limit with the metric_id will be taken if group_id is nil.
  # metric_id:  collectd entry e.g. (cpu-0+cpu-system)
  #
  # return array of hashes of {"max"=>0, "min"=>0, "metric_column"=>nil} or nil
  #
  def self.find_limits(metric_id, group_id=nil )
    config = parse_config(@@translate) || {}
    limits = []
    config.each {|key,value|
      next if group_id != nil && key != group_id
      #checking for collectd entry
      value["single_graphs"].each{|graph|
        graph["lines"].each{|line|
          line["limits"]["metric_column"] = line["metric_column"] if line.has_key?("metric_column")
          limits << line["limits"] if line["metric_id"] == metric_id
        }
      }    
    }
    limits
  end

  #
  # save()
  # Saving graph definition to <plugin_config_dir>/<CONFIGURATION_FILE>
  #
  def save
    config = Graph.parse_config
    if config.has_key? group_name
      config[group_name]["single_graphs"] = single_graphs
    else
      raise "#{group_name} not found in configuration file"
    end
    # avoid race condition in writing the config
    @@mutex.synchronize do
      f = File.open(File.join(Graph.plugin_config_dir(), @@configuration_file), "w")
      f.write(config.to_yaml)
      f.close
    end
  end

  #returns a human readable value
  def id()
    @group_name
  end

  # converts the graph to xml
  def to_xml(opts={})
    xml = opts[:builder] ||= Builder::XmlMarkup.new(opts)
    xml.instruct! unless opts[:skip_instruct]
    xml.graph do
      xml.id group_name
      xml.headline headline
      xml.y_scale y_scale
      xml.y_label y_label
      xml.y_max y_max
      xml.y_decimal_places y_decimal_places
      xml.single_graphs(:type => :array) do
        single_graphs.each do |graph|
          xml.single_graph do
            xml.cummulated graph["cummulated"]
            xml.linegraph graph["linegraph"]
            xml.headline graph["headline"]
            xml.lines(:type => :array) do
              graph["lines"].each do |line|
                xml.line do
                  xml.metric_id line["metric_id"]
                  xml.metric_column(line["metric_column"]) if line.has_key?("metric_column")
                  xml.label line["label"]
                  xml.limits do
                    xml.max line["limits"]["max"] 
                    xml.min line["limits"]["min"]
                    xml.reached line["limits"]["reached"] if line["limits"].has_key? "reached"
                  end 
                end
              end
            end
          end
        end
      end
    end
  end

end
