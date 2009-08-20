# = Base system model
# Provides access to basic system settings module queue. Provides and updates
# currently reached state in queue.
class Basesystem

  # steps needed by base system
  attr_accessor   :steps
  # current step to finish
  attr_accessor   :current

  # path to file which defines module queue
  STEPS_FILE = File.join(File.dirname(__FILE__),"..","..","config","basesystemsteps.conf")
  # path to file which store module then is next in queue or END_STRING if all steps is done
  CURRENT_STEP_FILE = File.join(File.dirname(__FILE__),"..","..","var","currentstep")
  # keyword that signalize finish of all steps
  END_STRING = "FINISH"

  #Gets instance of Basesystem with initialized steps queue.
  def initialize
    @steps = Array.new
    @current = nil
    #load steps configuration    
    fh = File.new(STEPS_FILE, "r")
    # file => read lines => remove line separators => only non-blank
    fh.lines.collect { |line| chomp line }.delete_if { |line| length line == 0 }
    fh.close
  end

  def current_step_valid?
    if @steps.include?(@current) or @current == END_STRING
      :true
    else
      Rails.logger.warn "invalid step in current"
      :false
    end
  end

  def restart_setup
    Rails.logger.warn "Restarting basic system setup"
    # allow empty list of setup steps
    @current = @steps[0] or END_STRING
  end

  def load_current_step
    if File.exist?(CURRENT_STEP_FILE)
      fh = File.new(CURRENT_STEP_FILE,"r")
      @current = fh.gets
      fh.close
    else
      @current = nil
    end
  end

  def save_current_step
    fh = File.new(CURRENT_STEP_FILE, "w")
    fh << @current
    fh.close
  end

  def next_step
    if current_step_valid?
      @current = @steps[@steps.index(@current)+1] or END_STRING
    end
  end

  #Gets instance of Basesystem with initialized steps queue and current step
  def Basesystem.find
    base = Basesystem.new
    base.load_current_step
    unless base.current_step_valid?
      base.restart_setup
    end
    base
  end

  #stores to system Basesystem settings
  #goes to the next step
  def step_completed
    unless current_step_valid?
      return false
    end
    next_step
    save_current_step
  end

  #serialize part of Basesystem to xml
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.basesystem do
      xml.current_step @current
      xml.setup_steps({:type => "array"}) do
        @steps.each do |step|
          xml.setup_step step
        end
      end
    end
  end

  #serialize part of Basesystem to json
  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end
end
