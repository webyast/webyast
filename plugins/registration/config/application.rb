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

require 'rails/all'
require 'fast_gettext'

if defined?(Bundler)
  Bundler.require *Rails.groups(:assets) if defined?(Bundler)
end

module Registration
  class Application < Rails::Application
    config.assets.enabled = true
    config.assets.version = '1.0'

    # precompile all webyast-* assets from plugins
    config.assets.precompile += ['webyast-*']

    # Generate digests for assets URLs.
    config.assets.digest = true
  end
end
