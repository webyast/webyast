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
# metrics = Metric.find(:all, group => /cpu/)
# metrics.each do |metric|
#   metric.name
#   metric.group
#   metric.host
#   metric.data(:stop => Time.now - 5000)
# end
#
#
class Metric

  COLLECTD_BASE = "/var/lib/collectd"

  attr_accessor :host, :group, :name
  
  def path
    File.join(Metric.host_directory(host), group, name + '.rrd')
  end

  def id
    [host, group, name].join('/')
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
  
  # the directory where we are gathering data from
  # normally is the directory corresponding to *this*
  # host. If there are more than one, we take the first
  # one or the one given
  #
  # Metrics.host_directory
  # Metrics.host_directory("foo.com")
  #
  def self.host_directory(host=Metric.default_host)
    File.join(COLLECTD_BASE, host)
  end

  # returns true if collectd daemon is running
  def self.collectd_running?
    ret = Scr.instance.execute(["/usr/sbin/rccollectd", "status"])
    ret[:exit].zero?
  end

  # returns the available metric groups
  def self.available_groups(host=Metric.default_host)
    Dir.glob(File.join(host_directory(host), '*')).reject{|x| not File.directory?(x) }.map{|x| File.basename(x) }
  end

  # returns the available metrics names for a group
  # that is the rrd file name without the extension
  def self.available_metrics(group, host=Metric.default_host)
    Dir.glob(File.join(host_directory(host), group, '*')).reject{|x| not File.file?(x) }.map{|x| File.basename(x).chomp('.rrd') }
  end

  # Finds metrics.
  #
  # Metric.find(:all)
  # Metric.find(:all, group => "cpu-1")
  # Metric.find(id)
  # Where id is host:group:name (whithout rrd extension)
  def self.find(what, opts={})
    case what
    when :all then find_multiple(opts)
    # in this case, the options are the first
    # parameter
    when Hash
    else find_multiple(what.merge(opts))
    end
  end

  def self.find_multiple(opts)
    ret = []
    current_host = opts[:host] || default_host
    available_hosts.each do |host|
      # if host is specified, only use that
      # host
      next if host != current_host
      available_groups(current_host).each do |group|
        # filter by group
        case opts[:group]
        when Regexp
          next if not group =~ opts[:group]
        when String
          next if group != opts[:group]
        end
        available_metrics(group, current_host).each do |metric_name|
          # filter by name
          case opts[:name]          
          when Regexp then next if not metric_name =~ opts[:name]
          when String then next if metric_name != opts[:name]
          end

          # instantiate the object
          metric = Metric.new
          metric.host = current_host
          metric.name = metric_name
          metric.group = group
          ret << metric
        end
      end
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
