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
Source9:        yastwebd
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArchitectures: noarch

#
%define pkg_user yastwebd
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

%install
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
mkdir -p $RPM_BUILD_ROOT/etc/yastwebd/vhosts.d/
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/etc/yastwebd/vhosts.d/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/etc/yastwebd/vhosts.d/rails.inc
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/etc/yastwebd/
install -m 0644 %SOURCE7 $RPM_BUILD_ROOT/etc/yastwebd/
install -m 0644 %SOURCE8 $RPM_BUILD_ROOT/etc/yastwebd/

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE4 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
mkdir -p $RPM_BUILD_ROOT/etc/yastwebd/tools
install -m 0644 %SOURCE5 $RPM_BUILD_ROOT/etc/yastwebd/tools
install -m 0644 %SOURCE6 $RPM_BUILD_ROOT/etc/


%clean
#rm -rf $RPM_BUILD_ROOT

%pre
#
# e.g. adding user
#
/usr/sbin/groupadd -r %{pkg_user} &>/dev/null ||:
/usr/sbin/useradd  -g %{pkg_user} -s /bin/false -r -c "User for YaST-Webservice" -d %{pkg_home} %{pkg_user} &>/dev/null ||:

%post
%fillup_and_insserv %{pkg_user}

%preun
%stop_on_removal %{pkg_user}

%postun
%restart_on_update %{pkg_user}
%{insserv_cleanup}


%files 
%defattr(-,root,root)
%dir /etc/yastwebd
%dir /etc/yastwebd/www
%dir /etc/yastwebd/tools
%dir /etc/yastwebd/vhosts.d
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%config /etc/yastwebd/www/app
%config /etc/yastwebd/www/db
%config /etc/yastwebd/www/doc
%config /etc/yastwebd/www/lib
%config /etc/yastwebd/www/public
%config /etc/yastwebd/www/Rakefile
%config /etc/yastwebd/www/README*
%config /etc/yastwebd/www/COPYING
%config /etc/yastwebd/www/script
%config /etc/yastwebd/www/test
%config /etc/yastwebd/www/config
%config /etc/yastwebd/tools/policyKit-rights.rb
%doc README* COPYING
%attr(-,lighttpd,lighttpd) /etc/yastwebd/www/log
%attr(-,lighttpd,lighttpd) /etc/yastwebd/www/tmp
%config(noreplace) /etc/yastwebd/vhosts.d/yast.conf
%config(noreplace) /etc/yastwebd/lighttpd.conf
%config /etc/yastwebd/vhosts.d/rails.inc
%config /etc/yastwebd/cleanurl-v5.lua
%config /etc/yastwebd/modules.conf
%config /usr/share/PolicyKit/policy/org.opensuse.yast.webservice.policy
%config(noreplace) /etc/yast_user_roles
%config(noreplace)  %{_sysconfdir}/init.d/%{pkg_user}
%{_sbindir}/rc%{pkg_user}

