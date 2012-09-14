#--
# Copyright (c) 2009-2010 Novell, Inc.
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

class TerminalController < ApplicationController

private

  # returns true if shellinabox daemon is running
  def shellinabox_running?
    #cannot run directly rcshellinabox status as it cannot run under non-root,
    # but because it is not fatal information and if someone hackly run process
    # which itself identify as shellinabox, then he runs into problems, but no
    # security problem occur
    ret = `/bin/ps xaf | /usr/bin/grep '/usr/bin/shellinaboxd' | /usr/bin/grep -vc 'grep'` # RORSCAN_ITL
    ret.to_i > 0
  end

public

  def index
    # No permission check is needed here, the terminal runs at a different port (4200)
    # and the service is provided by shellinabox package, Webyast is just an UI wrapper.
    # User can connect to https://<host>:4200 manually anyway.

    unless shellinabox_running?
      flash[:error] = _("Terminal service is not running. Please start with: 'rcshellinabox start'")
      redirect_to :controller => :controlpanel, :action => :index
    end
  end

end

