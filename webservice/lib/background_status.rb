#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

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
