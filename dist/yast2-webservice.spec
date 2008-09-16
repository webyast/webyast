#
# spec file for package yast2-webservice (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice
Requires:       PackageKit, yast2-core, lighttpd-mod_magnet, ruby-fcgi, rubygem-rake, ruby-dbus, sqlite, rubygem-sqlite3
PreReq:         lighttpd
License:        GPL
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        1.0.0
Release:        0
Summary:        YaST2 - Webservice 
Source:         webservice.tar.bz2
Source1:        yast.conf
Source2:        rails.include
Source3:        cleanurl-v5.lua
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArchitectures: noarch

%description
YaST2 - Webservice - REST based interface of YaST.
Authors:
--------
    Stefan Schubert <schubi@opensuse.org>

%prep
%setup -q -n webservice

%build

%install
#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/yast/
cp -a * $RPM_BUILD_ROOT/srv/www/yast/

# configure lighttpd web service
mkdir -p $RPM_BUILD_ROOT/etc/lighttpd/vhosts.d/
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/etc/lighttpd/vhosts.d/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/etc/lighttpd/vhosts.d/rails.inc
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/etc/lighttpd/
#
#set default api on localhost for the webclient
# 
sed 's,FRONTEND_HOST.*,FRONTEND_HOST = "127.0.42.2",' \
  $RPM_BUILD_ROOT/srv/www/yast/config/environments/development.rb > tmp-file \
  && mv tmp-file "$RPM_BUILD_ROOT/srv/www/yast/config/environments/development.rb"
sed 's,FRONTEND_PORT.*,FRONTEND_PORT = 80,' \
  $RPM_BUILD_ROOT/srv/www/yast/config/environments/development.rb > tmp-file \
  && mv tmp-file "$RPM_BUILD_ROOT/srv/www/yast/config/environments/development.rb"
sed 's,api.opensuse.org,127.0.42.2,' \
  $RPM_BUILD_ROOT/srv/www/yast/app/helpers/package_helper.rb > tmp-file \
  && mv tmp-file "$RPM_BUILD_ROOT/srv/www/yast/app/helpers/package_helper.rb"


%clean
rm -rf $RPM_BUILD_ROOT

%files 
%defattr(-,root,root)
%dir /srv/www/yast
/srv/www/yast/app
/srv/www/yast/db
/srv/www/yast/doc
/srv/www/yast/lib
/srv/www/yast/public
/srv/www/yast/Rakefile
/srv/www/yast/README*
/srv/www/yast/COPYING
/srv/www/yast/script
/srv/www/yast/test
/srv/www/yast/config
%doc README* COPYING
%attr(-,lighttpd,lighttpd) /srv/www/yast/log
%attr(-,lighttpd,lighttpd) /srv/www/yast/tmp
%config(noreplace) /etc/lighttpd/vhosts.d/yast.conf
%config /etc/lighttpd/vhosts.d/rails.inc
%config /etc/lighttpd/cleanurl-v5.lua
