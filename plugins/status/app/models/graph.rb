#
# This class handles the graph configuration for the status module
# The yaml file is located in config/status_configuration.yaml
#
class Graph
  require 'yaml'

  attr_reader :group_name
  attr_reader :y_scale
  attr_reader :y_label
  attr_reader :single_graphs

  CONFIGURATION_FILE = "status_configuration.yaml"

  private

  # 
  # reading data from Metric
  #
  def read_data(id)
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
    data = read_data(id)
    limit_reached = false
    data.each do |key, values|
      if key == metric_column
        values.each do |date, value| 
          if limits.has_key?("max") && limits["max"].to_i > 0 && value && limits["max"].to_i < value/y_scale
            Rails.logger.info "Max #{limits['max']} for #{metric_id}(#{metric_column}) has been reached"
            limit_reached = true
          end 
          if limits.has_key?("min") && limits["min"].to_i > 0 && value && limits["min"].to_i > value/y_scale
            Rails.logger.info "Min #{limits['min']} for #{metric_id}(#{metric_column}) has been reached"
            limit_reached = true
          end 
          break if limit_reached
        end
      end
      break if limit_reached
    end
    return limit_reached
  end

  #
  # evalualte config directory of the status plugin
  #
  def self.plugin_config_dir()
    dir = "#{RAILS_ROOT}/config" #default
    Rails.configuration.plugin_paths.each do |plugin_path|
      if File.directory?(File.join(plugin_path, "status"))
        dir = plugin_path+"/status/config"
        break
      end
    end
    dir
  end

  public

  #
  # reading configuration file
  #
  def self.parse_config(path = nil)
    path = File.join(Graph.plugin_config_dir(), CONFIGURATION_FILE ) if path == nil

    #reading configuration file
    return YAML.load(File.open(path)) if File.exists?(path)
    return nil
  end

  # initialize on element
  def initialize(group_id,value,limitcheck=false)
    @group_name = group_id
    @y_scale = value["y_scale"]
    @y_label = value["y_label"]
    if limitcheck
      value["single_graphs"].each do |graph|
        graph["lines"].each do |line|
          line["limits"]["reached"] = check_limits(line["metric_id"], line["metric_column"], line["limits"])
        end
      end
    end
    @single_graphs = value["single_graphs"]
  end

  #
  # find 
  # Graph.find(:all, limitcheck)
  # Graph.find(id, limitcheck) 
  # "id" could be the graph group (CPU, Disc) or the path of the collectd entry (metric_id)
  #      (e.g. cpu-0+cpu-system)
  # "limitcheck" checking if limit has been reached (default: false)
  #
  def self.find(what, limitcheck = false)
    config = parse_config
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
    config = parse_config
    return nil if config==nil
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
    f = File.open(File.join(Graph.plugin_config_dir(), CONFIGURATION_FILE), "w")
    f.write(config.to_yaml)
    f.close
  end

  # converts the graph to xml
  def to_xml(opts={})
    xml = opts[:builder] ||= Builder::XmlMarkup.new(opts)
    xml.instruct! unless opts[:skip_instruct]
    xml.graph do
      xml.id group_name
      xml.y_scale y_scale
      xml.y_label y_label
      xml.single_graphs(:type => :array) do
        single_graphs.each do |graph|
          xml.single_graph do
            xml.cummulated graph["cummulated"]
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
                    xml.reached check_limits(line["metric_id"], line["metric_column"], line["limits"]) if line["limits"].has_key? "reached"
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
