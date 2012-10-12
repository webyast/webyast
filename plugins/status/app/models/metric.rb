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
# Model over collectd data
#
# @author Bjoern Geuken <bgeuken@suse.de>
# @author Duncan Mac-Vicar P. <dmacvicar@suse.de>
# @author Stefan Schubert <schubi@suse.de>
#
require 'exceptions'
require 'graph'
require 'builder'

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
  require 'yaml'

  COLLECTD_BASE = "/var/lib/collectd"

  # path to the round robin database for this value
  attr_reader :path
  attr_reader :host
  attr_reader :plugin, :plugin_instance
  attr_reader :type, :type_instance
  # convenience, plugin and instance
  attr_reader :plugin_full
  attr_reader :type_full

  # like identifier, but to be used as a REST id
  # so / are replaced by +
  def id
    identifier.gsub("/", "+").gsub(".", "*")
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
    hosts = available_hosts
    return hosts.first if hosts.size==1 #there is only one host available
                                        #thats normally "WebYaST" defined in collectd.conf

    #there are more than one hosts entry in the collectd database. 
    #So lets try to get the right one....
    hostname = this_hostname    
    return case
    # if data exists for it, then this is the default
    when host_available?(hostname) then hostname    
    when !hosts.empty? then hosts.first
    else 
      #checking if collectd is running
      raise ServiceNotRunning.new('collectd') unless collectd_running?
      #ok, there is another error
      raise "Can't determine default host to read metric from"
    end
  end    
  
  # returns true if collectd daemon is running
  def self.collectd_running?
    #cannot run directly rccollectd status as it cannot run under non-root,
    # but because it is not fatal information and if someone hackly run process
    # which itself identify as collectd, then he runs into problems, but no
    # security problem occur
    ret = `pgrep -c -f /usr/sbin/collectd` # RORSCAN_ITL
    ret.to_i > 0
  end

  # available plugins
  def self.plugins
    Metric.find(:all).map { |x| x.plugin }
  end

  # avaliable databases for a host
  def self.rrd_files
    Dir.glob(File.join(COLLECTD_BASE, '**/*.rrd'))
  end
  
  # initialize with the path to the rrdb database
  def initialize(path=nil)
    @path = path
    # these values can be extracted from the file but we cache
    # them
    @host, @plugin, @plugin_instance, @type, @type_instance = Metric.parse_file_path(path) unless path.blank?

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

    host = "" if host.nil?
    plugin = "" if plugin.nil?
    plugin_instance = "" if plugin_instance.nil?
    type = "" if type.nil?
    type_instance = "" if type_instance.nil?
    
    return host, plugin, plugin_instance, type, type_instance
  end    
  
  # Finds metrics.
  #
  # Metric.find(:all)
  # Metric.find(:all, group => "cpu-1")
  # Metric.find(id)
  # Where id is host:group:name (whithout rrd extension)
  def self.find(what, opts={})
    return find_all if what == :all && opts.empty?
    case what
      when :all then opts.empty? ? find_all : find_multiple(opts)
      # in this case, the options are the first
      # parameter
      when Hash then find_multiple(what.merge(opts))
      when String
        find_multiple({:id => what}).first rescue nil
      else nil     
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
        raise InvalidParameters.new :key => key if not metric.respond_to?(key)
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
  
  # converts the metric to xml
  def to_xml(opts={})
    xml = opts[:builder] ||= Builder::XmlMarkup.new(opts)
    xml.instruct! unless opts[:skip_instruct]

    xml.metric do
      xml.id id
      xml.identifier identifier
      xml.host host
      xml.plugin plugin
      xml.plugin_instance plugin_instance
      xml.type type
      xml.type_instance type_instance
      line_id = id[host.length+1..id.length-1]  #remove hostname from id
      limits = Graph.find_limits(line_id)
      unless limits.blank?
        xml.limits(:type => :array) do
          limits.each do |limit|
            xml.limit() do
              xml.metric_column(limit["metric_column"]) 
              xml.max(limit["max"]) 
              xml.min(limit["min"])
            end
          end
        end 
      end

      # serialize data unless it is disabled
      unless opts.has_key?(:data) and !opts[:data]
        starttime = opts[:data]['starttime']
        interval = opts[:data]['interval']
        opts[:data].each do |col, values|
          next if col == "starttime"
          next if col == "interval"
          xml.value(:column => col, :start => starttime.to_i, :interval => interval ,:type => :hash) { values.sort.each { |x| xml.comment!(x[0].to_i.to_s) if Rails.env.development?; xml.value '"'+x[1].to_s+'"' } }
        end
      end
      
    end

  end

  #get last entry of rrd database
  def self.last_db_entry(file)
    `/bin/sh -c "LC_ALL=C /usr/bin/rrdtool last #{file}"` # RORSCAN_ITL ok, as long as no user input
  end

  
  # runs the rddtool on file with start time and end time
  #
  # You can pass start and stop options:
  # Metric.run_rrdtool(file, :start => t1, :stop => t2)
  #
  # default last 5 minutes from now
  def self.run_rrdtool(file, opts={})

    #checking if collectd is running
    raise ServiceNotRunning.new('collectd') unless collectd_running?

    #checking if systemtime is BEHIND the last entry of collectd. 
    #If yes, no data will be available.
    timestamp = last_db_entry(file)
    raise CollectdOutOfSyncError.new(timestamp) if Time.now < Time.at(timestamp.to_i)

    stop = opts.has_key?(:stop) ? opts[:stop] : Time.now
    start = opts.has_key?(:start) ? opts[:start] : stop - 300
    output = `/bin/sh -c "LC_ALL=C /usr/bin/rrdtool fetch #{file} AVERAGE --start #{start.to_i} --end #{stop.to_i}"` # RORSCAN_ITL as long as no user input
    raise output unless $?.exitstatus.zero?

    output
  end

  def self.read_metric_file(rrdfile, opts={})
    result = Hash.new
    
    output = run_rrdtool(rrdfile, opts)

    raise "Error running collectd rrdtool" if output =~ /ERROR/ or output.nil?
    
    line_count = 0
    result["starttime"] = 9.9e+99

    times = []
    labels = []
    output.each_line do |line|
      line.chomp!
      line_count += 1
      next if line.blank?

      # read the labels for the first line
      if line_count == 1
        labels = line.split(" ")
        # no labels, no data
        return {} if labels.empty?
        next
      end

      #Rails.logger.info "--> '#{line}'"
      
      time_str, values_str = line.split(":")
      time = Time.at(time_str.to_i)
      
      # store time to get the starttime and interval
      times << time

      #Rails.logger.info "--> '#{values_str}'"
      
      values = values_str.split(" ").map {|x| x == "nan" ? nil : x.to_f}

      values.each_with_index do |value, index|
#        Rails.logger.info "#{value} at #{index}"
        label = labels[index]
        result[label] = {} if not result.has_key?(label)
        result[label][time] = value
      end      
    end

    result["starttime"] = times.first

    # calculate the interval between elements
    if times.size > 1
      last = times.pop
      times.each_with_index do |time, index|
        result["interval"] = time.to_i - last.to_i
        last = time
      end
    end
    return result
    
  end
  
end
