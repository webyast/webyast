#--
# Webyast Webclient framework
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

require "tempfile"
#require "jsmin"

vars = ['JSMIN', 'JAVASCRIPTS_PATH', 'MIN']

JSMIN = File.join(RAILS_ROOT, '/lib/jsmin.rb')
JAVASCRIPTS_PATH = "#{RAILS_ROOT}/public/javascripts"
MIN = "#{RAILS_ROOT}/public/javascripts/min"

def minify(list, output)
   tmp = Tempfile.open('all')
   list.each {|file| open(file) {|f| tmp.write(f.read) } }
   tmp.rewind

   sh "ruby #{JSMIN} < #{tmp.path} > #{output}"
end

#"jquery-effects.min.js", "jquery.tinysort.js", "jquery.tipsy.js", "firewall.helper.js"]
namespace :js do
  directory MIN
  javascripts = ["jquery-1.4.2.js", "jquery.query.js", "jquery.timers.js", "jquery.ui.custom.js", "jquery.validate.js", "validation.js",
        "jqbrowser-compressed.js", "jquery.badbrowser.js", "yast.widgets.js", "yast.helpers.js", "jquery.activity.js", "notifier.js",
        "browser_fixes.js", "jquery.quicksearch.js", "digitalspaghetti.password.js", "script.js",
        "jquerytimer.js","jquerySessionTimeout.js", "jquery.blockUI.js", "jqueryDisableOnSubmit.js",
        "jquery-effects.min.js", "jquery.tinysort.js", "jquery.tipsy.js", "webyast-firewall.js", "webyast-network.js",
        "jquery.event.drag-2.0.min.js", "jquery.event.drop-2.0.min.js", "jquery.qsearch.js", "webyast-roles.js", "slidernav.js", 
        "jquery.easing.1.3.js", "jquery.quicksand.js",
        "webyast-modal-dialog.js", "webyast-online-help.js", "webyast-controlpanel.js", "webyast-localstorage.js", "passwordStrengthMeter.js"]

  Dir.chdir(JAVASCRIPTS_PATH) do
    javascripts.map! {|f| File.join(Dir.pwd, f)}

    file 'base-min.js' => javascripts do | f |
      output_file = File.join(MIN) + '/' + f.name
      minify(f.prerequisites, output_file)
    end
  end

  desc 'Minimize Javascripts'
  task :"base" => [MIN, 'base-min.js']  do
    puts "\nDone"
  end
end

