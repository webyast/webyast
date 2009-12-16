# This class collects progress data of a background process

class BackgroundStatus

  attr_reader	  :status,
		  :progress,
		  :subprogress

  def initialize(stat = 'unknown', progress = 0, subprogress = -1, &block)
    @status = stat
    @progress = progress
    @subprogress = subprogress
    @callback = block_given? ? block : nil
  end

  def status=(stat)
    if @status != stat
      @status = stat
      trigger_callback
    end
  end

  def progress=(p)
    if @progress != p
      @progress = p
      trigger_callback
    end
  end

  # returns -1 if there is no subprogress
  def subprogress=(s)
    if @subprogress != s
      @subprogress = s
      trigger_callback
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

  private

  def trigger_callback
    @callback.try(:call)
  end

end
