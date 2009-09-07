#
# Model over collectd data
#
# @author Bjoern Geuken <bgeuken@suse.de>
# @author Duncan Mac-Vicar P. <dmacvicar@suse.de>
# @author Stefan Schubert <schubi@suse.de>
#
require 'scr'
require 'yaml'

#
# This class acts as a model for metrics provided by collectd
# each round robin database
#
# By default the model operates in the current host, or in the
# first available one, unless overriden by the :host option
#
# each value has an identifier based on
# host, plugin, plugin instance, type and type instance
# See http://collectd.org/wiki/index.php/Naming_schema
#
# for the naming schema of a metric
# metrics = Metric.find(:all, :plugin => /cpu/)
# metrics.each do |metric|
#   metric.type
#   metric.type_instance
#   metric.plugin
#   metric.plugin_instance
#   metric.host
#   metric.data(:stop => Time.now - 5000)
# end
#
class Metric

  COLLECTD_BASE = "/var/lib/collectd"

  # path to the round robin database for this value
  attr_reader :path
  attr_reader :host
  attr_reader :plugin, :plugin_instance
  attr_reader :type, :type_instance
  # convenience, plugin and instance
  attr_reader :plugin_full
  attr_reader :type_full

  # alias for identifier
  def id
    identifier
  end
  
  def identifier
    [host, plugin_full, type_full].join('/')
  end

  # plugin and plugin instance ie: cpu-0
  def plugin_full
    return plugin if plugin_instance.blank?      
    "#{plugin}-#{plugin_instance}"
  end

  # type and type instance, ie: memory-free
  def type_full
    return type if type_instance.blank?      
    "#{type}-#{type_instance}"
  end
  
  # returns available hosts for which metrics are collected
  def self.available_hosts
    Dir.glob(File.join(COLLECTD_BASE, "*")).reject{|x| not File.directory?(x) }.map{|x| File.basename(x) }
  end

  # whether there is data available for a given host
  def self.host_available?(host)
    available_hosts.include?(host)
  end

  # returns the hostname of the running
  # host or nil if not available
  def self.this_hostname
    Socket.gethostbyname(Socket.gethostname).first rescue nil
  end
    
  # what host should be used if host is not
  # specified
  #
  # we try to use the running system hostname
  # or the first hostname with data available
  def self.default_host
    # try to get the real hostname
    hostname = this_hostname    
    hosts = available_hosts
    return case
    # if data exists for it, then this is the default
    when host_available?(hostname) then hostname    
    when !hosts.empty? then hosts.first
    else raise "Can't determine default host to read metric from"
    end
  end    
  
  # returns true if collectd daemon is running
  def self.collectd_running?
    ret = Scr.instance.execute(["/usr/sbin/rccollectd", "status"])
    ret[:exit].zero?
  end

  #
  def self.plugins
    Metric.find(:all).map { |x| x.plugin }
  end

  # avaliable databases for a host
  def self.rrd_files
    Dir.glob(File.join(COLLECTD_BASE, '**/*.rrd'))
  end
  
  # initialize with the path to the rrdb database
  def initialize(path)
    @path = path
    # these values can be extracted from the file but we cache
    # them
    @host, @plugin, @plugin_instance, @type, @type_instance = Metric.parse_file_path(path)
  end

  # parses the host, plugin, plugin_instance, type and type_instance
  # from the file name
  def self.parse_file_path(path)
    type_full = File.basename(path, '.rrd')
    plugin_instance_path = File.dirname(path)
    plugin_full = File.basename(plugin_instance_path)
    host_path = File.dirname(plugin_instance_path)
    host = File.basename(host_path)

    type, type_instance = type_full.split('-', 2)
    plugin, plugin_instance = plugin_full.split('-', 2)
    
    return host, plugin, plugin_instance, type, type_instance
  end    
  
  # Finds metrics.
  #
  # Metric.find(:all)
  # Metric.find(:all, group => "cpu-1")
  # Metric.find(id)
  # Where id is host:group:name (whithout rrd extension)
  def self.find(what, opts={})
    case what
    when :all then opts.empty? ? find_all : find_multiple(opts)
    # in this case, the options are the first
    # parameter
    when Hash
    else find_multiple(what.merge(opts))
    end
  end

  # find all values
  def self.find_all
    ret = []
    rrd_files.each do |path|
      ret << Metric.new(path)
    end
    ret
  end
    
  def self.find_multiple(opts)
    ret = []

    # think how to factor this out
    opts[:host] = default_host if not opts.has_key?(:host)
    
    all = Metric.find(:all)
    all.each do |metric|     
      matched = true
      # match each attribute passed in opts
      opts.each do |key, val|
        raise "Unknown attribute #{key}" if not metric.respond_to?(key)
        # if the val is a regexp we do different matching
        if val.is_a?(Regexp)
          matched = false if not metric.send(key) =~ val
        else
          matched = false if metric.send(key) != val
        end
      end
      # go to next value if this does not match
      next if not matched
      ret << metric
    end
    ret
  end

  # returns data for a given period of time
  # range can be specified with the :start and
  # :stop options
  #
  # default last 5 minutes from now
  #
  # result is a hash of the type:
  # { column1 => { time1 => value1, time2 => value2, ...}, ...}
  #
  def data(opts={})
    Metric.read_metric_file(path, opts)
  end
  
  # runs the rddtool on file with start time and end time
  #
  # You can pass start and stop options:
  # Metric.run_rrdtool(file, :start => t1, :stop => t2)
  #
  # default last 5 minutes from now
  def self.run_rrdtool(file, opts={})
    stop = opts.has_key?(:stop) ? opts[:stop] : Time.now
    start = opts.has_key?(:stop) ? opts[:stop] : stop - 300

    cmd = IO.popen("rrdtool fetch #{file} AVERAGE --start #{start.strftime("%H:%M,%m/%d/%Y")} --end #{stop.strftime("%H:%M,%m/%d/%Y")}")
    output = cmd.read
    cmd.close
    output
  end

  def self.read_metric_file(rrdfile, opts={})
    result = Hash.new
    output = run_rrdtool(rrdfile, opts)

    raise "Error running collectd rrdtool" if output =~ /ERROR/ or output.nil?

    labels=""
    output = output.gsub(",", ".") # translates eg. 1,234e+07 to 1.234e+07
    lines = output.split "\n"

    # set label names
    lines[0].each do |l|
      if l =~ /\D*/
        labels = l.split " "
      end
    end
    unless labels.blank?
      # set values for each label and time
      # evaluates interval and starttime once for each metric (not each label)
      nexttime = 9.9e+99
      result["starttime"] = 9.9e+99
      lines.each do |l| # each time
        next if l.blank?
        if l =~ /\d*:\D*/
          pair = l.split ":"
          values = pair[1].split " "
          column = 0
          values.each do |v| # each label
            unless result["interval"] # already defined?
              # get the least distance to evaluate time interval
              if pair[0].to_i < result["starttime"].to_i
                result["starttime"] = pair[0].to_i
              elsif pair[0].to_i < nexttime and pair[0].to_i > result["starttime"].to_i
                nexttime = pair[0].to_i
              end
            end
            v = "invalid" if v == "nan" #store valid values only
            result[labels[column]] ||= Hash.new
            result[labels[column]][pair[0]] = v
            column += 1
          end
        end
      end
      result["interval"] = nexttime.to_i - result["starttime"].to_i if result["interval"].nil?
      return result
    else
      raise "error reading data from rrdtool"
    end
  end
  
end
