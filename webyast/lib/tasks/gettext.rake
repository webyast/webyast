#
#  Copyright (c) 2012 Novell, Inc.
#  All Rights Reserved.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public License as
#  published by the Free Software Foundation; version 2.1 of the license.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with this library; if not, contact Novell, Inc.
#
#  To contact Novell about this file by physical or electronic mail,
#  you may find current contact information at www.novell.com

# gettext/HAML enhancements

# extend the HAML parser to extract plain text messages
# to support automatic translations (without need to mark the text with _())
namespace :gettext do
  task :haml_parser do
    require 'haml_parser'
  end
end

# 'gettext:find' sorts the messages alphabetically only when it is merging existing messages
# copying empty pot file from the template forces sorting even at the first run
namespace :gettext do
  task :create_pot_template do
     potfile = "locale/webyast-base.pot"
     template = "locale/webyast-base.pot.template"

    FileUtils.cp(template, potfile) unless File.exists?(potfile)
  end

  # monkeypatch for broken Gem.all_load_paths
  # see https://github.com/rubygems/rubygems/issues/171
  task :rubygems_fix do
    module Gem
      def self.all_load_paths
        []
      end
    end
  end
end

# extend the HAML parser before collecting the translatable texts
task :'gettext:find' => :'gettext:haml_parser'

# force message sorting even at the firt run (see the comments above)
task :'gettext:find' => :'gettext:create_pot_template'

# fix Gem.all_load_paths bug
task :'gettext:pack' => :'gettext:rubygems_fix'

