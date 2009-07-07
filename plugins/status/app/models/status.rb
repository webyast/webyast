class Status < ActiveRecord::Base
  require 'scr'

  attr_accessor :data

  def initialize
    @scr = Scr.instance
    @health_status = nil
    @data = Hash.new
    @cpu=""
    @memory=""
    @timestamp = Time.now #nil
#    @collectd_base_dir = "/var/lib/collectd/"
    @datapath = set_datapath
    @metrics = available_metrics
  end

  def start_collectd
    cmd = @scr.execute(["collectd"])
    @timestamp = Time.now
  end

  def stop_collectd
    cmd = @scr.execute(["killall", "collectd"])
    @timestamp = nil
  end

  # set path of stored rrd files, default: /var/lib/collectd/$host.$domain
  def set_datapath(path=nil)
    default = "/var/lib/collectd/"
    unless path.nil?
      @datapath = path.chomp("/")
    else # set default path
      host = @scr.execute(["hostname"])
      domain = @scr.execute(["domainname"])
      @datapath = "#{default}#{host[:stdout].strip}.#{domain[:stdout].strip}"
    end
    @datapath
  end

  def available_metrics
    metrics = Hash.new
    cmd = Scr.instance.execute(["ls", "#{@datapath}"])
    cmd[:stdout].split(" ").each do |l|
      files = Scr.instance.execute(["ls", "#{@datapath}/#{l}"])
      metrics["#{l}"] = { :rrds => files[:stdout].split(" ")}
    end
    metrics
  end

  def available_metric_files
    cmd = @scr.execute(["ls", "#{@datapath}.."])
    lines = cmd[:stdout].split "\n"
  end

  def determine_status
  end

  def draw_graph(heigth=nil, width=nil)
  end

  # creates several metrics for a defined period
  def collect_data(start=Time.now, stop=Time.now, data = %w{cpu memory disk})
    result = Hash.new
    unless @timestamp.nil? # collectd not started
      @metrics.each_pair do |m, n|
        @metrics["#{m}"][:rrds].each do |rrdb|
           result["#{rrdb}".chomp(".rrd")] = fetch_metric("#{m}/#{rrdb}", start, stop)
        end
        @data["#{m}"] = result
        result = Hash.new
      end
    end
    @data
  end

  # creates one metric for defined period
  def fetch_metric(rrdfile, start=Time.now, stop=Time.now)#, heigth=nil, width=nil)
    sum = 0.0
    counter = 0
    result = Hash.new#Array.new
    cmd = @scr.execute(["rrdtool", "fetch", "#{@datapath}/#{rrdfile}", "AVERAGE",\
                                     "--start"," #{start}", "--end", " #{stop}"])
    lines = cmd[:stdout].split "\n"
    lines[0].each do |l|
      if l =~ /\D*/
        labels = l.split " "
        collumn = 1
        labels.each do
          lines.each do |l|
            if l =~ /\d*:\D*/  ####
              pair = l.split " "
              unless pair[collumn].include?("nan") # no valid measurement
                sum += pair[collumn].to_f
                counter += 1
              end
            end
          end
          result[labels[collumn-1]] = sum/(counter) unless counter == 0
          sum, counter = 0.0, 0
          collumn += 1
        end
      end
    end
    result
  end
end
