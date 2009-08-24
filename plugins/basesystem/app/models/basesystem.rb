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

  def self.steps_file
    STEPS_FILE
  end

  def self.current_step_file
    CURRENT_STEP_FILE
  end

  def self.end_string
    END_STRING
  end

  #Gets instance of Basesystem with initialized steps queue.
  def initialize
    @steps = Array.new
    @current = ""
    #load steps configuration    
    fh = File.new(STEPS_FILE, "r")
    # file => read lines => remove line separators => only non-blank
    @steps = fh.lines.collect { |line| line.chomp }.delete_if { |line| line.length == 0 }
    fh.close
  end

  #Gets instance of Basesystem with initialized steps queue and current step
  def Basesystem.find
    base = Basesystem.new
    base.load_current_step
    unless base.current_step_valid?
      base.restart_setup
    end
    Rails.logger.info "Current step is set to #{base.current}"
    return base
  end

  def finish
    @current = END_STRING
  end

  def current_step_valid?
    if @steps.include?(@current) or @current == END_STRING
      true
    else
      Rails.logger.warn "Invalid step in current"
      false
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
      @current = fh.gets.chomp
      fh.close
    else
      @current = @steps[0]
    end
  end

  def save_current_step
    fh = File.new(CURRENT_STEP_FILE, "w")
    fh << @current
    fh.close
  end

  #stores to system Basesystem settings
  def save
    #check if current is valid
    if not current_step_valid?
      #invalid current value
      return false
    end
    save_current_step
  end

  #serialize part of Basesystem to xml
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.basesystem do
      xml.current  @current
      xml.steps({:type => "array"}) do
        @steps.each do
          |step|
          xml.step step
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

