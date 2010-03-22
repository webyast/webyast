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

  # avoid race conditions when creating the config file
  # at background - allow only one thread writing it
  #
  @@mutex = Mutex.new

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
    disk = {"y_scale"=>1073741824, 
            "y_label"=>"GByte", 
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
                                   "cummulated"=>"true"}
      end
    end
    config["Disk"] = disk unless disk["single_graphs"].blank?
    
    #Network
    network = {"y_scale"=>1, 
               "y_label"=>"MByte", 
               "single_graphs"=>[]}
    metrics.each do |metric|
      if metric.type == "if_packets" && metric.type_instance.start_with?("eth")
        metric_id = metric.id[metric.host.length+1..metric.id.length-1] #cut off host-id
        network["single_graphs"] << {"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, 
                                              "metric_column"=>"rx", "metric_id"=>metric_id}, 
                                             {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, 
                                              "metric_column"=>"tx", "metric_id"=>metric_id}], 
                                   "headline"=>metric.type_instance, 
                                   "cummulated"=>"false"}
      end
    end
    config["Network"] = network unless network["single_graphs"].blank?

    #Memory
    memory = {"y_scale"=>1048567, 
              "y_label"=>"MByte", 
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
                                "cummulated"=>"true"} unless lines.blank?
    config["Memory"] = memory unless memory["single_graphs"].blank?

    #CPU
    cpu = {"y_scale"=>1, 
           "y_label"=>"Percent", 
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
                               "cummulated"=>"false"} unless lines.blank?
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
  # reading configuration file
  #
  def self.parse_config(path = nil)
    path = File.join(Graph.plugin_config_dir(), CONFIGURATION_FILE ) if path == nil
    #create default configuration file
    Graph.create_config(path) unless File.exists?(path)

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

  # just a short cut for accessing the singleton object
  def self.bm
    BackgroundManager.instance
  end

  # create unique id for the background manager
  def self.id(what)
    "system_status_#{what}"
  end

  def self.find(what, limitcheck = false, opts = {})
    background = opts[:background]

    # background reading doesn't work correctly if class reloading is active
    # (static class members are lost between requests)
    if background && !bm.background_enabled?
      Rails.logger.info "Class reloading is active, cannot use background thread (set config.cache_classes = true)"
      background = false
    end

    if background
      proc_id = id(what)
      if bm.process_finished? proc_id
        Rails.logger.debug "Request #{proc_id} is done"
        return bm.get_value proc_id
      end

      running = bm.get_progress proc_id
      if running
        Rails.logger.debug "Request #{proc_id} is already running: #{running.inspect}"
        return [running]
      end

      bm.add_process proc_id
      Rails.logger.info "Starting background thread for reading status..."

      # read the status in a separate thread
      Thread.new do
        res = do_find what, limitcheck, bm
        bm.finish_process(proc_id, res)
      end

      return [ bm.get_progress(proc_id) ]
    else
      return do_find(what, limitcheck)
    end
  end

  #
  # find
  # Graph.find(:all, limitcheck)
  # Graph.find(id, limitcheck)
  # "id" could be the graph group (CPU, Disc) or the path of the collectd entry (metric_id)
  #      (e.g. cpu-0+cpu-system)
  # "limitcheck" checking if limit has been reached (default: false)
  #
  def self.do_find(what, limitcheck = false, bg = nil)
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

    # for reporing the progress
    idx = 0
    len = config.size

    config.each {|key,value|
      if !bg.nil?
        bg.update_progress id(what) do |bs|
          bs.progress = (idx.to_f/len*100).to_i
          Rails.logger.info "Reading status: progress: #{bs.progress}%%"
        end
      end

      ret << Graph.new(key,value,limitcheck)
      idx += 1
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
    # avoid race condition in writing the config
    @@mutex.synchronize do
      f = File.open(File.join(Graph.plugin_config_dir(), CONFIGURATION_FILE), "w")
      f.write(config.to_yaml)
      f.close
    end
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
