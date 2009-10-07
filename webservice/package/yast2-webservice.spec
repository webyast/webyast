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

%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer
Requires:       yast2-core >= 2.18.10
%else
# 11.1 or SLES11
Requires:       yast2-core >= 2.17.31
%endif

Requires:	lighttpd-mod_magnet, ruby-fcgi, ruby-dbus, sqlite
Requires:       rubygem-yast2-webservice-tasks
Recommends:     avahi-utils
Requires:	yast2-dbus-server
# gamin gives problems with lighttpd, so better conflict with it for now
Conflicts:      gamin
PreReq:         lighttpd, PolicyKit, PackageKit, rubygem-rake, rubygem-sqlite3, rubygem-rails-2_3, ruby-rpam, ruby-polkit, rubygem-test-unit
License:        MIT
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.4
Release:        0
Summary:        YaST2 - Webservice 
Source:         www.tar.bz2
Source1:        yast.conf
Source2:        rails.include
Source3:        cleanurl-v5.lua
Source4:        org.opensuse.yast.permissions.policy
Source5:        policyKit-rights.rb  
Source6:        yast_user_roles
Source7:        lighttpd.conf
Source8:        modules.conf
Source9:        yastws
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  ruby, pkg-config, rubygem-mocha
# if we run the tests during build, we need most of Requires here too,
# except for deployment specific stuff
BuildRequires:  rubygem-yast2-webservice-tasks, rubygem-restility
BuildRequires:  yast2-core, yast2-dbus-server, ruby-dbus, sqlite, avahi-utils dbus-1
BuildRequires:  PolicyKit, PackageKit, rubygem-sqlite3, rubygem-rails-2_3, ruby-rpam, ruby-polkit

# This is for Hudson (build service) to setup the build env correctly
%if 0
BuildRequires:  rubygem-test-unit
BuildRequires:  rubygem-rcov >= 0.9.3.2
%endif

# rpmlint warns about file duplicates, this should take care but
# doesn't build (?!)
#%if 0%{?suse_version} > 1020
#BuildRequires:  fdupes
#%endif

BuildArch:      noarch

#
%define pkg_user yastws
%define pkg_home /var/lib/%{pkg_user}
#


%description
YaST2 - Webservice - REST based interface of YaST.
Authors:
--------
    Duncan Mac-Vicar Prett <dmacvicar@suse.de>
    Klaus Kaempf <kkaempf@suse.de>
    Bjoern Geuken <bgeuken@suse.de>
    Stefan Schubert <schubi@suse.de>

%prep
%setup -q -n www

%build

#---------------------------------------------------------------
%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/log/*
touch $RPM_BUILD_ROOT/srv/www/%{pkg_user}/db/schema.rb

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

#  create empty tmp directory
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/cache
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/pids
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/sessions
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/sockets


#---------------------------------------------------------------
%clean
rm -rf $RPM_BUILD_ROOT

#---------------------------------------------------------------
%pre
#
# e.g. adding user
#
/usr/sbin/groupadd -r %{pkg_user} &>/dev/null ||:
/usr/sbin/useradd  -g %{pkg_user} -s /bin/false -r -c "User for YaST-Webservice" -d %{pkg_home} %{pkg_user} &>/dev/null ||:

#---------------------------------------------------------------
%post

#installing lighttpd server
test -r /usr/sbin/yastws || { echo "Creating link /usr/sbin/yastws";
        ln -s /usr/sbin/lighttpd /usr/sbin/yastws; }
%fillup_and_insserv %{pkg_user}
#
#granting permissions for yastws
#
/usr/bin/polkit-auth --user yastws --grant org.freedesktop.packagekit.system-update >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.freedesktop.policykit.read >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.read >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.write >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.execute >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.dir >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.registeragent >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.unregisteragent >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.unmountagent >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.error >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.unregisterallagents >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.scr.registernewagents >& /dev/null || :
/usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.module-manager.import >& /dev/null || :
#
# granting all permissions for root 
#
/etc/yastws/tools/policyKit-rights.rb --user root --action grant >& /dev/null || :
#
# create database 
#
cd srv/www/%{pkg_user}
RAILS_ENV=production rake db:migrate
chown -R yastws: db
chown -R yastws: log
echo "Database is ready"

#---------------------------------------------------------------
%preun
%stop_on_removal %{pkg_user}

#---------------------------------------------------------------
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

#---------------------------------------------------------------
%files 
%defattr(-,root,root)
%dir /etc/yastws
%dir /srv/www/yastws
%dir /etc/yastws/tools
%dir /etc/yastws/vhosts.d
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}/sockets
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}/cache
%attr(-,%{pkg_user},%{pkg_user}) %dir %{_var}/log/%{pkg_user}

/srv/www/yastws/app
%dir /srv/www/yastws/db
/srv/www/yastws/db/migrate
%ghost /srv/www/yastws/db/schema.rb
/srv/www/yastws/doc
/srv/www/yastws/lib
/srv/www/yastws/public
/srv/www/yastws/Rakefile
/srv/www/yastws/script
#/srv/www/yastws/test
/srv/www/yastws/config
/srv/www/yastws/vendor
%attr(755,root,root) %config /etc/yastws/tools/policyKit-rights.rb
%attr(755,root,root) /srv/www/yastws/start.sh
%doc /srv/www/yastws/README
%attr(-,%{pkg_user},%{pkg_user}) /srv/www/yastws/log
%attr(-,%{pkg_user},%{pkg_user}) /srv/www/yastws/tmp
%config(noreplace) /etc/yastws/vhosts.d/yast.conf
%config(noreplace) /etc/yastws/lighttpd.conf
%config /etc/yastws/vhosts.d/rails.inc
%config /etc/yastws/cleanurl-v5.lua
%config /etc/yastws/modules.conf
%config /usr/share/PolicyKit/policy/org.opensuse.yast.permissions.policy
%config(noreplace) /etc/yast_user_roles
%config(noreplace)  %{_sysconfdir}/init.d/%{pkg_user}
%{_sbindir}/rc%{pkg_user}

#---------------------------------------------------------------
%changelog
