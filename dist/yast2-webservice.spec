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
Requires:       yast2-core, lighttpd-mod_magnet, ruby-fcgi, ruby-dbus, sqlite, avahi-utils
PreReq:         lighttpd, PolicyKit, PackageKit, rubygem-rake, rubygem-sqlite3, rubygem-rails
License:        GPL
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        1.0.0
Release:        1
Summary:        YaST2 - Webservice 
Source:         www.tar.bz2
Source1:        yast.conf
Source2:        rails.include
Source3:        cleanurl-v5.lua
Source4:        org.opensuse.yast.webservice.policy
Source5:        policyKit-rights.rb  
Source6:        yast_user_roles
Source7:        lighttpd.conf
Source8:        modules.conf
Source9:        yastws
Source10:       rpam
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  ruby-devel

#
%define pkg_user yastws
%define pkg_home /var/lib/%{pkg_user}
#


%description
YaST2 - Webservice - REST based interface of YaST.
Authors:
--------
    Stefan Schubert <schubi@opensuse.org>

%prep
%setup -q -n www

%build

#
# Building PolicyKit and PAM bindings
#
cd ruby-polkit
ruby extconf.rb
make
cd ..
cd rpam/ext/Rpam
ruby extconf.rb
make
cd ../../..

%install

#
# Install PolicyKit and PAM bindings
#
cd ruby-polkit
make install DESTDIR=%{buildroot}
cd ..
cd rpam/ext/Rpam
make install DESTDIR=%{buildroot}
cd ../../..
rm -rf rpam ruby-polkit

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/etc/%{pkg_user}/www/
cp -a * $RPM_BUILD_ROOT/etc/%{pkg_user}/www/
rm $RPM_BUILD_ROOT/etc/%{pkg_user}/www/log/*

%{__install} -d -m 0755                            \
    %{buildroot}%{pkg_home}/sockets/               \
    %{buildroot}%{pkg_home}/cache/                 \
    %{buildroot}%{_sbindir}                        \
    %{buildroot}%{_var}/log/%{pkg_user}
#
# init script
#
%{__install} -D -m 0755 %SOURCE9 \
    %{buildroot}%{_sysconfdir}/init.d/%{pkg_user}
%{__ln_s} -f %{_sysconfdir}/init.d/%{pkg_user} %{buildroot}%{_sbindir}/rc%{pkg_user}
#

# configure lighttpd web service
mkdir -p $RPM_BUILD_ROOT/etc/yastws/vhosts.d/
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/etc/yastws/vhosts.d/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/etc/yastws/vhosts.d/rails.inc
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/etc/yastws/
install -m 0644 %SOURCE7 $RPM_BUILD_ROOT/etc/yastws/
install -m 0644 %SOURCE8 $RPM_BUILD_ROOT/etc/yastws/

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE4 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
mkdir -p $RPM_BUILD_ROOT/etc/yastws/tools
install -m 0644 %SOURCE5 $RPM_BUILD_ROOT/etc/yastws/tools
install -m 0644 %SOURCE6 $RPM_BUILD_ROOT/etc/

#PAM configuration
mkdir -p $RPM_BUILD_ROOT/etc/pam.d
install -m 0644 %SOURCE10 $RPM_BUILD_ROOT/etc/pam.d/

#  create empty tmp directory
mkdir -p $RPM_BUILD_ROOT/etc/yastws/www/tmp


%clean
rm -rf $RPM_BUILD_ROOT

%pre
#
# e.g. adding user
#
/usr/sbin/groupadd -r %{pkg_user} &>/dev/null ||:
/usr/sbin/useradd  -g %{pkg_user} -s /bin/false -r -c "User for YaST-Webservice" -d %{pkg_home} %{pkg_user} &>/dev/null ||:

%post
#installing lighttpd server
test -r /usr/sbin/yastws || { echo "Creating link /usr/sbin/yastws";
        ln -s /usr/sbin/lighttpd /usr/sbin/yastws; }
%fillup_and_insserv %{pkg_user}
#
#granting permissions for yastws
#
if grep yastws /etc/PolicyKit/PolicyKit.conf > /dev/null; then
   echo "Permission for yastws already granted in PolicyKit.conf"
else
   echo "Permission for yastws in PolicyKit.conf granted"
   perl -p -i.orig -e 's|</config>|<match user="yastws">\n  <match action="org.opensuse.yast.scr.*">\n   <return result="yes"/>\n  </match>\n</match>\n</config>|' /etc/PolicyKit/PolicyKit.conf
fi
/usr/bin/polkit-auth --user yastws --grant org.freedesktop.packagekit.system-update >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.freedesktop.policykit.read >& /dev/null || :
#
# granting all permissions for root 
#
/etc/yastws/tools/policyKit-rights.rb --user root --action grant >& /dev/null || :
#
# create database 
#
cd etc/yastws/www
rake db:migrate
chgrp yastws db db/*.sqlite*
chown yastws db db/*.sqlite*

%preun
%stop_on_removal %{pkg_user}

%postun
%restart_on_update %{pkg_user}
%{insserv_cleanup}
#remove link
if test -r /usr/sbin/yastws ; then
  echo "/usr/sbin/yastws already removed"
else
  echo "Removing link /usr/sbin/yastws";
  rm /usr/sbin/yastws
fi

%files 
%defattr(-,root,root)
%dir /etc/yastws
%dir /etc/yastws/www
%dir /etc/yastws/tools
%dir /etc/yastws/vhosts.d
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%dir /etc/pam.d
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}/sockets
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}/cache
%attr(-,%{pkg_user},%{pkg_user}) %dir %{_var}/log/%{pkg_user}

%config /etc/pam.d/rpam
%config /etc/yastws/www/app
%config /etc/yastws/www/db
%config /etc/yastws/www/doc
%config /etc/yastws/www/lib
%config /etc/yastws/www/public
%config /etc/yastws/www/Rakefile
%config /etc/yastws/www/COPYING
%config /etc/yastws/www/script
%config /etc/yastws/www/test
%config /etc/yastws/www/config
%config /etc/yastws/www/tmp
%attr(755,root,root) %config /etc/yastws/tools/policyKit-rights.rb
%doc /etc/yastws/www/public/doc_config.html 
%doc /etc/yastws/www/public/doc_interface.html
%doc COPYING
%attr(-,%{pkg_user},%{pkg_user}) /etc/yastws/www/log
%attr(-,%{pkg_user},%{pkg_user}) /etc/yastws/www/tmp
%config(noreplace) /etc/yastws/vhosts.d/yast.conf
%config(noreplace) /etc/yastws/lighttpd.conf
%config /etc/yastws/vhosts.d/rails.inc
%config /etc/yastws/cleanurl-v5.lua
%config /etc/yastws/modules.conf
%config /usr/share/PolicyKit/policy/org.opensuse.yast.webservice.policy
%config(noreplace) /etc/yast_user_roles
%config(noreplace)  %{_sysconfdir}/init.d/%{pkg_user}
%{_sbindir}/rc%{pkg_user}
%{_libdir}/ruby/site_ruby/%{rb_ver}/%{rb_arch}/polkit.so
%{_libdir}/ruby/site_ruby/%{rb_ver}/%{rb_arch}/rpam.so
