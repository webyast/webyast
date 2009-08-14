# = Base system model
class Basesystem

  # steps needed by base system
  attr_accessor   :steps
  # current step to finish
  attr_accessor   :current

  STEPS_FILE = File.join(File.dirname(__FILE__),"..","..","config","basesystemsteps.conf")
  CURRENT_STEP_FILE = File.join(File.dirname(__FILE__),"..","..","var","currentstep")
  END_STRING = "FINISH"

  def initialize
    @steps = Array.new
    #load steps configuration    
    fh = File.new(STEPS_FILE, "r")
    while (line = fh.gets)
      steps.push(line.chomp)
    end
    fh.close
  end

  def Basesystem.find
    ret = Basesystem.new        
    unless File.exist?(CURRENT_STEP_FILE)
      ret.current = ret.steps.empty? ? END_STRING : ret.steps[0]
    else
      fh = File.new(CURRENT_STEP_FILE,"r")
      ret.current = fh.gets
      fh.close
      if ret.steps.include(ret.current) #invalid step
        Rails.logger.warn "invalid step in current"
        ret.current = END_STRING
      end
    end
    Rails.logger.info "Current step is set to #{ret.current}"
    return ret
  end

  def save
    #check if current is valid
    unless @steps.include?(@current) or @current == END_STRING
      #invalid current value
      return false
    end
    cur = File.new(CURRENT_STEP_FILE, "w")
    cur.puts @current
    cur.close
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.basesystem do
      xml.tag!(:current, @current)
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end
end
