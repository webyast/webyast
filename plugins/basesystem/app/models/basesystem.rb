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
    #load steps configuration    
    fh = File.new(STEPS_FILE, "r")
    while (line = fh.gets)
      steps.push(line.chomp)
    end
    fh.close
  end

  #Gets instance of Basesystem with initialized steps queue and current step
  def Basesystem.find
    ret = Basesystem.new        
    unless File.exist?(CURRENT_STEP_FILE)
      ret.current = ret.steps.empty? ? END_STRING : ret.steps[0]
    else
      fh = File.new(CURRENT_STEP_FILE,"r")
      ret.current = fh.gets.chomp
      fh.close
      if ret.steps.include?(ret.current) #invalid step
        Rails.logger.warn "invalid step in current"
        ret.current = END_STRING
      end
    end
    Rails.logger.info "Current step is set to #{ret.current}"
    return ret
  end

  def finish
    @current = END_STRING
  end

  #stores to system Basesystem settings
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
