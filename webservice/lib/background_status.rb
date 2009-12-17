# This class collects progress data of a background process

class BackgroundStatus

  # use Observable design pattern for reporting changes
  include Observable

  attr_reader	  :status,
		  :progress,
		  :subprogress

  def initialize(stat = 'unknown', progress = 0, subprogress = -1)
    @status = stat
    @progress = progress
    @subprogress = subprogress
  end

  def status=(stat)
    if @status != stat
      changed
      @status = stat
      notify_observers self
    end
  end

  def progress=(p)
    if @progress != p
      changed
      @progress = p
      notify_observers self
    end
  end

  # returns -1 if there is no subprogress
  def subprogress=(s)
    if @subprogress != s
      changed
      @subprogress = s
      notify_observers self
    end
  end

  def to_xml(options = {})
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.tag! :background_status do
      xml.tag!(:status, @status)
      xml.tag!(:progress, @progress.to_i, {:type => "integer"} )
      xml.tag!(:subprogress, @subprogress.to_i, {:type => "integer"})
    end
  end

end
