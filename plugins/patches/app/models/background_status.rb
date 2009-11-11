# This class collects progress data of a background process

class BackgroundStatus

  attr_writer	  :status,
		  :progress,
		  :subprogress

  def initialize(stat = 'unknown', progress = 0, subprogress = nil)
    @status = stat
    @progress = progress
    @subprogress = subprogress
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
