class Status #< ActiveRecord::Base
  require 'scr'

  attr_accessor :data


  def to_xml(options = {})
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.status do
      @data.each_pair do |branch, n|
      #xml.branch
        leaf = @data["#{branch}"].split "|"
        leaf.each do |p|
          pair = p.split "=>"
          pair.each do |key, value|
            xml.tag!("#{pair[0]}", "#{pair[1]}")
          end
        end
      end
    end
  end

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

  #wieviele cpus?
  # creates several metrics for a defined period
  def collect_data(start=Time.now, stop=Time.now, data = %w{cpu memory disk})
#  def collect_data(start="16:18,07/02/2009", stop="16:19,07/02/2009", data=%w{cpu memory disk})
    unless @timestamp.nil?
      @metrics.each_pair do |m, n|
        @metrics["#{m}"][:rrds].each do |rrdb|
          value = fetch_metric("#{m}/#{rrdb}", start, stop)
          @data["#{m}"] = "#{@data["#{m}"]}|#{rrdb.chomp(".rrd")}=>#{value}"
         # @data["#{m}"]["#{rrdb}"] = fetch_metric("#{m}/#{rrdb}", start, stop)
        end
      end
    end
@data
  end

  # creates one metric for defined period
  def fetch_metric(rrdfile, start=Time.now, stop=Time.now)#, heigth=nil, width=nil)
    sum = 0.0
    counter = 1
    cmd = @scr.execute(["rrdtool", "fetch", "#{@datapath}/#{rrdfile}", "AVERAGE",\
                                     "--start"," #{start}", "--end", " #{stop}"])
    lines = cmd[:stdout].split "\n"
    lines.each do |l|
       if l =~ /\D*:\D*/
        pair = l.split ":"
        unless pair[1].include?("nan") # no valid measurement
          sum += pair[1].to_f
          counter += 1
        end
      end
    end
    sum/(counter-1) unless sum == 0
  end
end
