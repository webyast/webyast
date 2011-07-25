#!/bin/sh

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

rm -f log/development.log
rake db:migrate
rake sass:update
if [ -f public/javascripts/min/base-min.js ] ; then
  echo "base-min.js already available"
else
  rake js:base
fi

if [ -f ../plugins/users/public/javascripts/min/users-min.js ] ; then
  echo "users-min.js already available"
else
  if [ -f ../plugins/users/lib/tasks/jsmin.rake ] ; then
    cd ../plugins/users/
    rake js:users
    cd -
  else
    echo "users-min.js not needed"
  fi
fi

if [ -f ../plugins/status/public/javascripts/min/status-min.js ] ; then
  echo "status-min.js already available"
else
  if [ -f ../plugins/status/lib/tasks/jsmin_status.rake ] ; then
    cd ../plugins/status/
    rake js:status
    cd -
  else
    echo "status-min.js not needed"
  fi
fi
ruby script/server -p 54984
