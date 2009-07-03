class Status
  require 'scr'

  def to_xml(options = {})
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.status do
       xml.tag!(:cpu, @cpu)
       xml.tag!(:memory, @memory)
    end
  end

  def initialize
    @scr = Scr.instance
    @health_status = nil
    @data = Hash.new
    @cpu=""
    @memory=""
    @timestamp = Time.now #nil
    @datapath = "/var/lib/collectd/g192.suse.de/" # #{host.chomp("/")}/" # <--
  end

  def start_collectd
    cmd = @scr.execute(["collectd"])
    @timestamp = Time.now
  end

  def stop_collectd
    cmd = @scr.execute(["killall", "collectd"])
    @timestamp = nil
  end

  def set_datapath(path)
    @datapath = path
  end

  def reset_datapath(path)
    @datapath = "/var/lib/collectd/#{host}"
  end

  def available_metrics
    metrics = Hash.new
    cmd = Scr.instance.execute(["ls", "#{@datapath}"])
    cmd[:stdout].split(" ").each do |l|
      files = Scr.instance.execute(["ls", "#{@datapath}#{l}"])
      metrics["#{l}"] = { :rrds => files[:stdout].split(" ")}
    end
    metrics
  end

  def available_metric_files
    cmd = @scr.execute(["ls", "#{@datapath}.."])
    lines = cmd[:stdout].split "\n"
  end

  def update
  end

  def determine_status
  end

  def draw_graph(heigth=nil, width=nil)
  end

  #wieviele cpus?
  def collect_data(start=Time.now, stop=Time.now, data = %w{cpu memory disk})
#  def collect_data(start="16:18,07/02/2009", stop="16:19,07/02/2009", data=%w{cpu memory disk})
    unless @timestamp.nil?
      data.each do |d|
        case d
          when "cpu"
#            @cpu = fetch_metric("cpu-0/cpu-idle.rrd", "16:18,07/02/2009", "16:19,07/02/2009")
            @cpu = fetch_metric("cpu-0/cpu-idle.rrd", start, stop)
          when "memory"
#            @memory = fetch_metric("memory/memory-free.rrd", "16:18,07/02/2009", "16:19,07/02/2009")
            @memory = fetch_metric("memory/memory-free.rrd", start, stop)
          when "disk"
            #fetch_metric
        end
      end
    end
  end

  def fetch_metric(rrdfile, start=Time.now, stop=Time.now)#, heigth=nil, width=nil)
    sum = 0.0
    counter = 1
    cmd = @scr.execute(["rrdtool", "fetch", "#{@datapath}#{rrdfile}", "AVERAGE",\
                                     "--start"," #{start}", "--end", " #{stop}"])
    lines = cmd[:stdout].split "\n"
    lines.each do |l|
      l.to_s.strip
      unless l.blank? or l.include?("value")
        pair = l.split ":"
        unless pair[1].include?("nan") # no valid measurement
          sum += pair[1].to_f
          counter += 1
        end
      end
    end
    sum/(counter-1)
  end
end
