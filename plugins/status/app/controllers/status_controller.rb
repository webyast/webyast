include ApplicationHelper

class HashWithoutKeyConversion < Hash; end
HashWithoutKeyConversion.class_eval do
   def self.unrename_keys(params)
      case params.class.to_s
        when "Hash"
          params.inject({}) do |h,(k,v)|
            h[k.to_s] = unrename_keys(v)
            h
          end
        when "Array"
          params.map { |v| unrename_keys(v) }
        else
          params
         end
  end
end

class StatusController < ApplicationController
  before_filter :login_required

  private

  def create_limit(status, label = "", limits = {})
    if status.is_a? Hash
      status.each do |key, value|
        if value.is_a?(Hash)
          unless label.blank?
            next_label = label+ "/" + key
          else
             next_label = key
          end
          create_limit(value, next_label, limits)
        else
          limits[label] ||= { "max" => 0, "min" => 0 }
          limits[label]["max"] = value.to_f if key == "max"
          limits[label]["min"] = value.to_f if key == "min"
        end
      end
    end
    return limits
  end

  public

  # POST /status
  # POST /status.xml
  def create
    permission_check("org.opensuse.yast.system.status.writelimits")      

    #find the correct plugin path for the config file
    plugin_config_dir = "#{RAILS_ROOT}/config" #default
    Rails.configuration.plugin_paths.each do |plugin_path|
      if File.directory?(File.join(plugin_path, "status"))
        plugin_config_dir = plugin_path+"/status/config"
        Dir.mkdir(plugin_config_dir) unless File.directory?(plugin_config_dir)
        break
      end
    end
    limits = Hash.new
    pa = HashWithoutKeyConversion.from_xml(params["status"]["limits"])
    limits = create_limit(pa["limits"])
    f = File.open(File.join(plugin_config_dir, "status_limits.yaml"), "w")
    f.write(limits.to_yaml)
    f.close

    @status = Status.new
    # use now if time is not valid
    stop = params[:stop].blank? ? Time.now : Time.at(params[:stop].to_i)
    start = params[:start].blank? ? stop - 300 : Time.at(params[:start].to_i)
    @status.collect_data(start, stop, params[:data])
    render :show
  end

  # GET /status
  # GET /status.xml
  def index
    show
  end

  # GET /status/1
  # GET /status/1.xml
  def show
    bgr = params['background']

    # at least 'stop' parameter must be present if background mode is used,
    # needed for identifying the request when polling for the result
    raise InvalidParameters.new(:stop => 'MISSING') if bgr && params[:stop].blank?

    Rails.logger.info "Reading status in background" if bgr

    permission_check("org.opensuse.yast.system.status.read")
    @status = Status.new
    stop = params[:stop].blank? ? Time.now : Time.at(params[:stop].to_i)
    start = params[:start].blank? ? stop - 300 : Time.at(params[:start].to_i)
    @status.collect_data(start, stop, params[:data], bgr)
  end
end
